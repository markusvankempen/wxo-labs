# Getting Started with watsonx Orchestrate: Build Your First Custom Python Tool & AI Agent in 15 Minutes

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 1 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  
- **Tags:** `#watsonxOrchestrate` `#AIAgents` `#Python` `#Granite3` `#CLI` `#BeginnerTutorial` `#EnterpriseAI`

---

## Why This Pattern Matters

Large Language Models (LLMs) are great at conversational synthesis, but on their own, they cannot query your company database, call an internal microservice, or run deterministic business calculations. In IBM watsonx Orchestrate (WXO), tools give your AI agents hands and feet. You can write custom logic in plain Python, decorate it with @tool, and publish it directly to your Orchestrate catalog.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`greetings.py`)

```python
from ibm_watsonx_orchestrate import tool

@tool
def greet_user(name: str) -> str:
    """
    Generate a personalized greeting for a user.

    Args:
        name: The name of the person to greet.

    Returns:
        A friendly greeting message.
    """
    return f"Hello, {name}! Welcome to IBM watsonx Orchestrate."
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
name: hello_world_greeter
title: "Hello World Greeter"
description: "A friendly onboarding agent that greets users using custom Python tools."
model: ibm/granite-3-8b-instruct
instructions: |
  You are a friendly and welcoming assistant.
  When a user introduces themselves or asks you to greet someone, extract their name
  and call the `greet_user` tool to deliver a personalized welcome.
tools:
  - greet_user
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
orchestrate chat ask -n hello_world_greeter "Say hello to Markus"
```

**Live Response:**

```text
╭─ 🤖 hello_world_greeter ───────────────────────────────────────────────╮
│                                                                        │
│  Hello, Markus! Welcome to IBM watsonx Orchestrate.                    │
│                                                                        │
╰────────────────────────────────────────────────────────────────────────╯
```

---

## 💡 Pro Tips & Gotchas

- **The @tool decorator:** Automatically registers the function signature and docstrings into the tool JSON Schema.
- **Type annotations:** Parameter types like name: str are required by Orchestrate to generate the API contract for the LLM.
- **ModuleNotFoundError:** Always include -r requirements.txt when importing tools via CLI.


---

## 🏷️ Article Tags

`#watsonxOrchestrate` `#AIAgents` `#Python` `#Granite3` `#CLI` `#BeginnerTutorial` `#EnterpriseAI`

---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
