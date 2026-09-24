#!/usr/bin/env bash
# ---
# Author: Markus van Kempen | mvk@ca.ibm.com
# Diagnostic Scenarios Runner for Remote MCP
# Directly reproduces and diagnoses "Gateway creation failed: 422"
# ---
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
  cat <<EOF
Usage: ./test_debug_scenarios.sh [scenario_number]

Scenarios:
  1  Baseline Streamable HTTP (AUTH_MODE=off, /mcp)
     -> Proves WxO can create gateway and discover tools over Streamable HTTP without auth.

  2  Baseline SSE (AUTH_MODE=off, /sse)
     -> Proves WxO can create gateway and discover tools over Server-Sent Events.

  3  Remote MCP with custom header using 'kind: api_key' (AUTH_MODE=all, header: x-api-key)
     -> Recommended pattern for servers requiring a custom header API key.

  4  Remote MCP with custom header using 'kind: key_value' (AUTH_MODE=all, header: x-api-key)
     -> Validates Caleb's key-value pair connection configuration.

  5  [REPRODUCTION] Missing draft credentials simulation
     -> Recreates the exact "Gateway creation failed: 422" when credentials aren't set in draft.

  6  [REPRODUCTION] Unreachable / internal network URL simulation
     -> Recreates "Gateway creation failed: 422" when URL is not reachable from WxO cloud pods.

  all Run all scenarios in sequence.
EOF
}

SCENARIO="${1:-}"

if [[ -z "$SCENARIO" || "$SCENARIO" == "-h" || "$SCENARIO" == "--help" ]]; then
  show_help
  exit 0
fi

run_scenario_1() {
  echo ""
  echo "======================================================================"
  echo " [Scenario 1] Baseline Streamable HTTP without Auth"
  echo "======================================================================"
  AUTH_MODE=off MCP_TRANSPORT=streamable_http TOOLKIT_NAME="mcp_ticket_s1" ./deploy_remote_e2e.sh
}

run_scenario_2() {
  echo ""
  echo "======================================================================"
  echo " [Scenario 2] Baseline SSE without Auth"
  echo "======================================================================"
  AUTH_MODE=off MCP_TRANSPORT=sse TOOLKIT_NAME="mcp_ticket_s2" ./deploy_remote_e2e.sh
}

run_scenario_3() {
  echo ""
  echo "======================================================================"
  echo " [Scenario 3] Custom Header with 'kind: api_key'"
  echo "======================================================================"
  AUTH_MODE=all CONN_TYPE=api_key MCP_TRANSPORT=streamable_http TOOLKIT_NAME="mcp_ticket_s3" ./deploy_remote_e2e.sh
}

run_scenario_4() {
  echo ""
  echo "======================================================================"
  echo " [Scenario 4] Custom Header with 'kind: key_value'"
  echo "======================================================================"
  AUTH_MODE=all CONN_TYPE=key_value MCP_TRANSPORT=streamable_http TOOLKIT_NAME="mcp_ticket_s4" ./deploy_remote_e2e.sh
}

run_scenario_5() {
  echo ""
  echo "======================================================================"
  echo " [Scenario 5 REPRODUCTION] Missing Draft Credentials"
  echo " Expecting: Gateway creation failed: 422"
  echo "======================================================================"
  
  # Start server requiring auth
  ./stop.sh >/dev/null 2>&1 || true
  env MCP_MODE=http PORT=8080 HOST=0.0.0.0 AUTH_MODE=all MCP_API_KEY="secret-123" \
    npx -y mcp-ticket-demo >.run/mcp_s5.log 2>&1 &
  echo $! >.run/mcp.pid
  sleep 3

  # Start ngrok
  ngrok http 8080 --log=stdout >.run/ngrok.log 2>&1 &
  echo $! >.run/ngrok.pid
  sleep 4

  PUB_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    t = [x["public_url"] for x in d.get("tunnels", []) if x.get("public_url", "").startswith("https://")]
    print(t[0] if t else "")
except Exception:
    print("")
')

  echo "    Public URL: ${PUB_URL}"
  echo "    Creating connection WITHOUT setting draft credentials..."
  orchestrate connections remove -a broken_draft_conn 2>/dev/null || true
  orchestrate connections add -a broken_draft_conn
  orchestrate connections configure -a broken_draft_conn --env draft --type team --kind key_value
  # Notice: we DO NOT set credentials for draft!

  cat >.run/broken_toolkit.yaml <<EOF
spec_version: v1
kind: mcp
name: repro_422_toolkit
description: "Reproduction toolkit"
transport: streamable_http
url: "${PUB_URL}/mcp"
tools:
  - "*"
connections:
  - broken_draft_conn
EOF

  echo "    Attempting toolkit import (should trigger 422 or 401 error)..."
  set +e
  orchestrate toolkits import -f .run/broken_toolkit.yaml -a broken_draft_conn
  STATUS=$?
  set -e
  echo "    Result exit code: $STATUS"
  ./stop.sh >/dev/null 2>&1 || true
}

run_scenario_6() {
  echo ""
  echo "======================================================================"
  echo " [Scenario 6 REPRODUCTION] Unreachable / Internal Route"
  echo " Expecting: Gateway creation failed: 422 or network error"
  echo "======================================================================"
  cat >.run/unreachable_toolkit.yaml <<EOF
spec_version: v1
kind: mcp
name: repro_unreachable_toolkit
description: "Unreachable route test"
transport: streamable_http
url: "https://internal-cluster-route.local.lan/mcp"
tools:
  - "*"
EOF

  echo "    Attempting to import toolkit with unreachable host..."
  set +e
  orchestrate toolkits import -f .run/unreachable_toolkit.yaml
  STATUS=$?
  set -e
  echo "    Result exit code: $STATUS"
}

case "$SCENARIO" in
  1) run_scenario_1 ;;
  2) run_scenario_2 ;;
  3) run_scenario_3 ;;
  4) run_scenario_4 ;;
  5) run_scenario_5 ;;
  6) run_scenario_6 ;;
  all)
    run_scenario_1
    run_scenario_2
    run_scenario_3
    run_scenario_4
    ;;
  *)
    echo "Unknown scenario: $SCENARIO"
    show_help
    exit 1
    ;;
esac
