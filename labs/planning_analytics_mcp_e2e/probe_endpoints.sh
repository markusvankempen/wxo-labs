#!/bin/bash
# ==============================================================================
# Planning Analytics MCP & OAuth Endpoint Probe
# ==============================================================================

PA_HOST="us-east-1.planninganalytics.saas.ibm.com"
ACCOUNT_ID="35L2PSTGTSA4"
TENANT_ID="Z7LGTIG97RKC"

MCP_URL="https://${PA_HOST}/api/${TENANT_ID}/v0/agentic-ai/ibm-pa-tools/mcp"
AUTH_URL="https://${PA_HOST}/oauth2/authorize"
TOKEN_URL="https://${PA_HOST}/oauth2/token"

echo "=================================================================="
echo "🔍 Probing IBM Planning Analytics as a Service Endpoints"
echo "Tenant ID: ${TENANT_ID}"
echo "Account ID: ${ACCOUNT_ID}"
echo "=================================================================="
echo ""

echo "▶ 1. Probing MCP Endpoint: ${MCP_URL}"
curl -s -i -X POST "${MCP_URL}" | head -n 20
echo ""
echo "------------------------------------------------------------------"

echo "▶ 2. Probing OAuth2 Authorize Endpoint: ${AUTH_URL}"
curl -s -i "${AUTH_URL}" | head -n 20
echo ""
echo "------------------------------------------------------------------"

echo "▶ 3. Probing OAuth2 Token Endpoint: ${TOKEN_URL}"
curl -s -i -X POST "${TOKEN_URL}" | head -n 20
echo ""
echo "=================================================================="
echo "✅ Probing Complete"
