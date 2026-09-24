#!/usr/bin/env bash
# ---
# Author: Markus van Kempen | mvk@ca.ibm.com
# End-to-End Local Stdio MCP Test Suite using mcp-ticket-demo
# Validates running mcp-ticket-demo locally inside WxO via stdio
# ---
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_NAME="${TOOLKIT_NAME:-mcp_ticket_local}"
AGENT_NAME="${AGENT_NAME:-mcp_ticket_local_agent}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: missing dependency: $1" >&2; exit 1; }; }
need orchestrate

echo "======================================================================"
echo " Testing Local Stdio MCP Toolkit via mcp-ticket-demo"
echo "======================================================================"

echo "==> [1/3] Adding local MCP toolkit '${TOOLKIT_NAME}'..."
orchestrate toolkits remove -n "${TOOLKIT_NAME}" 2>/dev/null || true

orchestrate toolkits add \
  --kind mcp \
  --name "${TOOLKIT_NAME}" \
  --description "MCP Ticket Demo - Local Stdio Reference" \
  --package "mcp-ticket-demo" \
  --language node \
  --tools "*"

echo "    Local toolkit added successfully!"

echo "==> [2/3] Importing test agent '${AGENT_NAME}'..."
orchestrate agents remove -n "${AGENT_NAME}" -k native 2>/dev/null || true

cat <<EOF | orchestrate agents import -f -
spec_version: v1
kind: agent
name: ${AGENT_NAME}
display_name: "Local Stdio Ticket Agent"
description: "Agent to test local stdio mcp-ticket-demo tools"
instructions: |
  You are an IT helpdesk support assistant.
  Use search_tickets to search for open tickets.
  Use get_ticket to retrieve ticket details.
tools:
  - "${TOOLKIT_NAME}:search_tickets"
  - "${TOOLKIT_NAME}:get_ticket"
EOF

echo "==> [3/3] Probing agent..."
orchestrate chat ask -n "${AGENT_NAME}" -l "Search for any open tickets and summarize them." || true

echo "======================================================================"
echo " ✅ Local Stdio Test Completed!"
echo "======================================================================"
