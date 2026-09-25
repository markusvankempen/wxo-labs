# Input Defaults & UI Patterns in watsonx Orchestrate: Supercharging UX with Smart Pydantic Schemas

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 2 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  

---

## Why This Pattern Matters

In enterprise workflows like financial approvals or travel requests, users often don't know the exact parameters required, leading to repetitive validation errors. By enforcing smart defaults and range constraints with Pydantic in watsonx Orchestrate, our AI agent can pre-fill sensible defaults (e.g. $1,000 standard budget) and let users override only what is necessary.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`financial_tool.py`)

```python
from ibm_watsonx_orchestrate import tool
from pydantic import BaseModel, Field

class FinancialApprovalInput(BaseModel):
    """Input schema for financial approval with UI defaults."""
    amount: float = Field(
        default=1000.0,
        description="The amount to approve (USD)",
        ge=0.0,
        le=1000000.0
    )
    reason: str = Field(
        default="Standard equipment refresh",
        description="Reason for the approval request"
    )
    urgent: bool = Field(
        default=False,
        description="Mark as urgent for expedited manager review"
    )

@tool
def request_financial_approval(input: FinancialApprovalInput) -> str:
    """Submit a financial approval request with pre-filled defaults."""
    urgency = "🚨 URGENT" if input.urgent else "📋 Standard"
    return f"""
{urgency} Financial Approval Request Submitted
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Amount:   ${input.amount:,.2f} USD
Reason:   {input.reason}
Status:   Pending Department Review
Tracking: WXO-REQ-{(hash(input.reason) % 100000):05d}
"""
```

---

## 📦 Step 2: Declare Dependencies (`requirements.txt`)

```text
ibm-watsonx-orchestrate>=2.9.0
pydantic>=2.0.0
```

---

## 🤖 Step 3: Configure the AI Agent (`agent.yaml`)

```yaml
spec_version: v1
kind: native
name: finance_approval_agent
title: "Finance Approval Assistant"
description: "Assists employees with submitting financial purchase requests with smart defaults."
model: ibm/granite-3-8b-instruct
instructions: |
  You are an enterprise finance assistant.
  When a user requests financial approval, inspect their prompt for amounts and reasons.
  If they do not specify an amount, use the tool's smart default.
  Always confirm the submission details back to the user.
tools:
  - request_financial_approval
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
orchestrate chat ask -n finance_approval_agent "I need financial approval for new test monitors for $3500"
```

**Live Response:**

```text
╭─ 🤖 finance_approval_agent ───────────────────────────────────────────╮
│                                                                        │
│  📋 Standard Financial Approval Request Submitted                      │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                              │
│  Amount:   $3,500.00 USD                                               │
│  Reason:   new test monitors                                           │
│  Status:   Pending Department Review                                   │
│  Tracking: WXO-REQ-84729                                               │
│                                                                        │
│  Your request has been submitted to the finance desk for processing.   │
╰────────────────────────────────────────────────────────────────────────╯
```

---

## 💡 Pro Tips & Gotchas

- **Pydantic v1 vs v2 compatibility:** Ensure you use standard Pydantic Field definitions with ge/le constraints. WxO ADK 2.9+ bundles Pydantic v2.
- **Default UI Rendering:** When an agent invokes a tool in web chat with defaults, the parameters are pre-populated, dramatically decreasing conversational friction.


---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
