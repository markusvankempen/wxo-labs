#!/usr/bin/env bash
# ---
# Author: Markus van Kempen | mvk@ca.ibm.com
# Teardown script for mcp-ticket-demo E2E test suite
# ---
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="${SCRIPT_DIR}/.run"

stop_pid() {
  local name="$1"
  local pidfile="${RUN_DIR}/${name}.pid"
  if [[ -f "$pidfile" ]]; then
    local pid
    pid="$(cat "$pidfile" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      echo "Stopping ${name} (PID ${pid})..."
      kill "$pid" 2>/dev/null || true
      sleep 1
      if kill -0 "$pid" 2>/dev/null; then
        kill -9 "$pid" 2>/dev/null || true
      fi
    fi
    rm -f "$pidfile"
  fi
}

echo "==> Cleaning up mcp-ticket-demo processes..."
stop_pid "mcp"
stop_pid "ngrok"

# Fallback: kill any orphaned mcp-ticket-demo or ngrok started on port 8080
pkill -f "mcp-ticket-demo" 2>/dev/null || true

echo "==> Cleanup complete."
