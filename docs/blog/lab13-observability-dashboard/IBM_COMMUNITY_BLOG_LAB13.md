# Live Observability & Telemetry for watsonx Orchestrate: Monitoring Agent Health, Latency, and Token Spend

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 13 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  
- **Tags:** `#watsonxOrchestrate` `#Observability` `#Telemetry` `#TokenTracking` `#Grafana` `#PerformanceMonitoring` `#DevOps`

---

## Why This Pattern Matters

Operating 50+ enterprise agents without observability is running blind. Who is consuming all the Granite tokens? Why is the CRM tool taking 8 seconds to respond? We build an end-to-end telemetry collector and interactive live dashboard.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`telemetry_collector.py`)

```python
import time
from collections import defaultdict
from datetime import datetime

class AgentTelemetry:
    def __init__(self):
        self.metrics = defaultdict(lambda: {"invocations": 0, "total_ms": 0, "errors": 0, "tokens": 0})

    def record(self, agent_name: str, duration_ms: float, tokens: int, error: bool = False):
        m = self.metrics[agent_name]
        m["invocations"] += 1
        m["total_ms"] += duration_ms
        m["tokens"] += tokens
        if error:
            m["errors"] += 1

    def summary(self):
        print(f"📊 LIVE TELEMETRY SNAPSHOT [{datetime.utcnow().strftime('%H:%M:%S')}]")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        for agent, m in self.metrics.items():
            avg_lat = m["total_ms"] / m["invocations"] if m["invocations"] > 0 else 0
            err_rate = (m["errors"] / m["invocations"] * 100) if m["invocations"] > 0 else 0
            print(f"Agent: {agent:25} | Invocations: {m['invocations']:5} | Avg Latency: {avg_lat:6.1f}ms | Tokens: {m['tokens']:7} | Errors: {err_rate:4.1f}%")

collector = AgentTelemetry()
collector.record("hello_world_greeter", 320, 185)
collector.record("finance_approval_agent", 840, 420)
collector.record("async_job_manager", 1450, 610)
collector.summary()
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
name: telemetry_enabled_agent
title: "Monitored Agent"
model: ibm/granite-3-8b-instruct
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
python3 telemetry_collector.py
```

**Live Response:**

```text
📊 LIVE TELEMETRY SNAPSHOT [20:25:00]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Agent: hello_world_greeter       | Invocations:     1 | Avg Latency:  320.0ms | Tokens:     185 | Errors:  0.0%
Agent: finance_approval_agent    | Invocations:     1 | Avg Latency:  840.0ms | Tokens:     420 | Errors:  0.0%
Agent: async_job_manager         | Invocations:     1 | Avg Latency: 1450.0ms | Tokens:     610 | Errors:  0.0%
```

---

## 💡 Pro Tips & Gotchas

- **Prometheus / OpenTelemetry Export:** Expose telemetry on a `/metrics` endpoint in OpenTelemetry format to integrate with Grafana, Instana, and Datadog.
- **Token Quotas:** Set threshold alerts when token velocity exceeds standard developer budgets.


---

## 🏷️ Article Tags

`#watsonxOrchestrate` `#Observability` `#Telemetry` `#TokenTracking` `#Grafana` `#PerformanceMonitoring` `#DevOps`

---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
