# IBM Planning Analytics MCP Integration & Testing Suite for WxO

**Author:** Markus van Kempen | mvk@ca.ibm.com  
**Research | Floor 7½ 🏢🤏** — [https://pages.github.ibm.com/mvankempen/homepage/](https://pages.github.ibm.com/mvankempen/homepage/)  
*No bug too small, no syntax too weird.*

---

## 🎯 Overview & Instance Configuration

This directory provides automated scripts, manifests, and diagnostic tooling for integrating **IBM Planning Analytics (PA) as a Service** with **watsonx Orchestrate (WxO)** via the **Model Context Protocol (MCP)** using two distinct authentication flows:

1. **Flow 1: API Key / Basic Auth** (`realm="apikey"`)
2. **Flow 2: OAuth 2.0 Authorization Code Flow** (via PA Workspace with mandatory scope `v0userContext`)

### Target Instance Parameters

| Parameter | Value |
|---|---|
| **PA Workspace Admin Console** | `https://us-east-1.planninganalytics.saas.ibm.com/?accountId=35L2PSTGTSA4&tenantId=Z7LGTIG97RKC&perspective=pa-administration` |
| **Host Region** | `us-east-1.planninganalytics.saas.ibm.com` |
| **Account ID** | `35L2PSTGTSA4` |
| **Tenant ID** | `Z7LGTIG97RKC` |
| **MCP Universal Route** | `https://us-east-1.planninganalytics.saas.ibm.com/api/Z7LGTIG97RKC/v0/agentic-ai/ibm-pa-tools/mcp` |
| **OAuth2 Authorize URL** | `https://us-east-1.planninganalytics.saas.ibm.com/oauth2/authorize` |
| **OAuth2 Token URL** | `https://us-east-1.planninganalytics.saas.ibm.com/oauth2/token` |
| **Mandatory OAuth Scope** | `v0userContext` |

---

## 🔍 Verified Live Telemetry (Endpoint Probing)

Running `./probe_endpoints.sh` against the target instance verified that the endpoints are active and confirmed the expected authentication challenges:

```http
POST /api/Z7LGTIG97RKC/v0/agentic-ai/ibm-pa-tools/mcp
HTTP/2 401 
server: cloudflare
www-authenticate: Basic realm="apikey"
www-authenticate: Bearer realm="Service"
www-authenticate: Bearer realm="siusermgr"
```

* **`Basic realm="apikey"`**: Proves **Flow 1** is supported using standard HTTP Basic authentication where username is `apikey` and password is the API key.
* **`Bearer realm="siusermgr"`**: Proves **Flow 2** is supported using OAuth2 Bearer tokens issued by PAW’s user manager (`/oauth2/token`).

---

## 📁 Repository Structure

```
planning_analytics_mcp_e2e/
├── README.md                  # This complete integration guide
├── env.example                # Sample environment configuration
├── probe_endpoints.sh         # Live diagnostic endpoint probe script
├── test_flow1_apikey.sh       # Automation runner for Flow 1 (API Key)
├── test_flow2_oauth.sh        # Automation runner for Flow 2 (OAuth2 Auth Code)
├── test_agent_scenarios.sh    # Automated multi-query agent scenario test runner
├── toolkit_pa_apikey.yaml     # Remote MCP toolkit manifest (API Key)
├── toolkit_pa_oauth.yaml      # Remote MCP toolkit manifest (OAuth2)
├── connection_pa_apikey.yaml  # WxO Connection spec (Basic Auth / API Key)
├── connection_pa_oauth.yaml   # WxO Connection spec (OAuth2 Auth Code)
├── agent.yaml                 # AI Agent binding API Key Planning Analytics tools
└── agent_oauth.yaml           # AI Agent binding OAuth Planning Analytics tools
```

---

## 🚀 Flow 1: Integration via API Key (Basic Auth)

Flow 1 uses machine-to-machine authentication via the `apikey` realm.

### Automated Execution

```bash
cp env.example .env
# Edit .env and supply PA_API_KEY
./test_flow1_apikey.sh
```

### Manual CLI Workflow

```bash
# 1. Register connection
orchestrate connections add -a pa_apikey_conn

# 2. Configure connection as basic auth on draft
orchestrate connections configure \
  -a pa_apikey_conn \
  --env draft \
  --type team \
  --kind basic

# 3. Store the credentials (username must be "apikey")
orchestrate connections set-credentials \
  -a pa_apikey_conn \
  --env draft \
  --username "apikey" \
  --password "$PA_API_KEY"

# 4. Import the MCP Toolkit
orchestrate toolkits import -f toolkit_pa_apikey.yaml -a pa_apikey_conn

# 5. Verify discovered tools (36 tools discovered)
COLUMNS=250 orchestrate tools list | grep -i "pa_apikey_conn"

# 6. Import & deploy test agent
orchestrate agents import -f agent.yaml
orchestrate agents deploy -n planning_analytics_agent

# 7. Ask agent a question
orchestrate chat ask -n planning_analytics_agent "What are the available TM1 servers?"
```

#### ✅ Verified Live Agent Response:
```text
╭─ 🤖 planning_analytics_agent ────────────────────────────────────────────────╮
│                                                                              │
│  The TM1 environment currently has the following server available:           │
│                                                                              │
│  - **BusinessFlow**                                                          │
│                                                                              │
╰──────────────────────────────────────────────────────────────────────────────╯
```

### 🤖 Running Automated Agent Tool Scenarios

We have created an automated test runner, `test_agent_scenarios.sh`, that executes multiple real TM1 analytical queries against the agent non-interactively and asserts that valid TM1 objects are returned:

```bash
./test_agent_scenarios.sh
```

**Scenarios Tested:**
1. **TM1 Server Discovery**: Asserts TM1 server `BusinessFlow` is retrieved.
2. **Cube Enumeration**: Queries all 24 cubes on `BusinessFlow` (including `Sales`, `BalanceSheet`, `IncomeStatement`).
3. **Dimension Inspection**: Retrieves the schema dimensions for `Sales` (`Sandboxes`, `Channel`, `Geography`, `Product`, `Scenario`, `Sales`, `Time`).
4. **View Discovery**: Discovers saved views on the cube (e.g. `Default` MDX view).

---

## 🔐 Flow 2: Integration via OAuth 2.0 Authorization Code Flow

Flow 2 delegates user credentials via the Planning Analytics Workspace OAuth client.

> [!WARNING]
> **Account Requirement:**
> Flow 2 requires an **Enterprise / Paid Planning Analytics SaaS subscription**.
> In **Trial accounts**, IBM explicitly restricts access to the **Administration > Integrations** tile to prevent trial abuse.
> If you are on a **Planning Analytics Trial**, use **Flow 1 (API Key / Basic Auth)**, which is 100% supported and fully functional!

### Step 1: Configure Authorized Application in PAW (Enterprise Only)

1. Open your PA Admin Console:  
   `https://us-east-1.planninganalytics.saas.ibm.com/?accountId=35L2PSTGTSA4&tenantId=Z7LGTIG97RKC&perspective=pa-administration`
2. Click the **Integrations** tile.
3. Locate **OAuth** and click **Add** (or edit existing).
4. Enter a **Client name** (e.g. `WxO-Assistant`).
5. **Add Redirect URL:** Add the WxO callback URL for your region:
   * Dallas: `https://api.dl.watson-orchestrate.ibm.com/v1/orchestrate/oauth2/callback`
   * US-South: `https://api.us-south.watson-orchestrate.ibm.com/v1/orchestrate/oauth2/callback`
   * Toronto: `https://api.tor.watson-orchestrate.ibm.com/v1/orchestrate/oauth2/callback`
   *(Check the exact Redirect URL shown in the WxO connection dialog).*
6. Click **Generate secret** and copy the **Client ID** and **Client Secret**.

### Step 2: Run the Automated Flow 2 Script

```bash
# Edit .env and supply PA_OAUTH_CLIENT_ID and PA_OAUTH_CLIENT_SECRET
./test_flow2_oauth.sh
```

### Manual CLI Workflow

```bash
# 1. Register connection
orchestrate connections add -a pa_oauth_conn

# 2. Configure as oauth_auth_code_flow on draft
orchestrate connections configure \
  -a pa_oauth_conn \
  --env draft \
  --kind oauth_auth_code_flow \
  --type team

# 3. Store credentials with mandatory scope "v0userContext"
orchestrate connections set-credentials \
  -a pa_oauth_conn \
  --env draft \
  --client-id "$PA_OAUTH_CLIENT_ID" \
  --client-secret "$PA_OAUTH_CLIENT_SECRET" \
  --auth-url "https://us-east-1.planninganalytics.saas.ibm.com/oauth2/authorize" \
  --token-url "https://us-east-1.planninganalytics.saas.ibm.com/oauth2/token" \
  --scopes "v0userContext" \
  --grant-type "authorization_code"

# 4. Import the MCP Toolkit
orchestrate toolkits import -f toolkit_pa_oauth.yaml -a pa_oauth_conn
```

---

## 🛠 Troubleshooting Common Errors

### `CM-UNKNOWN-001: "Failed to obtain access token"` (Status 500)

* **Root Cause 1: Missing Scope:** PAW **strictly requires** the scope `v0userContext`. If `--scopes` is omitted or empty, the token endpoint rejects the exchange.
* **Root Cause 2: Redirect URI Mismatch:** The redirect URL configured in PAW Administration does not match the exact callback URL WxO sends in the backchannel POST.
* **Root Cause 3: Client Secret Invalidation:** PAW only allows **one** OAuth client. If "Generate secret" was clicked again, any previous secret stopped working immediately.

### `Gateway creation failed: 422`

* **Root Cause:** WxO could not reach the MCP endpoint or the initial `initialize` JSON-RPC handshake failed.
* **Verification:** Run `./probe_endpoints.sh` to confirm network reachability and HTTP 401 response. Ensure credentials are set on `--env draft`.
