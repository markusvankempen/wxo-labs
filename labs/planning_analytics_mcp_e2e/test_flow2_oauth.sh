#!/bin/bash
set -e

# ==============================================================================
# Flow 2: IBM Planning Analytics MCP Integration via OAuth 2.0 Auth Code
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
AUTH_URL="https://${PA_HOST}/oauth2/authorize"
TOKEN_URL="https://${PA_HOST}/oauth2/token"
PA_OAUTH_SCOPE="v0userContext"

echo "=================================================================="
echo "🚀 Testing Flow 2: Planning Analytics MCP via OAuth 2.0 Auth Code"
echo "Target Endpoint: ${MCP_URL}"
echo "Auth URL:        ${AUTH_URL}"
echo "Token URL:       ${TOKEN_URL}"
echo "Required Scope:  ${PA_OAUTH_SCOPE}"
echo "=================================================================="

# Check for Client ID & Secret
if [ -z "$PA_OAUTH_CLIENT_ID" ]; then
  echo "⚠️ PA_OAUTH_CLIENT_ID is not set in environment or .env."
  read -p "Enter PA OAuth Client ID: " PA_OAUTH_CLIENT_ID
fi

if [ -z "$PA_OAUTH_CLIENT_SECRET" ]; then
  echo "⚠️ PA_OAUTH_CLIENT_SECRET is not set in environment or .env."
  read -sp "Enter PA OAuth Client Secret: " PA_OAUTH_CLIENT_SECRET
  echo ""
fi

if [ -z "$PA_OAUTH_CLIENT_ID" ] || [ -z "$PA_OAUTH_CLIENT_SECRET" ]; then
  echo "❌ Error: Both Client ID and Client Secret are required."
  echo "Configure them in PAW Admin: https://${PA_HOST}/?accountId=${ACCOUNT_ID}&tenantId=${TENANT_ID}&perspective=pa-administration"
  exit 1
fi

echo ""
echo "▶ 1. Creating WxO Connection: pa_oauth_conn..."
orchestrate connections add -a pa_oauth_conn || true

echo "▶ 2. Configuring WxO Connection as oauth_auth_code_flow on DRAFT environment..."
orchestrate connections configure \
  -a pa_oauth_conn \
  --env draft \
  --kind oauth_auth_code_flow \
  --type team

echo "▶ 3. Setting OAuth credentials (with scope: v0userContext)..."
orchestrate connections set-credentials \
  -a pa_oauth_conn \
  --env draft \
  --client-id "$PA_OAUTH_CLIENT_ID" \
  --client-secret "$PA_OAUTH_CLIENT_SECRET" \
  --auth-url "$AUTH_URL" \
  --token-url "$TOKEN_URL" \
  --scopes "$PA_OAUTH_SCOPE" \
  --grant-type "authorization_code"

echo ""
echo "▶ 4. Importing Remote MCP Toolkit: planning_analytics_oauth..."
orchestrate toolkits import -f toolkit_pa_oauth.yaml -a pa_oauth_conn

echo ""
echo "▶ 5. Verifying Discovered Tools in WxO Catalog..."
COLUMNS=250 orchestrate tools list | grep -i "pa_oauth_conn" || true

echo ""
echo "▶ 6. Importing & Deploying Agent: planning_analytics_oauth_agent..."
orchestrate agents import -f agent_oauth.yaml || true
orchestrate agents deploy -n planning_analytics_oauth_agent || true

echo ""
echo "=================================================================="
echo "⚠️ First-Time Authorization Reminder:"
echo "For OAuth Authorization Code flow, complete the one-time user authorization:"
echo "Visit the WxO Web UI (Manage > Connections > pa_oauth_conn) and click 'Authorize',"
echo "or run: orchestrate chat ask -n planning_analytics_oauth_agent \"What are the available TM1 servers?\""
echo "to receive the browser login authorization link."
echo "=================================================================="
