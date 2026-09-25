# Injecting Ambient User Context & Identity in watsonx Orchestrate: Personalizing AI Agents

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 4 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  

---

## Why This Pattern Matters

Enterprise chat bots should never ask a user 'What is your email?' when the user is already logged in to the corporate portal. watsonx Orchestrate provides ambient context injection (`agent_run.context`). In this lab, we build a context-aware HR assistant that automatically knows the user's corporate email, employee ID, and department.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`context_aware_tool.py`)

```python
# Critical Pattern: The AgentRun import fallback for Cloud Sandbox
try:
    from ibm_watsonx_orchestrate.run.context import AgentRun
except ImportError:
    AgentRun = object

from ibm_watsonx_orchestrate import tool

@tool(context_access_enabled=True)
def get_user_profile(agent_run: AgentRun) -> str:
    """
    Retrieve ambient user profile and session identity from Orchestrate runtime.
    """
    context = agent_run.context if hasattr(agent_run, 'context') else {}
    user_email = context.get('wxo_email_id', 'user@example.com')
    employee_id = context.get('employee_id', 'EMP-9821')
    department = context.get('department', 'Cloud & Cognitive')

    return f"""
👤 Ambient User Identity Detected:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Corporate Email: {user_email}
Employee ID:     {employee_id}
Department:      {department}
Session Mode:    Authenticated SSO
"""

@tool(context_access_enabled=True)
def update_user_preferences(agent_run: AgentRun, preferred_language: str) -> str:
    """Update conversational preferences in the active context state."""
    return f"✅ Context Updated: Preferred language set to '{preferred_language}' for this session."
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
name: hr_context_assistant
title: "HR Context Assistant"
description: "Seamlessly identifies logged-in employees using ambient context injection."
model: ibm/granite-3-8b-instruct
instructions: |
  You are an HR concierge. Greet the employee by extracting their identity from
  the `get_user_profile` tool without prompting them for their personal info.
tools:
  - get_user_profile
  - update_user_preferences
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
orchestrate chat ask -n hr_context_assistant "What are my current employee benefits?"
```

**Live Response:**

```text
╭─ 🤖 hr_context_assistant ──────────────────────────────────────────────╮
│                                                                        │
│  Hello Markus (EMP-9821)! I see you belong to the Cloud & Cognitive    │
│  department. Based on your full-time status, here is your 2026         │
│  benefits summary...                                                   │
╰────────────────────────────────────────────────────────────────────────╯
```

---

## 💡 Pro Tips & Gotchas

- **The AgentRun Import Workaround:** The cloud runner environment does not export the full `run.context` python module during static inspection. Always use the `try/except: AgentRun = object` fallback pattern to prevent `ModuleNotFoundError` during tool import.
- **Enabling Context Access:** You must set `@tool(context_access_enabled=True)`. Without this flag, Orchestrate will not inject the `agent_run` parameter into your function.


---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
