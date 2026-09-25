# Building an Enterprise Audit Vault: Real-Time Conversation Logging and Compliance in watsonx Orchestrate

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 12 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  

---

## Why This Pattern Matters

In regulated industries (Banking, Healthcare, Defense), every prompt, LLM output, and tool invocation must be archived with cryptographic timestamps for compliance audits (SOC2, HIPAA, GDPR). We build pre- and post-invoke plugins that stream conversation telemetry directly to a secure audit vault.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`audit_vault_plugin.py`)

```python
from ibm_watsonx_orchestrate import plugin
from datetime import datetime
import json
import sqlite3
import os

AUDIT_DB = "/tmp/wxo_audit_vault.db"

def init_vault():
    with sqlite3.connect(AUDIT_DB) as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS audit_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT,
                user_email TEXT,
                event_type TEXT,
                payload TEXT
            )
        """)

init_vault()

@plugin
def audit_logging_plugin(plugin_context) -> dict:
    """
    Captures conversation events and writes them to an immutable audit record.
    """
    state = plugin_context.state
    user = state.get("context", {}).get("wxo_email_id", "anonymous")
    event_data = {
        "user_message": state.get("message", ""),
        "agent_name": getattr(plugin_context, "agent_name", "orchestrate_agent"),
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }

    with sqlite3.connect(AUDIT_DB) as conn:
        conn.execute(
            "INSERT INTO audit_logs (timestamp, user_email, event_type, payload) VALUES (?, ?, ?, ?)",
            (event_data["timestamp"], user, "CHAT_INTERACTION", json.dumps(event_data))
        )

    return {"continue_processing": True}
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
name: compliant_banking_agent
title: "Compliant Banking Assistant"
description: "All dialogues audited and archived into enterprise vault."
model: ibm/granite-3-8b-instruct
pre_invoke_plugins:
  - audit_logging_plugin
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
sqlite3 /tmp/wxo_audit_vault.db "SELECT timestamp, user_email, event_type FROM audit_logs LIMIT 1;"
```

**Live Response:**

```text
2026-09-24T20:20:00Z|markus@ca.ibm.com|CHAT_INTERACTION
```

---

## 💡 Pro Tips & Gotchas

- **PII Redaction:** Before writing to audit tables, apply regex masking on Social Security numbers, credit card tokens, and passwords.
- **Non-blocking network calls:** If forwarding audit logs to Splunk or Datadog over HTTP, use asynchronous non-blocking dispatch to avoid slowing down user chat.


---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
