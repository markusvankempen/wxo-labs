#!/usr/bin/env bash
# ---
# Author: Markus van Kempen | mvk@ca.ibm.com
# End-to-End Remote MCP Test Suite using mcp-ticket-demo
# Validates WxO Remote MCP Gateway creation, reachability, headers, and tool execution.
# ---
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${SCRIPT_DIR}/.run"
mkdir -p "$RUN_DIR"

# ---------------------------------------------------------------------------
# Load configuration
# ---------------------------------------------------------------------------
load_env_file() {
  local f="$1" line key val
  [[ -f "$f" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" == *"="* ]] || continue
    key="${line%%=*}"
    val="${line#*=}"
    key="${key%"${key##*[![:space:]]}"}"
    key="${key#"${key%%[![:space:]]*}"}"
    [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    if [[ "$val" =~ ^\"(.*)\"$ ]]; then val="${BASH_REMATCH[1]}"
    elif [[ "$val" =~ ^\'(.*)\'$ ]]; then val="${BASH_REMATCH[1]}"
    fi
    export "${key}=${val}"
  done <"$f"
}

load_env_file "${SCRIPT_DIR}/../.env"
load_env_file "${SCRIPT_DIR}/.env"

MCP_MODE="http"
PORT="${PORT:-8080}"
HOST="${HOST:-0.0.0.0}"
AUTH_MODE="${AUTH_MODE:-off}"
MCP_API_KEY="${MCP_API_KEY:-demo-mcp-secret-key-12345}"
MCP_TRANSPORT="${MCP_TRANSPORT:-streamable_http}"
TOOLKIT_NAME="${TOOLKIT_NAME:-mcp_ticket_demo}"
AGENT_NAME="${AGENT_NAME:-mcp_ticket_agent}"
CONNECTION_APP_ID="${CONNECTION_APP_ID:-mcp_ticket_conn}"
CONN_TYPE="${CONN_TYPE:-api_key}" # api_key or key_value
PUBLIC_URL="${PUBLIC_URL:-}"
SKIP_CHAT_TEST="${SKIP_CHAT_TEST:-0}"
CHAT_PROMPT="${CHAT_PROMPT:-Please describe the server and then search for open tickets.}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing dependency: $1" >&2; exit 1; }; }
need npx
need curl
need python3
need orchestrate

echo "======================================================================"
echo " Starting Remote MCP E2E Test with mcp-ticket-demo"
echo " Transport: ${MCP_TRANSPORT} | Auth: ${AUTH_MODE} | Port: ${PORT}"
echo "======================================================================"

# ---------------------------------------------------------------------------
# [1] Start local mcp-ticket-demo server
# ---------------------------------------------------------------------------
echo "==> [1/6] Launching mcp-ticket-demo in HTTP mode..."
# Stop previous instances if running
"${SCRIPT_DIR}/stop.sh" >/dev/null 2>&1 || true

MCP_ENV="MCP_MODE=http PORT=${PORT} HOST=${HOST} AUTH_MODE=${AUTH_MODE}"
if [[ "$AUTH_MODE" != "off" ]]; then
  MCP_ENV="${MCP_ENV} MCP_API_KEY=${MCP_API_KEY}"
fi

env MCP_MODE=http PORT="${PORT}" HOST="${HOST}" AUTH_MODE="${AUTH_MODE}" MCP_API_KEY="${MCP_API_KEY}" \
  npx -y mcp-ticket-demo >"${RUN_DIR}/mcp.log" 2>&1 &
MCP_PID=$!
echo "$MCP_PID" >"${RUN_DIR}/mcp.pid"
echo "    mcp-ticket-demo started (PID: ${MCP_PID})"

# Wait for local health check
echo "    Waiting for /health on http://localhost:${PORT}/health..."
HEALTHY=0
for i in {1..30}; do
  if curl -fs "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
    HEALTHY=1
    break
  fi
  sleep 1
done

if [[ "$HEALTHY" -ne 1 ]]; then
  echo "ERROR: mcp-ticket-demo failed to become healthy on port ${PORT}" >&2
  tail -n 25 "${RUN_DIR}/mcp.log" >&2 || true
  exit 1
fi
echo "    Local server healthy!"

# ---------------------------------------------------------------------------
# [2] Ensure public reachability (ngrok or existing PUBLIC_URL)
# ---------------------------------------------------------------------------
echo "==> [2/6] Verifying public reachability..."
if [[ -z "$PUBLIC_URL" ]]; then
  need ngrok
  echo "    Starting ngrok tunnel for port ${PORT}..."
  ngrok http "${PORT}" --log=stdout >"${RUN_DIR}/ngrok.log" 2>&1 &
  NGROK_PID=$!
  echo "$NGROK_PID" >"${RUN_DIR}/ngrok.pid"

  for i in {1..20}; do
    PUBLIC_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    t = [x["public_url"] for x in d.get("tunnels", []) if x.get("public_url", "").startswith("https://")]
    print(t[0] if t else "")
except Exception:
    print("")
')
    [[ -n "$PUBLIC_URL" ]] && break
    sleep 1
  done
fi

if [[ -z "$PUBLIC_URL" ]]; then
  echo "ERROR: Unable to get public HTTPS tunnel URL." >&2
  tail -n 20 "${RUN_DIR}/ngrok.log" >&2 || true
  exit 1
fi

echo "    Public URL : ${PUBLIC_URL}"
echo "    Live Dashboard : ${PUBLIC_URL}/log"
echo "    Admin Console  : ${PUBLIC_URL}/admin"
echo "$PUBLIC_URL" >"${RUN_DIR}/public_url.txt"

# Verify public health check
echo "    Checking public /health endpoint..."
curl -fs "${PUBLIC_URL}/health" >"${RUN_DIR}/public_health.json"
echo "    Public /health OK: $(python3 -c 'import json; print(json.load(open("'${RUN_DIR}'/public_health.json")).get("service"))')"

# Determine endpoint path based on transport
if [[ "$MCP_TRANSPORT" == "streamable_http" ]]; then
  MCP_ENDPOINT="${PUBLIC_URL}/mcp"
elif [[ "$MCP_TRANSPORT" == "sse" ]]; then
  MCP_ENDPOINT="${PUBLIC_URL}/sse"
else
  echo "ERROR: Unsupported transport: $MCP_TRANSPORT" >&2
  exit 1
fi
echo "    MCP Endpoint : ${MCP_ENDPOINT}"

# ---------------------------------------------------------------------------
# [3] Configure WxO connection (if AUTH_MODE != off)
# ---------------------------------------------------------------------------
CONNECTION_FLAGS=""
if [[ "$AUTH_MODE" != "off" ]]; then
  echo "==> [3/6] Configuring WxO authentication connection '${CONNECTION_APP_ID}'..."
  orchestrate connections remove -a "${CONNECTION_APP_ID}" 2>/dev/null || true
  orchestrate connections add -a "${CONNECTION_APP_ID}"

  if [[ "$CONN_TYPE" == "api_key" ]]; then
    echo "    Configuring as kind: api_key with custom header 'x-api-key'..."
    orchestrate connections configure -a "${CONNECTION_APP_ID}" --env draft --type team --kind api_key --name "x-api-key"
    orchestrate connections set-credentials -a "${CONNECTION_APP_ID}" --env draft --api-key "${MCP_API_KEY}"
  elif [[ "$CONN_TYPE" == "key_value" ]]; then
    echo "    Configuring as kind: key_value with entry 'x-api-key=...'..."
    orchestrate connections configure -a "${CONNECTION_APP_ID}" --env draft --type team --kind key_value
    orchestrate connections set-credentials -a "${CONNECTION_APP_ID}" --env draft -e "x-api-key=${MCP_API_KEY}"
  fi
  CONNECTION_FLAGS="--app-id ${CONNECTION_APP_ID}"
else
  echo "==> [3/6] Auth mode is 'off' — no WxO connection required."
fi

# ---------------------------------------------------------------------------
# [4] Register remote MCP toolkit in WxO
# ---------------------------------------------------------------------------
echo "==> [4/6] Registering remote MCP toolkit '${TOOLKIT_NAME}' in WxO..."
orchestrate toolkits remove -n "${TOOLKIT_NAME}" 2>/dev/null || true

TOOLKIT_YAML="${RUN_DIR}/toolkit.generated.yaml"
cat >"${TOOLKIT_YAML}" <<EOF
spec_version: v1
kind: mcp
name: ${TOOLKIT_NAME}
description: "mcp-ticket-demo E2E reference (${MCP_TRANSPORT})"
transport: ${MCP_TRANSPORT}
url: "${MCP_ENDPOINT}"
tools:
  - "*"
EOF

if [[ -n "${CONNECTION_FLAGS}" ]]; then
  cat >>"${TOOLKIT_YAML}" <<EOF
connections:
  - ${CONNECTION_APP_ID}
EOF
fi

echo "    Importing toolkit manifest:"
cat "${TOOLKIT_YAML}"

orchestrate toolkits import -f "${TOOLKIT_YAML}" ${CONNECTION_FLAGS}

echo "    Toolkit imported successfully!"
echo "    Open ${PUBLIC_URL}/log to see the WxO handshake trace."

# ---------------------------------------------------------------------------
# [5] Inspect tools and build test agent
# ---------------------------------------------------------------------------
echo "==> [5/6] Inspecting tools and creating agent '${AGENT_NAME}'..."
orchestrate agents remove -n "${AGENT_NAME}" -k native 2>/dev/null || true

AGENT_YAML="${RUN_DIR}/agent.generated.yaml"
cat >"${AGENT_YAML}" <<EOF
spec_version: v1
kind: agent
name: ${AGENT_NAME}
display_name: "MCP Ticket Agent (${TOOLKIT_NAME})"
description: "Agent to test mcp-ticket-demo tools"
instructions: |
  You are an IT helpdesk support assistant.
  Use describe_server first if you need to know server capabilities.
  Use search_tickets to search for open tickets.
  Use get_ticket to retrieve ticket details.
tools:
  - "${TOOLKIT_NAME}:describe_server"
  - "${TOOLKIT_NAME}:search_tickets"
  - "${TOOLKIT_NAME}:get_ticket"
EOF

orchestrate agents import -f "${AGENT_YAML}"
echo "    Agent imported successfully!"

# ---------------------------------------------------------------------------
# [6] Test tool invocation via chat
# ---------------------------------------------------------------------------
if [[ "${SKIP_CHAT_TEST}" -eq 0 ]]; then
  echo "==> [6/6] Probing agent with prompt: '${CHAT_PROMPT}'..."
  orchestrate chat ask -n "${AGENT_NAME}" -l "${CHAT_PROMPT}" || true
else
  echo "==> [6/6] Chat probe skipped (SKIP_CHAT_TEST=1)."
fi

echo ""
echo "======================================================================"
echo " ✅ Test Completed Successfully!"
echo " Public MCP Endpoint : ${MCP_ENDPOINT}"
echo " Live Call Trace     : ${PUBLIC_URL}/log"
echo " Admin Dashboard     : ${PUBLIC_URL}/admin (login demo/demo)"
echo " Stop background processes anytime with: ${SCRIPT_DIR}/stop.sh"
echo "======================================================================"
