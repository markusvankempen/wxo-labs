# Non-Blocking Async Execution in watsonx Orchestrate: Building Background Job Workers for Heavy Tasks

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 5 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  
- **Tags:** `#watsonxOrchestrate` `#AsyncExecution` `#BackgroundJobs` `#Non-Blocking` `#WorkerThreads` `#PollingPattern`

---

## Why This Pattern Matters

HTTP requests to watsonx Orchestrate tools will timeout if an operation takes longer than 30–60 seconds (such as training an ML model or aggregating 100,000 DB rows). In this lab, we build a non-blocking asynchronous pattern: start the background job, return an immediate Job ID to the user, and allow conversational polling for status.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`async_tools.py`)

```python
from ibm_watsonx_orchestrate import tool
import threading
import uuid
import time
from datetime import datetime

# In-memory job registry (use Redis/Postgres in production clusters)
JOBS = {}

@tool
def start_background_job(job_name: str, duration_seconds: int = 15) -> str:
    """
    Start a long-running background task asynchronously without blocking the chat.
    """
    job_id = str(uuid.uuid4())[:8]
    JOBS[job_id] = {
        'id': job_id,
        'name': job_name,
        'status': 'RUNNING',
        'started_at': datetime.now().strftime("%H:%M:%S"),
        'progress': '0%'
    }

    def worker():
        for pct in [25, 50, 75, 100]:
            time.sleep(duration_seconds / 4)
            JOBS[job_id]['progress'] = f"{pct}%"
        JOBS[job_id]['status'] = 'COMPLETED'
        JOBS[job_id]['completed_at'] = datetime.now().strftime("%H:%M:%S")
        JOBS[job_id]['result'] = f"Success: Dataset '{job_name}' processed (14,200 rows indexed)."

    thread = threading.Thread(target=worker, daemon=True)
    thread.start()

    return f"🚀 Background job '{job_name}' dispatched! Job ID: {job_id}. You can continue chatting while it runs."

@tool
def check_job_status(job_id: str) -> str:
    """Check the status and output of a running background job."""
    job = JOBS.get(job_id)
    if not job:
        return f"❌ Job ID '{job_id}' not found."
    
    if job['status'] == 'COMPLETED':
        return f"✅ Job {job_id} [{job['name']}] COMPLETED at {job['completed_at']}: {job['result']}"
    else:
        return f"⏳ Job {job_id} [{job['name']}] is STILL RUNNING (Progress: {job['progress']}). Started at {job['started_at']}."
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
name: async_job_manager
title: "Async Job Dispatcher"
description: "Dispatches and monitors asynchronous long-running batch operations."
model: ibm/granite-3-8b-instruct
instructions: |
  You are a background operations assistant. When a user asks to run an extensive task,
  dispatch it using `start_background_job` and give them their Job ID.
  When they query status, use `check_job_status`.
tools:
  - start_background_job
  - check_job_status
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
orchestrate chat ask -n async_job_manager "Start data aggregation for Q3 Sales"
```

**Live Response:**

```text
╭─ 🤖 async_job_manager ─────────────────────────────────────────────────╮
│                                                                        │
│  🚀 Background job 'Q3 Sales' dispatched! Job ID: 4f8a19de.             │
│  Feel free to ask other questions while the pipeline executes!         │
╰────────────────────────────────────────────────────────────────────────╯
```

---

## 💡 Pro Tips & Gotchas

- **State Persistence in Containers:** In multi-pod Kubernetes or serverless cloud environments, worker memory is isolated. In production, back your JOBS store with Redis or Cloudant.
- **Gateway Timeout Prevention:** Always return within 2 seconds of invoking `start_background_job` to maintain responsiveness.


---

## 🏷️ Article Tags

`#watsonxOrchestrate` `#AsyncExecution` `#BackgroundJobs` `#Non-Blocking` `#WorkerThreads` `#PollingPattern`

---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
