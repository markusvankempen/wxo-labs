# MCP User Context Passing in Watsonx Orchestrate

This repository is a **fully working, end-to-end validated** reference implementation that proves WxO injects a user Bearer token into every outbound tool HTTP call. It can be cloned, deployed with a single script, and used as a blueprint for connecting MCP tool servers that need to act on behalf of the logged-in WxO user.

> **Validated on:** March 14 2026 · WxO ADK 2.6.0 · Python 3.12 · ngrok free tier

---

## Table of Contents

1. [Why this matters](#why-this-matters)
2. [Architecture](#architecture)
3. [Repository file map](#repository-file-map)
4. [The two identity patterns](#the-two-identity-patterns)
5. [Prerequisites](#prerequisites)
6. [Step-by-step replication guide](#step-by-step-replication-guide)
7. [Validated test results](#validated-test-results)
8. [FAQ — answering the core question](#faq--answering-the-core-question)
9. [Production roadmap](#production-roadmap)
10. [Official references](#official-references)

---

## Why this matters

When a user is authenticated in Orchestrate (e.g., via OIDC/IAM) and the agent invokes an MCP tool, the MCP server often needs to know the user's identity to:
1. Personalise responses.
2. Create audit trails (who did what, when).
3. Perform actions on behalf of the user in downstream systems (Maximo, SAP, ServiceNow).

Since Orchestrate and those target systems share the same Identity Provider (IDP), we can pass the user context without asking the user for credentials again. This repo proves it works.

---

## Architecture

### High-level token flow

```mermaid
sequenceDiagram
    participant User as 👤 User (Browser / CLI)
    participant WxO as 🤖 WxO Agent Runtime
    participant Conn as 🔑 WxO Connection<br/>(mcp_ctx_bearer)
    participant NGrok as 🌐 ngrok tunnel
    participant MCP as 🖥️ MCP SSE Server<br/>(mcp_sse_server.py)
    participant IDP as 🏛️ IBM IAM / MCSP IDP

    User->>WxO: "check identity"
    WxO->>WxO: Selects tool: get_session_identity
    WxO->>Conn: Retrieve stored Bearer token
    Conn-->>WxO: Authorization: Bearer <JWT>
    WxO->>NGrok: GET /check-identity\nAuthorization: Bearer <JWT>
    NGrok->>MCP: Proxied HTTP request
    MCP->>MCP: Extract Authorization header
    MCP->>MCP: Base64-decode JWT payload\n→ email: mvk4ibm@gmail.com
    MCP-->>NGrok: JSON {status, username, token_preview, pattern}
    NGrok-->>WxO: HTTP 200 JSON response
    WxO-->>User: "Username: mvk4ibm@gmail.com\nToken: eyJraWQ..."

    Note over IDP,Conn: One-time setup: exchange API key for JWT\ncurl POST /apikeys/token → signed JWT\nstored in connection via CLI
```

### Component deployment diagram

```mermaid
graph TD
    subgraph local["💻 Local Machine (macOS)"]
        server["mcp_sse_server.py<br/>Starlette ASGI<br/>port 8000"]
        ngrok["ngrok tunnel<br/>:4040 admin<br/>→ localhost:8000"]
    end

    subgraph wxo["☁️ IBM WxO DEV Instance"]
        agent["Agent<br/>mcp_auth_tester_agent<br/>(mcp_agent_def.yaml)"]
        tool["Tool<br/>get_session_identity<br/>(mcp_context_openapi.json)"]
        conn["Connection<br/>mcp_ctx_bearer<br/>type=team, kind=bearer"]
        agent -->|uses| tool
        tool -->|secured by| conn
    end

    subgraph idp["🏛️ IBM MCSP IAM"]
        token_ep["POST /apikeys/token<br/>→ signed JWT"]
    end

    conn -.->|stored credential| token_ep
    tool -->|"GET /check-identity\nAuthorization: Bearer JWT"| ngrok
    ngrok --> server

    user["👤 WxO User\n(browser / CLI)"] --> agent
```

### What happens inside the MCP server per request

```mermaid
flowchart LR
    A["HTTP Request\narrives at /check-identity"] --> B{Authorization\nheader present?}
    B -- No --> C["Return warning JSON\nstatus: warning\nusername: NOT_FOUND"]
    B -- Yes --> D["Extract token\nafter 'Bearer '"]
    D --> E["Split JWT into\nheader.payload.signature"]
    E --> F["Base64-decode\npayload segment"]
    F --> G["Parse JSON claims\n{sub, email, iat, exp}"]
    G --> H["Pick username:\nemail → preferred_username → sub"]
    H --> I["Return success JSON\nstatus: success\nusername: mvk4ibm@gmail.com\ntoken_preview: eyJra..."]
```

---

## Repository file map

| File | Purpose |
|---|---|
| [`mcp_sse_server.py`](mcp_sse_server.py) | **Main server.** Starlette ASGI app with two routes: `/sse` (MCP SSE for native clients) and `/check-identity` (REST JSON for WxO OpenAPI tool calls). Extracts the Bearer token from the `Authorization` header and decodes the JWT payload to return `username`. |
| [`mcp_context_openapi.json`](mcp_context_openapi.json) | **WxO tool definition.** OpenAPI 3.1 spec imported into WxO. Defines the `get_session_identity` operation at `GET /check-identity`, declares `bearerAuth` security, lists the `username`, `token_preview`, `status`, `pattern` response fields. |
| [`mcp_agent_def.yaml`](mcp_agent_def.yaml) | **WxO agent definition.** Imported via CLI. `kind: native`, `name: mcp_auth_tester_agent`, `title: MCP Identity Tester`, links to the `get_session_identity` tool. |
| [`deploy_to_wxo.sh`](deploy_to_wxo.sh) | **Deploy script.** Imports the tool and agent into the active WxO environment in one command. |
| [`simulated_orchestrate_client.py`](simulated_orchestrate_client.py) | Local STDIO simulation — tests Pattern 2 (parameter injection) without a live WxO instance. |
| [`simulated_wxa_sse_client.py`](simulated_wxa_sse_client.py) | Local SSE simulation — spins up an SSE client and manually injects an `Authorization` header to test the server header-extraction logic. |
| [`test_locally.sh`](test_locally.sh) | Runs `simulated_orchestrate_client.py` after checking for the `mcp` SDK. |
| [`mcp_context_openapi_basic.json`](mcp_context_openapi_basic.json) | Minimal OpenAPI variant (no auth) for quick smoke-testing. |
| [`patch_auth.yaml`](patch_auth.yaml) | YAML patch for updating auth config on an existing WxO tool. |
| [`.env`](.env) | **Not committed** (in `.gitignore`). Stores `WO_INSTANCE_URL`, `WO_TRIAL_API_KEY`, `username`, `password`. |

---

## The two identity patterns

### Pattern 1 — Transport Level (Bearer Token in HTTP Header) ✅ *validated in this repo*

WxO injects the Bearer token at the HTTP layer. The tool server reads `request.headers.get("Authorization")`. The LLM never sees the raw token.

```
WxO Runtime → HTTP GET /check-identity
              Authorization: Bearer eyJraWQiOiJ2MWJk...
                                     ↑ injected by WxO Connection
MCP Server ← extracts token, decodes JWT, returns username
```

**Pros:** Token is invisible to the LLM. Works with any HTTP server. No schema changes needed.  
**Cons:** With `--type team` the same service token is used for all users (see [Production roadmap](#production-roadmap) for per-user tokens).

### Pattern 2 — Application Level (Parameter Injection)

WxO injects the user's email as a hidden tool argument via `{{user.email}}` mapping in Skill Settings.

```
WxO Runtime → calls tool with arguments:
              {"injected_user_id": "mvk4ibm@gmail.com"}
                                    ↑ injected by WxO Skill Settings
MCP Server ← reads from JSON-RPC arguments
```

**Pros:** Simple. No HTTP header parsing. Works with STDIO MCP servers.  
**Cons:** The identity value passes through the LLM's argument construction — less secure for sensitive tokens.

---

## Prerequisites

| Requirement | Version tested | Install |
|---|---|---|
| Python | 3.12 | `brew install python` |
| `mcp` SDK | latest | `pip install mcp` |
| `starlette` + `uvicorn` | latest | `pip install starlette uvicorn` |
| `orchestrate` CLI (IBM ADK) | 2.6.0 | IBM internal distribution |
| `ngrok` | free tier | `brew install ngrok/ngrok/ngrok` |
| Active WxO DEV instance | - | IBM WxO trial or enterprise |

---

## Step-by-step replication guide

### Step 1 — Clone and install dependencies

```bash
git clone <this-repo>
cd mcp_user_context_test
pip install mcp starlette uvicorn
```

### Step 2 — Create your `.env` file

```bash
cat > .env << 'EOF'
WO_INSTANCE_URL=https://api.dl.watson-orchestrate.ibm.com/instances/<your-instance-id>
WO_TRIAL_API_KEY=<your-mcsp-api-key>
username=<your-wxo-login-email>
password=<your-wxo-login-password>
EOF
```

> The `.gitignore` already excludes `.env`. Never commit credentials.

### Step 3 — Run local tests (no WxO account needed)

```bash
# STDIO test — Pattern 2 (parameter injection)
./test_locally.sh

# SSE test — Pattern 1 (header extraction)
python mcp_sse_server.py &          # terminal 1: start server
python simulated_wxa_sse_client.py  # terminal 2: run client
```

Expected output:
```
✅ SSE Tool Invoked via WxO!
🔍 The tool securely extracted the following Token from the HTTP Request Headers:
> Bearer eyJhbGciOiJIUzI1NiJ9...
```

### Step 4 — Expose the server via ngrok

```bash
ngrok http 8000
# Copy the https URL: e.g. https://0ea9-99-239-88-232.ngrok-free.app
```

Update the `servers[0].url` in [`mcp_context_openapi.json`](mcp_context_openapi.json) to your ngrok URL:

```json
"servers": [{ "url": "https://<your-ngrok-subdomain>.ngrok-free.app" }]
```

### Step 5 — Activate your WxO CLI environment

```bash
source .env
orchestrate env activate DEV
# Enter your API key when prompted
orchestrate env list   # confirm (active) shows next to DEV
```

### Step 6 — Create the WxO connection

This is the credential store that WxO uses to inject the Bearer token into tool calls.

```bash
source .env

# 6a. Register the connection app-id
orchestrate connections add --app-id mcp_ctx_bearer

# 6b. Configure it as a team-level bearer token connection (draft + live)
orchestrate connections configure \
  --app-id mcp_ctx_bearer --env draft \
  --type team --kind bearer \
  --server-url "https://<your-ngrok-subdomain>.ngrok-free.app"

orchestrate connections configure \
  --app-id mcp_ctx_bearer --env live \
  --type team --kind bearer \
  --server-url "https://<your-ngrok-subdomain>.ngrok-free.app"

# 6c. Exchange the MCSP API key for a signed JWT
REAL_JWT=$(curl -s -X POST \
  "https://iam.platform.saas.ibm.com/siusermgr/api/1.0/apikeys/token" \
  -H "Content-Type: application/json" \
  -d "{\"apikey\": \"${WO_TRIAL_API_KEY}\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

# 6d. Store the JWT as the Bearer credential
orchestrate connections set-credentials \
  --app-id mcp_ctx_bearer --env draft --token "$REAL_JWT"

orchestrate connections set-credentials \
  --app-id mcp_ctx_bearer --env live --token "$REAL_JWT"
```

> **Note:** JWTs from this endpoint expire in ~2 hours. Re-run steps 6c–6d to refresh. See [token refresh one-liner](#token-refresh-one-liner) below.

### Step 7 — Deploy the tool and agent

```bash
# Import the OpenAPI tool spec linked to the connection
orchestrate tools import \
  --file mcp_context_openapi.json \
  --kind openapi \
  --app-id mcp_ctx_bearer

# Import the agent definition
orchestrate agents import --file mcp_agent_def.yaml

# Deploy the agent so it appears in the WxO chat UI
orchestrate agents deploy -n mcp_auth_tester_agent
```

### Step 8 — Test via CLI

```bash
orchestrate chat ask -n mcp_auth_tester_agent "check identity"
```

Expected result:
```
╭─ 🤖 mcp_auth_tester_agent ──────────────────────────────────────────────╮
│  - Status: ✅ Success                                                   │
│  - Pattern Used: Pattern 1 – Transport Level Header Propagation         │
│  - Username: mvk4ibm@gmail.com                                          │
│  - Token Preview: eyJraWQiOiJ2MWJkdXR0T0hscGFSeURKVi1HS0ox...          │
╰─────────────────────────────────────────────────────────────────────────╯
```

### Step 9 — Test via WxO UI

1. Open `https://dl.watson-orchestrate.ibm.com`
2. Start a new chat and select **MCP Identity Tester** agent
3. Type: `check identity`
4. Click **Show Reasoning** to see the raw tool call (input `{}`, token in output)

### Token refresh one-liner

JWT credentials expire. Run this any time the tool returns `NOT_FOUND`:

```bash
source .env && \
REAL_JWT=$(curl -s -X POST "https://iam.platform.saas.ibm.com/siusermgr/api/1.0/apikeys/token" \
  -H "Content-Type: application/json" \
  -d "{\"apikey\": \"${WO_TRIAL_API_KEY}\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])") && \
orchestrate connections set-credentials --app-id mcp_ctx_bearer --env draft --token "$REAL_JWT" && \
orchestrate connections set-credentials --app-id mcp_ctx_bearer --env live  --token "$REAL_JWT" && \
echo "✅ Credentials refreshed"
```

---

## Validated test results

> **Run date:** March 14 2026 · WxO ADK 2.6.0 · Python 3.12.8 · ngrok free tier  
> All three tiers passed in a single uninterrupted session.

---

### Test 1 — Local STDIO (`python3 simulated_orchestrate_client.py`)

**Command:**
```bash
python3 simulated_orchestrate_client.py
```

**Full output (with debug trace):**
```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪  Simulated WxO STDIO Client — Flow Trace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/5] ⚙️  Server launch params:
      command : python mcp_context_server.py
      env     : WXO_USER_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dum...

[2/5] 🚀 Spawning MCP server process via STDIO...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[SERVER] 🚀  MCP Context Server starting (STDIO mode)
[SERVER]    Tool  : get_user_context
[SERVER]    Pattern 1 : reads WXO_USER_TOKEN env var
[SERVER]    Pattern 2 : reads injected_user_id argument
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ✅ MCP handshake complete

[3/5] 🗂️  Tools available on server:
      • get_user_context: Returns information about the user context received from the client

[4/5] ────────────────────────────────────────────────────────
      Scenario A — call WITHOUT context injection
      Arguments sent: {'action_name': 'Check Status'}
────────────────────────────────────────────────────────
[SERVER] ── tool='get_user_context'  action='Check Status'
[SERVER]    full arguments received: {'action_name': 'Check Status'}
[SERVER]    Pattern 2 (arg injection) injected_user_id='NOT_INJECTED'
[SERVER]    Pattern 1 (env/header token): eyJhbGciOiJIUzI1NiIsInR5c...
[SERVER]    → Pattern 2 NOT PRESENT (no injected_user_id argument)
[SERVER]    Building and returning response...
🛠️ Tool 'get_user_context' executed for action: 'Check Status'

👤 Context Mapping Pattern Results:
- Pattern 1 (Header/Env Token): eyJhbGciOi... (SIMULATED)
- Pattern 2 (Injected Argument): NOT_INJECTED

⚠️ No user identity was found in the tool arguments.

[5/5] ────────────────────────────────────────────────────────
      Scenario B — call WITH context injection (Pattern 2)
      Arguments sent: {'action_name': 'Update Maximo', 'injected_user_id': 'mvk@ca.ibm.com'}
────────────────────────────────────────────────────────
[SERVER] ── tool='get_user_context'  action='Update Maximo'
[SERVER]    full arguments received: {'action_name': 'Update Maximo', 'injected_user_id': 'mvk@ca.ibm.com'}
[SERVER]    Pattern 2 (arg injection) injected_user_id='mvk@ca.ibm.com'
[SERVER]    Pattern 1 (env/header token): eyJhbGciOiJIUzI1NiIsInR5c...
[SERVER]    → Pattern 2 SUCCESS  user='mvk@ca.ibm.com'
[SERVER]    Building and returning response...
🛠️ Tool 'get_user_context' executed for action: 'Update Maximo'

👤 Context Mapping Pattern Results:
- Pattern 1 (Header/Env Token): eyJhbGciOi... (SIMULATED)
- Pattern 2 (Injected Argument): mvk@ca.ibm.com

✅ Orchestrate Successfully passed the User ID via parameter injection.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅  Test complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**What it proves:** Scenario A shows the empty baseline (no identity without injection). Scenario B proves the MCP server receives `injected_user_id=mvk@ca.ibm.com` exactly as WxO would pass it via Skill Settings `{{user.email}}` mapping. The `[SERVER]` debug lines confirm the exact argument dict received by the tool handler.

---

### Test 2 — Local SSE (`python3 simulated_wxa_sse_client.py`)

**Command:**
```bash
python3 simulated_wxa_sse_client.py
```

**Full output (with debug trace):**
```text
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧪  Simulated WxO SSE Client — Flow Trace
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/4] 🔑 Simulated Bearer token built
      Token : eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.wxo_simulated_user_payload

[2/4] 📤 HTTP headers that will be sent to /sse:
      Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.wxo_simulated_user_payload
      X-Wxo-Agent-Id: agent-12345

[3/4] 🌐 Opening SSE connection → http://localhost:8000/sse
      ✅ MCP handshake complete

[4/4] 🛠️  Calling tool: get_session_identity
      Arguments: {"action": "Check Auth Headers"}

────────────────────────────────────────────────────────
📩  MCP Server Response:
────────────────────────────────────────────────────────
✅ SSE Tool Invoked via WxO!
🔍 The tool securely extracted the following Token from the HTTP Request Headers:

> Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.wxo_simulated_user_payload

💡 In production, you would exchange this token into an OBO (On-Behalf-Of) flow
to pass into backing enterprise systems like Maximo!
────────────────────────────────────────────────────────

EXIT:0
```

**What it proves:** The `Authorization: Bearer` header injected by the client at step [2/4] is successfully extracted by the MCP server and echoed back in the tool response. The token travels from HTTP transport layer into the `ContextVar`, then into the tool handler — without touching the JSON-RPC `arguments` dict. Exit code 0 confirms no errors.

---

### Test 3 — Live WxO CLI chat

**Command:**
```bash
source .env && orchestrate chat ask -n mcp_auth_tester_agent "check identity"
```

**Full output:**
```text
[INFO] - Using agent: mcp_auth_tester_agent (ID: 5661f0a1-a658-48dc-8444-3a78e4de431d)
╭────────────────────────────────── 💬 Chat ───────────────────────────────────╮
│ Chat Mode                                                                    │
│ Type your messages and press Enter to send.                                  │
│ Commands: 'exit', 'quit', or 'q' to exit                                     │
╰──────────────────────────────────────────────────────────────────────────────╯
╭─ 👤 User ────────────────────────────────────────────────────────────────────╮
│  check identity                                                              │
╰──────────────────────────────────────────────────────────────────────────────╯
[INFO] - First message is_async flag: False
[INFO] - Non-async agent - displaying HTTP response
╭─ 🤖 mcp_auth_tester_agent ───────────────────────────────────────────────────╮
│                                                                              │
│  Here's the identity information extracted from your request headers:        │
│                                                                              │
│  - **Token preview:** `eyJraWQiOiJ2MWJkdXR0T0hscGFSeURKVi1HS0ox...`          │
│  - **Username:** `mvk4ibm@gmail.com`                                         │
│  - **Pattern used:** *Pattern 1 – Transport Level Header Propagation*        │
│  - **Status:** Success                                                       │
│                                                                              │
│  In a production environment, you would typically exchange this token        │
│  through an **On‑Behalf‑Of (OBO)** flow to obtain the necessary access       │
│  tokens for Maximo, SAP, or other downstream services.                       │
│                                                                              │
╰──────────────────────────────────────────────────────────────────────────────╯
```

**What it proves:**
- WxO selected `mcp_auth_tester_agent` (agent ID confirmed in `[INFO]` line)
- The agent called `get_session_identity` via the `mcp_ctx_bearer` connection
- The connection injected `Authorization: Bearer <JWT>` into the outbound HTTP request to ngrok → `mcp_sse_server.py`
- The server decoded the JWT payload and returned `username: mvk4ibm@gmail.com`
- The LLM rendered the structured JSON response into natural language for the user

---

### Test 4 — Live WxO UI chat

The same result confirmed from `https://dl.watson-orchestrate.ibm.com` via the **MCP Identity Tester** agent.

**Raw tool call (visible via "Show Reasoning"):**
```json
{
  "tool": "check_auth_headers",
  "input": {},
  "output": {
    "status": "success",
    "message": "✅ WxO Identity Check: Token successfully extracted from HTTP headers!\n💡 In production, exchange this token via OBO flow for Maximo/SAP access.",
    "pattern": "Pattern 1 - Transport Level Header Propagation",
    "token_preview": "eyJraWQiOiJ2MWJkdXR0T0hscGFSeURKVi1HS0ox...",
    "username": "mvk4ibm@gmail.com"
  }
}
```

**Agent natural-language response:**
> Here's the identity information that was extracted from the request headers:
>
> - **Username:** mvk4ibm@gmail.com
> - **Token preview:** eyJraWQiOiJ2MWJkdXR0T0hscGFSeURKVi1HS0ox...
> - **Pattern used:** Transport‑Level Header Propagation (Pattern 1)
>
> The token shown is a short preview for security reasons. In a production environment, you would exchange this token via an OBO (On‑Behalf‑Of) flow to obtain the appropriate access to Maximo, SAP, or other downstream services.

**Key observation:** Tool `input` is `{}` (empty object) — the token was **not** passed as a tool argument. The LLM never saw the raw token. It arrived exclusively via the HTTP `Authorization` header injected by the WxO connection.

---

### Summary — what each test proves

| Test | Transport | Identity source | Result |
|---|---|---|---|
| **1 · STDIO** (`simulated_orchestrate_client.py`) | JSON-RPC over stdin/stdout | `injected_user_id` argument (Pattern 2) | `mvk@ca.ibm.com` via argument |
| **2 · SSE local** (`simulated_wxa_sse_client.py`) | HTTP SSE + ContextVar | `Authorization` header (Pattern 1) | Token extracted from header, never in args |
| **3 · Live WxO CLI** (`orchestrate chat ask`) | HTTP REST via ngrok | WxO connection injects real JWT | `mvk4ibm@gmail.com` decoded from live JWT |
| **4 · Live WxO UI** (browser chat) | HTTP REST via ngrok | Same WxO connection | Identical result; `input: {}` proves token NOT in args |

### How the server extracts the username (from [`mcp_sse_server.py`](mcp_sse_server.py))

```python
def _decode_jwt_payload(token: str) -> dict:
    """Decode JWT payload without signature verification (claims are not secret)."""
    parts = token.split(".")               # header . payload . signature
    padded = parts[1] + "=" * (4 - len(parts[1]) % 4)
    return json.loads(base64.b64decode(padded))

auth_header = request.headers.get("Authorization", "")
token = auth_header.split(" ", 1)[1]       # strip "Bearer "
claims = _decode_jwt_payload(token)
username = (
    claims.get("email")                    # IBM IAM / MCSP primary claim
    or claims.get("preferred_username")    # OIDC standard fallback
    or claims.get("sub")                   # last resort — user UUID
)
```

> JWT claims are base64-encoded, not encrypted. No public key, no library, no network call is required to read `email`/`sub`. Signature **verification** (confirming the token is genuine) would require the IdP's public key and is a separate, optional step for production use.

---

## FAQ — answering the core question

> **Q: Does WxO set the `Authorization` header with the Bearer token when calling the tool, and can the tool just extract that token from the HTTP header?**

**Yes — confirmed by live test.** When a tool is linked to a connection (`--app-id`), WxO automatically injects `Authorization: Bearer <token>` on every outbound HTTP call. The tool reads it from a standard HTTP header. The LLM sees neither the header nor the raw token.

> **Q: Whose token is it?**

It depends on the **connection type**:

| Connection type | CLI flag | Token injected | Use case |
|---|---|---|---|
| Team / service account | `--type team --kind bearer` | Same static JWT for all users | Shared service integrations, tested in this repo |
| Per-user OAuth2 | `--type user --kind oauth2` | The individual logged-in user's own OAuth2 token | True per-user RBAC, audit trails, OBO flows |

> **Q: What if all systems share the same IDP?**

With `--type user --kind oauth2` the user's own IDP session token flows through. The MCP server receives a JWT where `email`/`sub` is the **actual logged-in WxO user**, not a service account. Configure this with:

```bash
orchestrate connections configure \
  --app-id mcp_ctx_user --env live \
  --type user --kind oauth2 \
  --server-url "https://your-mcp-server.example.com" \
  --authorization-url "https://your-idp.example.com/oauth2/authorize" \
  --token-url "https://your-idp.example.com/oauth2/token" \
  --client-id "<client-id>" \
  --client-secret "<client-secret>"
```

---

## Production roadmap

| Capability | This repo | Production |
|---|---|---|
| Token transport | ✅ Bearer via HTTP header | ✅ Same mechanism |
| Token type | Static team JWT (refreshed manually) | Per-user OAuth2 `--type user` |
| Token decode | Base64 only (no verification) | Verify signature with IdP public key (e.g. `PyJWT`) |
| Token refresh | Manual CLI one-liner | Automatic — WxO OAuth2 handles refresh tokens |
| Server hosting | Local + ngrok | Cloud container (Code Engine, k8s) |
| OBO flow | Not implemented | Exchange user token for downstream system token via `token-exchange` grant |

### OBO (On-Behalf-Of) token exchange — production pattern

```bash
orchestrate connections set-credentials \
  --app-id your_mcp_app --env live \
  --grant-type urn:ietf:params:oauth:grant-type:token-exchange \
  --token-url <IDP_TOKEN_URL> \
  -t "body:subject_token_type=urn:ietf:params:oauth:token-type:access_token" \
  -t "body:app_token_key=subject_token"
```

This exchanges the user's WxO session token for a backend-specific access token (Maximo, SAP) without exposing the original credential.

---

## Official references

1. **[MCP Protocol — Authentication](https://mcp-framework.com/)** — MCP specification on using `Authorization: Bearer` for SSE connections.
2. **[WxO — Connecting to Applications](https://www.ibm.com/docs/en/watsonx/watsonx-orchestrate/current?topic=apps-connecting-applications)** — How WxO manages OAuth2/Bearer connections.
3. **[WxO — Authenticating with APIs](https://www.ibm.com/docs/en/watsonx/watsonx-orchestrate/current?topic=apis-authenticating-api)** — WxO sets `Authorization: Bearer <token>` in outbound tool calls.
4. **[RFC 8693 — OAuth 2.0 Token Exchange](https://www.rfc-editor.org/rfc/rfc8693)** — The standard for On-Behalf-Of flows referenced above.

---

**Author:** Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)  
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)  
*No bug too small, no syntax too weird.*
