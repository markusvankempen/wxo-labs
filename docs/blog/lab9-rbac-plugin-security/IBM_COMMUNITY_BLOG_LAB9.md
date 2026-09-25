# Securing AI Agents with RBAC Pre-Invoke Plugins in watsonx Orchestrate: Multi-Role Authorization

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 9 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  
- **Tags:** `#watsonxOrchestrate` `#RBAC` `#Pre-InvokePlugins` `#AgentSecurity` `#Authorization` `#AccessControl`

---

## Why This Pattern Matters

Some AI agents have access to privileged actions (rebooting servers, deleting records, viewing payroll). Before the agent's LLM even processes a user prompt, a pre-invoke plugin intercepts the request, verifies the caller's enterprise roles, and terminates execution immediately if unauthorized.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`rbac_plugin.py`)

```python
from ibm_watsonx_orchestrate import plugin

ROLE_DIRECTORY = {
    "markus@ca.ibm.com": ["admin", "devops"],
    "alice@company.com": ["manager"],
    "guest@partner.com": ["viewer"]
}

PERMITTED_ROLES = ["admin", "devops"]

@plugin
def rbac_pre_invoke(plugin_context) -> dict:
    """
    Pre-invoke security gatekeeper.
    Evaluates caller identity against access control rules before LLM invocation.
    """
    context = plugin_context.state.get("context", {})
    user_email = context.get("wxo_email_id", "guest@partner.com")
    assigned_roles = ROLE_DIRECTORY.get(user_email, [])

    is_authorized = any(role in PERMITTED_ROLES for role in assigned_roles)

    if is_authorized:
        return {"continue_processing": True}
    else:
        return {
            "continue_processing": False,
            "message": f"""
🚫 Access Denied (HTTP 403 Forbidden)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User:      {user_email}
Required:  {", ".join(PERMITTED_ROLES)}
Assigned:  {", ".join(assigned_roles) if assigned_roles else "None"}

You do not possess the required security roles to interact with this agent.
Contact the security operations desk for role escalation.
"""
        }
```

---

## 📦 Step 2: Declare Dependencies (`requirements.txt`)

```text
ibm-watsonx-orchestrate>=2.9.0
```

---

## 🤖 Step 3: Configure the AI Agent (`agent.yaml`)

```yaml
spec_version: v1
kind: native
name: devops_remediation_agent
title: "DevOps Infrastructure Remediation Agent"
description: "High-privilege agent restricted to certified DevOps admins."
model: ibm/granite-3-8b-instruct
pre_invoke_plugins:
  - rbac_pre_invoke
instructions: |
  You are an infrastructure recovery assistant with cluster administration rights.
tools:
  - restart_kubernetes_pod
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
orchestrate chat ask -n devops_remediation_agent "Restart production payment pod"
```

**Live Response:**

```text
╭─ 🚫 rbac_pre_invoke ───────────────────────────────────────────────────╮
│                                                                        │
│  🚫 Access Denied (HTTP 403 Forbidden)                                 │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                             │
│  User:      guest@partner.com                                          │
│  Required:  admin, devops                                              │
│  Assigned:  viewer                                                     │
│                                                                        │
│  You do not possess the required security roles to interact.           │
╰────────────────────────────────────────────────────────────────────────╯
```

---

## 💡 Pro Tips & Gotchas

- **continue_processing flag:** Setting `continue_processing: False` completely bypasses model inference, saving token costs and completely eliminating prompt-injection attacks.
- **Audit Logging:** Combine pre-invoke RBAC with persistent audit logging to record unauthorized attempts.


---

## 🏷️ Article Tags

`#watsonxOrchestrate` `#RBAC` `#Pre-InvokePlugins` `#AgentSecurity` `#Authorization` `#AccessControl`

---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
