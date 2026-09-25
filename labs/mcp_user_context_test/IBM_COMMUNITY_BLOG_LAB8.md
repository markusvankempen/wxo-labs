# Enterprise Security with MCP & watsonx Orchestrate: Passing User Context and Bearer Tokens to Sidecars

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 8 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  
- **Tags:** `#watsonxOrchestrate` `#MCPSecurity` `#BearerTokens` `#JWT` `#OAuth` `#EnterpriseSecurity` `#Starlette`

---

## Why This Pattern Matters

When an agent queries an external database via MCP, how does the MCP server know WHO is executing the command? We cannot let the LLM see raw security tokens. In this lab, we implement transport-level HTTP Bearer token injection where WXO forwards the user's authenticated token directly in the HTTP header.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`mcp_sse_server.py`)

```python
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route
import base64
import json

async def check_identity(request):
    """Inspect the incoming Bearer token injected by watsonx Orchestrate."""
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return JSONResponse({"error": "Unauthorized: Missing Bearer Token"}, status_code=401)
    
    token = auth_header.split(" ")[1]
    try:
        payload_segment = token.split(".")[1]
        decoded = base64.b64decode(payload_segment + "==").decode("utf-8")
        claims = json.loads(decoded)
        user_email = claims.get("email", claims.get("sub", "authenticated_user"))
        roles = claims.get("roles", ["viewer"])
    except Exception:
        user_email = "authenticated_sso_user"
        roles = ["user"]

    return JSONResponse({
        "status": "authenticated",
        "user_email": user_email,
        "roles": roles,
        "identity_source": "WxO Connection HTTP Injection"
    })

routes = [Route("/check-identity", endpoint=check_identity, methods=["GET"])]
app = Starlette(routes=routes)
```

---

## 📦 Step 2: Declare Dependencies (`requirements.txt`)

```text
starlette>=0.30.0
uvicorn>=0.25.0
```

---

## 🤖 Step 3: Configure the AI Agent (`agent.yaml`)

```yaml
spec_version: v1
kind: native
name: secure_identity_agent
title: "Secure Identity Agent"
description: "Delegates authenticated queries using connection-injected Bearer tokens."
model: ibm/granite-3-8b-instruct
tools:
  - check_identity
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
curl -H "Authorization: Bearer <TOKEN>" http://localhost:8000/check-identity
```

**Live Response:**

```text
{
  "identity_source": "WxO Connection HTTP Injection",
  "roles": ["admin"],
  "status": "authenticated",
  "user_email": "markus@ca.ibm.com"
}
```

---

## 💡 Pro Tips & Gotchas

- **Token Leakage Prevention:** Never pass raw tokens as prompt arguments to the LLM. Always inject them at the transport layer (`Authorization: Bearer`) using WXO Connection settings.
- **JWT Expiry:** Ensure downstream services handle token refresh or expect fresh tokens on every agent dialogue turn.


---

## 🏷️ Article Tags

`#watsonxOrchestrate` `#MCPSecurity` `#BearerTokens` `#JWT` `#OAuth` `#EnterpriseSecurity` `#Starlette`

---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
