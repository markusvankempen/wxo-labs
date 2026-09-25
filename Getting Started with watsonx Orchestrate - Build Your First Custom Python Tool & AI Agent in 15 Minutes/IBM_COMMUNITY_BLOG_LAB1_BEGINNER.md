# Getting Started with watsonx Orchestrate: Build Your First Custom Python Tool & AI Agent in 15 Minutes

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 1 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  

---

## Why Custom Tools Matter

Large Language Models (LLMs) are great at answering questions, but on their own, they cannot query your company database, trigger an internal API, or execute deterministic business logic.

In **IBM watsonx Orchestrate (WXO)**, tools give your AI agents hands and feet. You can write custom logic in plain Python, decorate it with `@tool`, and publish it directly to your Orchestrate catalog. From there, the LLM autonomously extracts parameters from conversational dialogue and executes your Python code.

In this quick, hands-on tutorial (adapted from **Lab 1** of the [WXO Labs Series](https://markusvankempen.github.io/wxo-labs/)), we will build, deploy, and chat with your very first custom Python tool and native AI agent from scratch in **under 15 minutes**.

---

## 📋 Prerequisites

Before starting, ensure you have:
1. **Python 3.10+** installed on your workstation.
2. The **IBM watsonx Orchestrate CLI**:
   ```bash
   pip install ibm-watsonx-orchestrate
   ```
3. Your active environment set up (verify with `orchestrate env list`).

---

## 🛠️ Step 1: Write Your Python Tool (`greetings.py`)

Create a new directory for your project:
```bash
mkdir -p ~/wxo_lab1_greeter && cd ~/wxo_lab1_greeter
```

Create a file named `greetings.py`:

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

### 💡 What makes this work?
* **`@tool` decorator:** Automatically registers the Python function as an Orchestrate tool.
* **Type annotations (`name: str`):** Orchestrate inspects Python type hints to generate the JSON input schema.
* **Docstrings:** The LLM reads the function description and `Args:` documentation to decide **when** to call the tool and **which parameters** to extract from the user's prompt!

---

## 📦 Step 2: Define Requirements (`requirements.txt`)

Create a `requirements.txt` file in the same directory:

```txt
ibm-watsonx-orchestrate>=2.9.0
```

---

## 🚀 Step 3: Import the Tool into watsonx Orchestrate

Run the following CLI command to package and upload your Python tool to your Orchestrate environment:

```bash
orchestrate tools import -k python -f greetings.py -r requirements.txt
```

You should see:
```text
[INFO] - Successfully imported tool 'greet_user'
```

Verify that it appears in your catalog:
```bash
orchestrate tools list | grep greet_user
```

---

## 🤖 Step 4: Create and Configure Your AI Agent (`agent.yaml`)

Now let's build an AI agent that knows how to use our new tool. Create a file named `agent.yaml`:

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

## 🚢 Step 5: Import, Deploy, and Test Your Agent

### 1. Import and Deploy
```bash
# Import the agent manifest
orchestrate agents import -f agent.yaml

# Deploy the agent to your active environment
orchestrate agents deploy -n hello_world_greeter
```

### 2. Test Live via the CLI
Ask the agent a question:
```bash
orchestrate chat ask -n hello_world_greeter "Say hello to Markus"
```

**Live Output:**
```text
╭─ 🤖 hello_world_greeter ───────────────────────────────────────────────╮
│                                                                        │
│  Hello, Markus! Welcome to IBM watsonx Orchestrate.                    │
│                                                                        │
╰────────────────────────────────────────────────────────────────────────╯
```

The agent analyzed your prompt, recognized that it should greet "Markus", extracted `name="Markus"`, invoked `greet_user(name="Markus")` in Python, and returned the greeting!

---

## 🎯 Challenge: Add Multi-Language Support!

Ready to take it one step further? 

Try modifying `greetings.py` to accept an optional `language` parameter:

```python
from ibm_watsonx_orchestrate import tool

@tool
def greet_user(name: str, language: str = "en") -> str:
    """
    Generate a personalized greeting in the requested language.

    Args:
        name: The person to greet.
        language: Language code ('en' for English, 'es' for Spanish, 'fr' for French, 'de' for German).
    """
    greetings = {
        "en": f"Hello, {name}! Welcome to IBM watsonx Orchestrate.",
        "es": f"¡Hola, {name}! Bienvenido a IBM watsonx Orchestrate.",
        "fr": f"Bonjour, {name}! Bienvenue dans IBM watsonx Orchestrate.",
        "de": f"Guten Tag, {name}! Willkommen bei IBM watsonx Orchestrate."
    }
    return greetings.get(language.lower(), greetings["en"])
```

Re-import the tool:
```bash
orchestrate tools import -k python -f greetings.py -r requirements.txt
```

Now ask your agent:
```bash
orchestrate chat ask -n hello_world_greeter "Greet Carlos in Spanish"
```
The agent will automatically map `language="es"` and reply in Spanish!

---

## 🗺️ What’s Next in Your Journey?

Congratulations! You've completed **Lab 1** of our hands-on curriculum.

This is the first of **15 progressive labs** designed to take you from foundational Python tools to enterprise production architectures.

* 🟢 **Foundation (Labs 1–3):** UI input defaults, file uploads, and document parsing.
* 🟡 **Intermediate (Labs 4–8):** User context injection (`{wxo_user_name}`), async background jobs, file streaming, and Model Context Protocol (MCP) servers.
* 🔴 **Advanced (Labs 9–11, 15):** Role-Based Access Control (RBAC), Entra ID SSO, CI/CD export/import, and remote containerized MCP services.
* 🏆 **Expert (Labs 12–14):** Enterprise audit vaults, live observability dashboards, and RAG evaluation pipelines.

Explore the complete interactive curriculum and source code:
* 🌐 **Interactive Portal:** [https://markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
* 📦 **GitHub Repository:** [https://github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)

*Have questions or want to see a specific topic covered in Part 2? Drop a comment below!*
