# IBM Planning Analytics (TM1) Enterprise MCP Integration: API Key & OAuth 2.0 Authentication Flows

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 16 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  
- **Tags:** `#watsonxOrchestrate` `#IBMPlanningAnalytics` `#TM1` `#ModelContextProtocol` `#MCP` `#OAuth2.0` `#APIKeyAuth` `#EnterpriseAI`

---

## Why This Pattern Matters

Enterprise financial analysts and business planners rely on IBM Planning Analytics (TM1) for multi-dimensional cube budgeting, rolling forecasts, and variance modeling. Connecting watsonx Orchestrate agents to TM1 via the Model Context Protocol (MCP) enables conversational querying of TM1 servers, cubes, dimensions, and MDX views. This lab covers two end-to-end authentication patterns: Flow 1 (API Key/Basic Auth with realm='apikey') which works seamlessly on both SaaS trials and enterprise tenants, and Flow 2 (OAuth 2.0 Authorization Code Flow via PA Workspace with the mandatory v0userContext scope).

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`toolkit_pa_apikey.yaml`)

```python
spec_version: v1
kind: mcp
name: planning_analytics_apikey
description: "IBM Planning Analytics MCP Universal Endpoint (API Key / Basic Auth)"
transport: streamable_http
url: "https://us-east-1.planninganalytics.saas.ibm.com/api/Z7LGTIG97RKC/v0/agentic-ai/ibm-pa-tools/mcp"
tools:
  - "*"
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
name: planning_analytics_agent
title: "IBM Planning Analytics AI Agent"
description: "Enterprise financial and operational planning agent connected to IBM Planning Analytics via MCP."
model: ibm/granite-3-8b-instruct
instructions: |
  You are an expert IBM Planning Analytics (TM1) financial and operational planning assistant.
  Inspect available TM1 servers or cube schemas, and execute queries using the appropriate tool.
tools:
  - planning_analytics_apikey:get_available_tm1_servers
  - planning_analytics_apikey:get_tm1_cubes
  - planning_analytics_apikey:get_cube_dimensions
  - planning_analytics_apikey:list_cube_views
  - planning_analytics_apikey:get_cube_sample_members
  - planning_analytics_apikey:execute_mdx_and_get_view
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
orchestrate chat ask -n planning_analytics_agent "What are the available TM1 servers?"
```

**Live Response:**

```text
╭─ 🤖 planning_analytics_agent ────────────────────────────────────────────────╮
│                                                                              │
│  The TM1 environment currently has the following server available:           │
│                                                                              │
│  - **BusinessFlow**                                                          │
│                                                                              │
╰──────────────────────────────────────────────────────────────────────────────╯
```

---

## 💡 Pro Tips & Gotchas

- **CM-UNKNOWN-001: Failed to obtain access token:** PA Workspace OAuth strictly mandates the scope `v0userContext`. Without this scope, the OAuth token endpoint rejects the exchange.
- **Trial vs Enterprise Subscriptions:** In trial accounts, the Administration > Integrations menu is restricted. Always use Flow 1 (API Key / Basic Auth with realm='apikey') which is 100% supported on all tiers.
- **Universal Route Handshake:** Ensure the remote endpoint URL matches your account and tenant ID: `https://<region>.planninganalytics.saas.ibm.com/api/<tenantId>/v0/agentic-ai/ibm-pa-tools/mcp`.


---

## 🏷️ Article Tags

`#watsonxOrchestrate` `#IBMPlanningAnalytics` `#TM1` `#ModelContextProtocol` `#MCP` `#OAuth2.0` `#APIKeyAuth` `#EnterpriseAI`

---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
