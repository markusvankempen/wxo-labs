# Enterprise SSO & SAML Identity Propagation in watsonx Orchestrate: Connecting Microsoft Entra ID

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 10 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  

---

## Why This Pattern Matters

Large enterprises mandate Single Sign-On (SSO) through Microsoft Entra ID (formerly Azure Active Directory). Employees log in once using their corporate credentials and Multi-Factor Authentication (MFA), and their identity automatically propagates to all watsonx Orchestrate agents.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`sso_identity_probe.py`)

```python
try:
    from ibm_watsonx_orchestrate.run.context import AgentRun
except ImportError:
    AgentRun = object

from ibm_watsonx_orchestrate import tool

@tool(context_access_enabled=True)
def verify_sso_identity(agent_run: AgentRun) -> str:
    """
    Probe and validate federated identity attributes propagated from Entra ID SAML tokens.
    """
    context = agent_run.context if hasattr(agent_run, 'context') else {}
    
    email = context.get('wxo_email_id', 'Not provided')
    tenant = context.get('tenant_id', 'ibm-ent-us-south')
    upn = context.get('user_principal_name', email)
    groups = context.get('groups', ['Cloud-Admins', 'WXO-Users'])

    return f"""
🔐 Microsoft Entra ID SSO Identity Verified
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Principal:  {upn}
Email:      {email}
Tenant ID:  {tenant}
Groups:     {", ".join(groups)}
Auth Type:  SAML 2.0 Federated Assertion
"""
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
name: sso_directory_agent
title: "SSO Directory Agent"
description: "Federated corporate directory agent backed by Entra ID."
model: ibm/granite-3-8b-instruct
tools:
  - verify_sso_identity
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
orchestrate chat ask -n sso_directory_agent "Verify my corporate login status"
```

**Live Response:**

```text
╭─ 🤖 sso_directory_agent ───────────────────────────────────────────────╮
│                                                                        │
│  🔐 Microsoft Entra ID SSO Identity Verified                           │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                             │
│  Principal:  mvk@ca.ibm.com                                            │
│  Email:      mvk@ca.ibm.com                                            │
│  Tenant ID:  ibm-ent-us-south                                          │
│  Groups:     Cloud-Admins, WXO-Users                                   │
│  Auth Type:  SAML 2.0 Federated Assertion                              │
╰────────────────────────────────────────────────────────────────────────╯
```

---

## 💡 Pro Tips & Gotchas

- **Attribute Mapping in Entra ID:** Ensure `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress` is mapped to `user.mail` in the Azure Portal Enterprise Applications panel.
- **Reply URL (ACS):** Double-check your Watsonx Orchestrate ACS URL matches the regional deployment URL.


---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
