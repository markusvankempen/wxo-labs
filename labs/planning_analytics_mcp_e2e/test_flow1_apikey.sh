#!/bin/bash
set -e

# ==============================================================================
# Flow 1: IBM Planning Analytics MCP Integration via API Key (Basic Auth)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f .env ]; then
  source .env
fi

PA_HOST="${PA_HOST:-us-east-1.planninganalytics.saas.ibm.com}"
TENANT_ID="${TENANT_ID:-Z7LGTIG97RKC}"
ACCOUNT_ID="${ACCOUNT_ID:-35L2PSTGTSA4}"
MCP_URL="https://${PA_HOST}/api/${TENANT_ID}/v0/agentic-ai/ibm-pa-tools/mcp"

echo "=================================================================="
echo "🚀 Testing Flow 1: Planning Analytics MCP via API Key"
echo "Target Endpoint: ${MCP_URL}"
echo "Auth Realm: Basic realm=\"apikey\" (username: apikey, password: <API_KEY>)"
echo "=================================================================="

# Check for API Key
if [ -z "$PA_API_KEY" ]; then
  echo "⚠️ PA_API_KEY is not set in environment or .env."
  read -sp "Enter your Planning Analytics API Key: " PA_API_KEY
  echo ""
fi

if [ -z "$PA_API_KEY" ]; then
  echo "❌ Error: PA_API_KEY is required to test Flow 1."
  exit 1
fi

echo "▶ 1. Probing direct endpoint with API Key Basic Auth..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -u "apikey:${PA_API_KEY}" -X POST "${MCP_URL}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}')

echo "Direct probe returned HTTP Status: ${HTTP_STATUS}"
if [ "$HTTP_STATUS" = "200" ]; then
  echo "✅ Success: API Key authenticated successfully against PA MCP endpoint!"
elif [ "$HTTP_STATUS" = "401" ]; then
  echo "⚠️ HTTP 401: Unauthorized. Please verify the API key."
else
  echo "ℹ️ Server returned status: ${HTTP_STATUS}"
fi

echo ""
echo "▶ 2. Creating WxO Connection: pa_apikey_conn"
orchestrate connections add -a pa_apikey_conn || true

echo "▶ 3. Configuring WxO Connection with Basic Auth on DRAFT environment..."
orchestrate connections configure \
  -a pa_apikey_conn \
  --env draft \
  --type team \
  --kind basic

echo "▶ 4. Storing credentials (username: apikey, password: <PA_API_KEY>)..."
orchestrate connections set-credentials \
  -a pa_apikey_conn \
  --env draft \
  --username "apikey" \
  --password "$PA_API_KEY"

echo ""
echo "▶ 5. Importing Remote MCP Toolkit: planning_analytics_apikey..."
orchestrate toolkits import -f toolkit_pa_apikey.yaml -a pa_apikey_conn

echo ""
echo "▶ 6. Verifying Discovered Tools in WxO Catalog..."
COLUMNS=250 orchestrate tools list | grep -i "pa_apikey_conn" || true

echo ""
echo "▶ 7. Importing & Deploying Agent: planning_analytics_agent..."
orchestrate agents import -f agent.yaml || true
orchestrate agents deploy -n planning_analytics_agent || true

echo ""
echo "=================================================================="
echo "🎉 Flow 1 Setup & Verification Complete!"
echo "You can now chat with your agent via:"
echo "  orchestrate chat ask -n planning_analytics_agent \"What are the available TM1 servers?\""
echo "=================================================================="
