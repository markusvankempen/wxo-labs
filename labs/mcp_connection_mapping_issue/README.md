# MCP Tool — `connections.key_value()` Not Working

**Author:** Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)  
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)  
*No bug too small, no syntax too weird.*

---

## 🐛 The Problem

The user created a WxO key-value connection (`render_images`) and successfully registered
it with the MCP toolkit using `--app-id "render_images"`. However, calling
`connections.key_value(WATSONX_APP_ID)` inside the MCP tool returns nothing or raises
a `KeyError`.

### Their Setup
```bash
orchestrate connections add -a render_images
orchestrate connections configure -a render_images --env draft --type team --kind key_value
orchestrate connections set-credentials -a render_images --env draft \
  -e "BASE_URL=xxx" -e "USER_NAME=xxx" -e "API_KEY=xxx" -e "IMAGE_ANALYSIS_DEPLOYMENT_ID=xxx"

orchestrate toolkits add \
  --kind mcp \
  --name fetch-the-image-and-display \
  --package-root . \
  --command "python render_images.py" \
  --tools "*" \
  --app-id "render_images"     # ← links the connection to the toolkit
```

### Their Code (Broken)
```python
from ibm_watsonx_orchestrate.run import connections  # ← PROBLEM

def get_watsonx_creds():
    creds = connections.key_value(WATSONX_APP_ID)  # ← Returns nothing in MCP context
```

---

## 🔍 Root Cause

**`connections.key_value()` is a Python Tool runtime construct — it is NOT designed for MCP tools.**

The `ibm_watsonx_orchestrate.run.connections` module works by intercepting an
injected runtime context that WxO provides to **native Python tools** running inside
the WxO Python sandbox environment.

For **MCP tools**, the runtime model is completely different:

| Feature | Python Tool (`@tool`) | MCP Tool (`@mcp.tool`) |
|---|---|---|
| Runs inside | WxO Python sandbox | **Separate sidecar process** (subprocess) |
| Connection injection | Via `connections.key_value()` SDK call | Via **environment variables** injected into the process |
| `--app-id` effect | Links credentials for SDK | Injects creds as `ENV VARS` into the process |

### ADK Documentation Confirmation
From the ADK docs (section 10.6 — MCP Toolkits):
> *"For Local MCP, the values from `my_env_connection` are mapped directly to **environment variables** securely injected into the sidecar process. The connection auth type determines how they are passed, but `key_value` is most common."*

**Conclusion:** WxO injects the key-value credentials as environment variables when it
spawns the MCP server process. The correct way to read them is `os.environ`, NOT
the `connections` SDK module.

---

## ✅ The Fix

Replace the `connections.key_value()` call with `os.environ` (or `os.getenv`).

```python
# BEFORE (Broken in MCP context):
from ibm_watsonx_orchestrate.run import connections

def get_watsonx_creds():
    creds = connections.key_value(WATSONX_APP_ID)
    return creds

# AFTER (Correct for MCP tools):
import os

def get_watsonx_creds():
    required_keys = ["BASE_URL", "USER_NAME", "API_KEY", "IMAGE_ANALYSIS_DEPLOYMENT_ID"]
    creds = {k: os.environ.get(k) for k in required_keys}
    missing = [k for k, v in creds.items() if not v]
    if missing:
        raise KeyError(f"Missing required credentials as env vars: {', '.join(missing)}")
    return creds
```

WxO will automatically read the values from the `render_images` connection
and inject them as `BASE_URL`, `USER_NAME`, `API_KEY`, and
`IMAGE_ANALYSIS_DEPLOYMENT_ID` environment variables when the MCP process starts.

---

## 🛡️ Local Development Pattern

When testing locally (outside of WxO), the env vars won't be injected. Use a
`.env` file and `python-dotenv` as a fallback:

```python
import os
from dotenv import load_dotenv

# Loads .env for local dev; WxO env vars take precedence when deployed
load_dotenv()

def get_watsonx_creds():
    required_keys = ["BASE_URL", "USER_NAME", "API_KEY", "IMAGE_ANALYSIS_DEPLOYMENT_ID"]
    creds = {k: os.environ.get(k) for k in required_keys}
    missing = [k for k, v in creds.items() if not v]
    if missing:
        raise KeyError(
            f"Missing credentials: {', '.join(missing)}. "
            f"Set them in your .env file locally, or via 'orchestrate connections set-credentials' for WxO."
        )
    return creds
```

See `render_images_fixed.py` in this directory for the full corrected tool.

---

## ⚠️ Key-value connection name → env var mapping

WxO injects the key-value pairs **exactly as you provided them** via `set-credentials -e`.
The env var name **is** the key you used:

```bash
# You set:
-e "BASE_URL=xxx"

# WxO injects into your MCP process:
os.environ["BASE_URL"] == "xxx"  # ✅
```

There is no prefix or namespace transformation. The key is the env var name, 1:1.

---

## 🛠️ Troubleshooting & Verification

If your credentials are still missing in WxO after switching to `os.environ`, use the following checklist to verify your configuration:

### 1. Verification Commands
Use the `orchestrate` CLI to ensure everything is bound correctly:

*   **Check Toolkit Binding**: Run `orchestrate toolkits list`.
    *   *Verify:* The **App ID** column for your toolkit must match the name of your connection (e.g., `render_images`).
*   **Check Connection Status**: Run `orchestrate connections list`.
    *   *Verify:* The connection should be listed and enabled. If it isn't, the sidecar won't receive the environment variables.

### 2. The "Diagnostic Tool" Pattern
To see exactly what WxO is injecting into your sidecar, add this temporary diagnostic tool to your MCP server:

```python
@mcp.tool()
def debug_env_vars() -> dict:
    """
    DEBUG: Lists environment variables visible to this MCP subprocess (masked).
    """
    import os
    env_snapshot = {
        k: (v[:8] + "..." if len(v) > 8 else "[SET]")
        for k, v in sorted(os.environ.items())
        if k not in ("PATH", "PYTHONPATH", "HOME", "USER", "SHELL", "TERM")
    }
    return {"total_vars": len(env_snapshot), "vars": env_snapshot}
```

Deploy this and call it from the WxO chat. If your keys (e.g., `BASE_URL`) don't appear in the output, the issue is with the **connection registration** or the **`--app-id` flag** during toolkit addition.

---

## Summary Checklist

- [ ] Remove `from ibm_watsonx_orchestrate.run import connections` from your MCP tool
- [ ] Replace `connections.key_value(...)` with `os.environ.get(KEY_NAME)`
- [ ] Keep `--app-id "render_images"` in the toolkit `add` command — this is what tells WxO to inject the creds
- [ ] Add `load_dotenv()` with a `.env` file for local testing

*Author: Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)*
*No bug too small, no syntax too weird.*
