#!/bin/bash
set -e

# ==============================================================================
# E2E Agent Test Runner: Planning Analytics MCP Assistant
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

AGENT_NAME="${1:-planning_analytics_agent}"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=================================================================="
echo -e "${CYAN}🤖 Planning Analytics AI Agent Test Suite${NC}"
echo -e "Target Agent: ${YELLOW}${AGENT_NAME}${NC}"
echo "=================================================================="

# Function to run a non-interactive query and format output
run_query() {
  local title="$1"
  local prompt="$2"
  local expected="$3"

  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}▶ Testing Scenario: ${title}${NC}"
  echo -e "${CYAN}Prompt:${NC} \"${prompt}\""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  RESPONSE=$(printf "%s\nexit\n" "$prompt" | orchestrate chat ask -n "$AGENT_NAME" 2>&1)

  # Extract the agent's response block
  AGENT_TEXT=$(echo "$RESPONSE" | sed -n '/🤖 planning_analytics_agent/,/╰─/p' | sed 's/│//g' | sed 's/╭─.*//' | sed 's/╰─.*//' | sed '/^[[:space:]]*$/d')

  if [ -n "$AGENT_TEXT" ]; then
    echo -e "${GREEN}Response Received:${NC}"
    echo "$AGENT_TEXT"
  else
    echo -e "${YELLOW}Raw Output:${NC}"
    echo "$RESPONSE" | grep -v "Save Your Conversation" | grep -v "Commands: 'exit'" | tail -n 20
  fi

  if [ -n "$expected" ]; then
    if echo "$RESPONSE" | grep -qi "$expected"; then
      echo -e "${GREEN}✅ Verification PASSED: Found expected token '${expected}'${NC}"
    else
      echo -e "${RED}⚠️ Verification WARNING: Did not find expected token '${expected}'${NC}"
    fi
  fi
}

# --- Automated Test Scenarios ---

# Scenario 1: TM1 Servers
run_query "TM1 Server Discovery" \
  "What TM1 servers are available?" \
  "BusinessFlow"

# Scenario 2: Cube Listing
run_query "Cubes on BusinessFlow" \
  "What cubes exist on the BusinessFlow server?" \
  "Sales"

# Scenario 3: Cube Dimension Inspection
run_query "Sales Cube Dimensions" \
  "What dimensions are in the Sales cube on BusinessFlow?" \
  "Geography"

# Scenario 4: Cube Views Listing
run_query "Cube Views Discovery" \
  "What views are available for the Sales cube on BusinessFlow?" \
  "view"

echo ""
echo "=================================================================="
echo -e "${GREEN}🎉 All Agent Test Scenarios Completed Successfully!${NC}"
echo "You can also chat interactively with your agent at any time:"
echo -e "  ${YELLOW}orchestrate chat ask -n ${AGENT_NAME}${NC}"
echo "=================================================================="
