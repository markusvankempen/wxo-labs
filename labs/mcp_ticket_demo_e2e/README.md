# MCP Ticket Demo — End-to-End Testing & Diagnostic Suite for WxO

**Author:** Markus van Kempen | mvk@ca.ibm.com  
**Research | Floor 7½ 🏢🤏** — [https://pages.github.ibm.com/mvankempen/homepage/](https://pages.github.ibm.com/mvankempen/homepage/)  
*No bug too small, no syntax too weird.*

---

## 🎯 Purpose & Background

This suite provides **automated, end-to-end test scripts and reference configurations** for testing Model Context Protocol (MCP) integrations with **IBM watsonx Orchestrate (WxO)**.

It uses [`mcp-ticket-demo`](https://www.npmjs.com/package/mcp-ticket-demo) (GitHub: [markusvankempen/mcp-ticket-demo](https://github.com/markusvankempen/mcp-ticket-demo/tree/main/server)) — a production-shaped reference MCP server that supports:
* Both **Streamable HTTP** (`/mcp`) and **Server-Sent Events** (`/sse`).
* Local **stdio** subprocess execution.
* Three authentication modes (`off`, `write`, `all`) with API keys via custom headers (`x-api-key` or `Authorization: Bearer <token>`).
* Live observability via `/health`, `/test`, and a real-time `/log` request trace dashboard.

### The Problem It Solves: `Gateway creation failed: 422`

When registering a remote MCP server in WxO (via ADK CLI or Web UI), users often encounter:
```
[ERROR] - Failed to create toolkit: Gateway creation failed: 422 {"detail":"An error occurred, please try again."}
```

This error occurs when the WxO SaaS backend (e.g. in Toronto `ca-tor`) fails its initial outbound handshake (`initialize` and `tools/list`) with the remote MCP route.

The primary root causes this suite diagnoses:
1. **Unreachable Route / Corporate VPN:** The MCP server is on a private network (e.g. Red Hat internal OpenShift route, internal ingress, VPN) not accessible over the public internet by WxO cloud pods.
2. **Untrusted TLS/SSL:** The route uses an internal corporate CA or self-signed certificate rejected by IBM Cloud containers.
3. **Endpoint Path Mismatch:** Providing the base domain instead of `/mcp` (Streamable HTTP) or `/sse` (SSE).
4. **Connection / Header Mismatch:** Using a `key_value` connection without setting draft credentials, or passing credentials in a format the MCP server rejects.

---

## 📁 Suite Structure

```
mcp_ticket_demo_e2e/
├── README.md                      # This comprehensive guide
├── env.example                    # Sample configuration
├── deploy_remote_e2e.sh           # Main automated remote MCP deployment script
├── deploy_local_stdio.sh          # Local stdio MCP deployment script
├── test_debug_scenarios.sh        # Runner for all 6 diagnostic scenarios
├── stop.sh                        # Teardown script for background processes
├── toolkit_streamable_http.yaml   # Remote MCP manifest for Streamable HTTP
├── toolkit_sse.yaml               # Remote MCP manifest for SSE
├── toolkit_local_stdio.yaml       # Local Stdio MCP manifest
├── connection_api_key.yaml        # Connection using kind: api_key (--name "x-api-key")
├── connection_key_value.yaml      # Connection using kind: key_value
└── agent.yaml                     # Test agent definition binding MCP tools
```

---

## 🚀 Quickstart: Run Baseline Test (Zero Auth)

The fastest way to verify that WxO's remote MCP gateway is functioning in your environment:

```bash
cd mcp_ticket_demo_e2e
cp env.example .env

# Run automated deployment (launches server, starts ngrok tunnel, registers toolkit, deploys agent)
./deploy_remote_e2e.sh
```

During execution:
* The script starts `mcp-ticket-demo` on port 8080 with `AUTH_MODE=off`.
* It opens an HTTPS tunnel via `ngrok`.
* It registers the remote toolkit in WxO using `transport: streamable_http` and `url: https://<ngrok-id>.ngrok-free.app/mcp`.
* It prints the **Live Call Trace URL** (`https://<ngrok-id>.ngrok-free.app/log`) where you can see WxO's incoming handshake in real time!

To stop all background processes:
```bash
./stop.sh
```

---

## 🔬 The 6 Diagnostic Scenarios

Run individual diagnostic scenarios with `./test_debug_scenarios.sh <number>`:

### Scenario 1: Baseline Streamable HTTP (`AUTH_MODE=off`)
```bash
./test_debug_scenarios.sh 1
```
* **Purpose:** Proves WxO remote MCP gateway creation and dynamic tool discovery (`tools: ["*"]`) work over Streamable HTTP without credentials.
* **If it succeeds:** Confirms WxO cloud backend in your region can reach and parse standard Streamable HTTP endpoints.

### Scenario 2: Baseline Server-Sent Events (`transport: sse`)
```bash
./test_debug_scenarios.sh 2
```
* **Purpose:** Tests the SSE transport at `/sse`.
* **Use case:** When integrating with servers built with FastMCP or Python MCP SDK that default to SSE.

### Scenario 3: Custom Header Auth using `kind: api_key` (Recommended)
```bash
./test_debug_scenarios.sh 3
```
* **Purpose:** Tests authenticating requests via a custom HTTP header (e.g. `x-api-key: <token>` or QRadar's `SEC: <token>`).
* **Connection configuration:**
  ```bash
  orchestrate connections configure -a mcp_ticket_conn --env draft --type team --kind api_key --name "x-api-key"
  orchestrate connections set-credentials -a mcp_ticket_conn --env draft --api-key "secret-key"
  ```

### Scenario 4: Custom Header Auth using `kind: key_value`
```bash
./test_debug_scenarios.sh 4
```
* **Purpose:** Validates passing custom headers via `key_value` pair connections.
* **Connection configuration:**
  ```bash
  orchestrate connections configure -a mcp_ticket_conn --env draft --type team --kind key_value
  orchestrate connections set-credentials -a mcp_ticket_conn --env draft -e "x-api-key=secret-key"
  ```

### Scenario 5: [REPRODUCTION] Missing Draft Credentials
```bash
./test_debug_scenarios.sh 5
```
* **Purpose:** Recreates the exact `Gateway creation failed: 422` error by creating a connection but intentionally leaving the `draft` credentials unset.
* **Observation:** The remote server rejects WxO's unauthenticated `tools/list` handshake with 401/403, and WxO immediately surfaces `Gateway creation failed: 422`.

### Scenario 6: [REPRODUCTION] Unreachable / Internal Route
```bash
./test_debug_scenarios.sh 6
```
* **Purpose:** Recreates the failure when the URL points to a private internal host (`https://internal-cluster-route.local.lan/mcp`).
* **Observation:** Confirms that network unreachability triggers the gateway creation error.

---

## 💻 Local Stdio MCP Alternative

If an MCP server does not need to be hosted as a remote cloud microservice, WxO can run it locally as a subprocess:

```bash
./deploy_local_stdio.sh
```

Under the hood:
```bash
orchestrate toolkits add \
  --kind mcp \
  --name mcp_ticket_local \
  --description "Local MCP Ticket Demo" \
  --package "mcp-ticket-demo" \
  --language node \
  --tools "*"
```

---

## 📊 Live Observability Dashboard

One of the best debugging features of `mcp-ticket-demo` is its built-in web endpoints:

| Endpoint | Description |
|---|---|
| `/health` | Unauthenticated JSON health status (auth mode, port, tool count) |
| `/test` | Read-only smoke test running queries against the internal ticket store |
| `/log` | **Live Call Trace:** Displays incoming HTTP method, endpoint, headers, and payload |
| `/admin` | Web UI to toggle auth modes, lock/unlock tools, and view issued API keys (default login `demo`/`demo`) |

When WxO calls `tools/list` or executes a tool, refresh the `/log` page to see the exact headers and JSON-RPC body WxO sent!
