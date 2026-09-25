# Automating Agent CI/CD Lifecycle: Exporting, Versioning, and Promoting watsonx Orchestrate Agents

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 11 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  

---

## Why This Pattern Matters

Manually re-creating tools and agents across Dev, Staging, and Production tenants is slow and error-prone. In this lab, we build a production-grade CI/CD pipeline using the Orchestrate CLI to export self-contained bundles, unpack dependencies, validate schemas, and promote across environments.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`cicd_promoter.py`)

```python
#!/usr/bin/env python3
import subprocess
import os
import sys

def run_cmd(cmd):
    print(f"👉 Executing: {cmd}")
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"❌ Error: {res.stderr}")
        sys.exit(res.returncode)
    return res.stdout

def export_and_promote(agent_name, target_env="staging"):
    bundle_path = f"/tmp/{agent_name}_bundle.zip"
    print(f"📦 Step 1: Exporting {agent_name} from Dev...")
    run_cmd(f"orchestrate agents export -n {agent_name} -k native -o {bundle_path}")

    print(f"🔄 Step 2: Activating target environment '{target_env}'...")
    run_cmd(f"orchestrate env activate {target_env}")

    print(f"📥 Step 3: Unpacking and importing bundle to {target_env}...")
    run_cmd(f"orchestrate agents import -f {bundle_path}")

    print(f"✅ Promotion of '{agent_name}' to '{target_env}' COMPLETE!")

if __name__ == "__main__":
    export_and_promote("hello_world_greeter", target_env="staging")
```

---

## 📦 Step 2: Declare Dependencies (`requirements.txt`)

```text
ibm-watsonx-orchestrate>=2.9.0
```

---

## 🤖 Step 3: Configure the AI Agent (`agent.yaml`)

```yaml
# Sample export manifest
spec_version: v1
kind: native
name: hello_world_greeter
title: "Hello World Greeter (v2.1.0)"
model: ibm/granite-3-8b-instruct
tools:
  - greet_user
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
python3 cicd_promoter.py
```

**Live Response:**

```text
👉 Executing: orchestrate agents export -n hello_world_greeter -k native -o /tmp/hello_world_greeter_bundle.zip
👉 Executing: orchestrate env activate staging
👉 Executing: orchestrate agents import -f /tmp/hello_world_greeter_bundle.zip
✅ Promotion of 'hello_world_greeter' to 'staging' COMPLETE!
```

---

## 💡 Pro Tips & Gotchas

- **Connection Secrets Exclusion:** Export bundles intentionally exclude raw API keys and connection passwords. Use environment-specific `.env` or KeyProtect vaults in staging/prod.
- **Semantic Versioning:** Always update the agent's title or version tag in YAML before committing to git.


---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
