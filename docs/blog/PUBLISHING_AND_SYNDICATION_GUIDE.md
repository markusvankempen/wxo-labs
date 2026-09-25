# WXO Labs: Web Publishing & Syndication Strategy Guide

This guide details the distribution, syndication, and publishing workflow for the **16-part WXO Labs Developer Series**. Each lab includes production-ready code, live tests, OpenAPI/MCP specifications, responsive dark-mode presentations, and pre-formatted HTML for the IBM Community CMS.

---

## 1. Distribution Channel Matrix

| Tier | Platform / Community | Target Labs | Primary Objective |
| :--- | :--- | :--- | :--- |
| **Tier 1 (Core)** | **IBM Community — watsonx Orchestrate** | **All 16 Labs** + Series Overview | Direct engagement with IBM clients, business partners, IBM Champions, and active Orchestrate builders. |
| **Tier 1 (Specialized)** | **IBM Community — Planning Analytics** | **Lab 16** (TM1 MCP Integration) | Reach TM1 modelers, FP&A architects, and finance automation specialists. |
| **Tier 1 (Automation)** | **IBM Community — Global IT Automation** | **Labs 5, 9, 11, 12, 13, 15** | Target enterprise platform engineers, IT Sec, DevOps, and SRE teams. |
| **Tier 2 (Syndication)** | **IBM Developer (developer.ibm.com)** | Labs 1, 7, 8, 15, 16 | Formal developer portal tutorials with high organic search indexation. |
| **Tier 2 (Tech Media)** | **Medium (IBM Watson / Towards Data Science)** | All Labs (cross-posted) | Global AI developer reach (with canonical link pointing to GitHub Pages). |
| **Tier 3 (Open Ecosystem)**| **Model Context Protocol (MCP) Showcase** | **Labs 7, 8, 15, 16** | Feature in official Anthropic MCP Discord `#showcase` and GitHub Discussions. |
| **Tier 3 (Developer Hubs)**| **Dev.to / Hashnode** | Labs 1–16 | SEO backlinks and syndication (using `canonical_url` tag). |
| **Tier 4 (Social Amplification)**| **LinkedIn & X (Twitter)** | Weekly cadence per lab | Drive developer traffic directly to the live GitHub repository & Docs site. |

---

## 2. Platform Destination Details & URLs

### A. Primary Destination: IBM Community Hub
* **Hub URL:** [https://community.ibm.com/community/user/watsonxorchestrate/home](https://community.ibm.com/community/user/watsonxorchestrate/home)
* **Group Path:** `IBM Community Hub > Global IT Automation > watsonx Orchestrate`
* **Format:** Ready-to-paste HTML via the `ibm_community_post.html` file in each lab folder.
* **Why it matters:** This is the home for certified IBM partners, enterprise clients, product managers, and solution architects using watsonx Orchestrate daily.

### B. Specialized Destination: Planning Analytics Community
* **Hub URL:** [https://community.ibm.com/community/user/planninganalytics/home](https://community.ibm.com/community/user/planninganalytics/home)
* **Group Path:** `IBM Community Hub > Business Analytics > Planning Analytics`
* **Target Post:** **Lab 16 — IBM Planning Analytics TM1 MCP Enterprise Integration**
* **Why it matters:** Bridges the gap between financial cube modeling (TM1py, MDX, dimensions) and agentic LLM workflows.

### C. Open Source / Open Ecosystem: Model Context Protocol (MCP)
* **Official MCP Registry & Docs:** [https://modelcontextprotocol.io](https://modelcontextprotocol.io)
* **Community GitHub:** [https://github.com/modelcontextprotocol/servers/discussions](https://github.com/modelcontextprotocol/servers/discussions)
* **Target Posts:**
  * **Lab 7:** Model Context Protocol (MCP) Discovery & Tool Binding
  * **Lab 8:** Advanced MCP User Context & State Handling
  * **Lab 15:** Remote Server-Sent Events (SSE) MCP on IBM Cloud Code Engine
  * **Lab 16:** IBM Planning Analytics TM1 Enterprise MCP Server
* **Value:** Positions IBM watsonx Orchestrate alongside Anthropic Claude as a premier enterprise host for MCP tools.

### D. Medium & Dev.to Syndication
* **Canonical Policy:** Always set canonical URL to the corresponding `https://markusvankempen.github.io/wxo-labs/blog/labX-...` page. This ensures Google credits domain authority to `markusvankempen.github.io`.
* **Publication Targets:**
  * *IBM Data and AI / IBM Watson on Medium*
  * *Level Up Coding / Towards Data Science*
  * *Dev.to (`#ibm`, `#ai`, `#python`, `#mcp` tags)*

---

## 3. IBM Community CMS Publishing Checklist

Every lab folder under `docs/blog/` contains an `ibm_community_post.html` file with a pre-filled **Metadata Cheat Sheet** at the top (lines 1–28).

### Step-by-Step Copy & Paste Procedure:
1. Open the target lab's `ibm_community_post.html` (e.g., `docs/blog/lab1-hello-world/ibm_community_post.html`).
2. Navigate to [IBM Community Blog Submission Form](https://community.ibm.com/community/user/watsonxorchestrate/blogs).
3. Click **"Write a Blog Post"**.
4. Fill in the form fields using the top cheat sheet comments:
   * **Title**: Paste the `Meta Title` (e.g., `Getting Started with watsonx Orchestrate: Build Your First Custom Python Tool & AI Agent in 15 Minutes`).
   * **Associated Group**: Select `watsonx Orchestrate` (under `Global IT Automation`).
   * **Meta Description**: Paste the concise 155-character description provided.
   * **Featured Image**: Enter the raw GitHub URL (e.g., `https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/assets/wxo_blog_banner.jpg`).
   * **Canonical URL**: Enter the GitHub Pages live URL (e.g., `https://markusvankempen.github.io/wxo-labs/blog/getting-started-watsonx-orchestrate/`).
   * **Tags / Keywords**: Copy the comma-separated tag list.
5. In the blog body editor, click the **Source (`<>`)** code icon.
6. Copy the HTML content **below line 30** (starting with `<!-- BLOG ARTICLE BODY: Copy from here down -->`) and paste it into the Source view.
7. Click **Preview** to verify headers, badges, code snippets, and image rendering.
8. Click **Publish**.

---

## 4. Master Index of Series Articles & Metadata

| # | Lab Code & Focus | IBM Community Group | Canonical URL | GitHub Source Folder |
| :---: | :--- | :--- | :--- | :--- |
| **0** | **Series Overview** | watsonx Orchestrate | `https://markusvankempen.github.io/wxo-labs/blog/` | `docs/blog/index.html` |
| **1** | **Hello World Tool** | watsonx Orchestrate | `.../getting-started-watsonx-orchestrate/` | `labs/lab1_hello_world_tutorial/` |
| **2** | **Input Defaults & Schema** | watsonx Orchestrate | `.../lab2-input-defaults/` | `labs/lab2_input_default_test/` |
| **3** | **Multipart File Upload** | watsonx Orchestrate | `.../lab3-file-upload-processing/` | `labs/lab3_file_upload_test/` |
| **4** | **Context Injection (X-Context)** | watsonx Orchestrate | `.../lab4-context-injection/` | `labs/lab4_context_injection_test/` |
| **5** | **Async Tools & Polling** | watsonx Orchestrate / Automation | `.../lab5-async-tools-background-jobs/` | `labs/lab5_async_tool/` |
| **6** | **Streaming File Downloads** | watsonx Orchestrate | `.../lab6-file-downloads-streaming/` | `labs/lab6_download_file_and_stream_e2e_test/` |
| **7** | **MCP Discovery & Specs** | watsonx Orchestrate | `.../lab7-mcp-basics/` | `labs/lab7_mcp_discovery_test/` |
| **8** | **MCP User Context Injection** | watsonx Orchestrate | `.../lab8-mcp-advanced-user-context/` | `labs/lab8_mcp_user_context_test/` |
| **9** | **RBAC Plugin Security** | watsonx Orchestrate / Automation | `.../lab9-rbac-plugin-security/` | `labs/lab9_rbac_plugin/` |
| **10** | **Entra ID SSO & OIDC** | watsonx Orchestrate | `.../lab10-sso-entra-id/` | `labs/lab10_sso_entra_id_test/` |
| **11** | **Agent CI/CD Lifecycle** | watsonx Orchestrate / Automation | `.../lab11-agent-cicd-lifecycle/` | `labs/lab11_agent_import_e2e_test/` |
| **12** | **Audit Vault & Compliance** | watsonx Orchestrate / Automation | `.../lab12-conversation-audit-vault/` | `labs/lab12_conversation_logging_plugin/` |
| **13** | **Observability Dashboard** | watsonx Orchestrate / Automation | `.../lab13-observability-dashboard/` | `labs/lab13_wxo_observability_dashboard/` |
| **14** | **RAG Evaluation (Ragas)** | watsonx Orchestrate | `.../lab14-rag-evaluation-pipeline/` | `labs/lab14_ragas_rag_eval_e2e_test/` |
| **15** | **Remote SSE MCP on Cloud** | watsonx Orchestrate / Automation | `.../lab15-remote-mcp-code-engine/` | `labs/lab15_mcp_connection_mapping_issue/` |
| **16** | **Planning Analytics TM1 MCP** | watsonx Orchestrate / Planning Analytics | `.../lab16-planning-analytics-mcp/` | `labs/planning_analytics_mcp_e2e/` |

---

## 5. Recommended Publishing Cadence (8-Week Program)

Publishing 2 labs per week delivers sustained community momentum, predictable release expectations, and optimal search indexing.

* **Week 1: Fundamentals & Quick Wins**
  * *Tuesday:* Series Kickoff & Lab 1 (Hello World & First Agent in 15 Minutes)
  * *Thursday:* Lab 2 (Mastering OpenAPI Schemas & Input Defaults)
* **Week 2: Advanced Payloads & Data Ingestion**
  * *Tuesday:* Lab 3 (Multipart File Processing & Document AI)
  * *Thursday:* Lab 4 (Runtime User Context Injection & Session Tokens)
* **Week 3: Asynchronous Operations & Streaming**
  * *Tuesday:* Lab 5 (Background Tasks, Webhooks, & 202 Polling)
  * *Thursday:* Lab 6 (Streaming Large Binary Reports & Dynamic File Delivery)
* **Week 4: Model Context Protocol (MCP) Mastery**
  * *Tuesday:* Lab 7 (Model Context Protocol Demystified: FastMCP Server)
  * *Thursday:* Lab 8 (Dynamic Session Context & Identity in MCP)
* **Week 5: Enterprise Governance & Identity**
  * *Tuesday:* Lab 9 (Zero-Trust RBAC & Plugin Security Scopes)
  * *Thursday:* Lab 10 (Enterprise Single Sign-On with Microsoft Entra ID)
* **Week 6: Production Operations & Compliance**
  * *Tuesday:* Lab 11 (Automating Agent CI/CD Lifecycle & Import CLI)
  * *Thursday:* Lab 12 (Immutable Conversation Logging & Audit Vault)
* **Week 7: SRE, Telemetry & Quality Assurance**
  * *Tuesday:* Lab 13 (OpenTelemetry Dashboards & Prometheus Latency Tracking)
  * *Thursday:* Lab 14 (Automated RAG Evaluation with Ragas & Granite 3)
* **Week 8: Cloud Scale & Enterprise Line of Business**
  * *Tuesday:* Lab 15 (Deploying Remote SSE MCP to IBM Cloud Code Engine)
  * *Thursday:* Lab 16 (Enterprise FP&A: IBM Planning Analytics TM1 MCP Server)

---

## 6. Social Media & Developer Community Copy Templates

### LinkedIn Post Template (For Lab Launches)
```markdown
🚀 Excited to release Lab [X] of our 16-part hands-on series for IBM watsonx Orchestrate!

Today's focus: [Lab Title]

In this tutorial, you'll learn:
👉 [Key takeaway 1]
👉 [Key takeaway 2]
👉 [Key takeaway 3]

Full code, OpenAPI/MCP specs, and ready-to-deploy containers are open source on GitHub:
🔗 Live Guide: https://markusvankempen.github.io/wxo-labs/blog/[lab-folder]/
🔗 Code Repository: https://github.com/markusvankempen/wxo-labs

#IBMwatsonx #watsonxOrchestrate #AIAgents #Python #OpenAPI #ModelContextProtocol #EnterpriseAI
```

### Discord / Slack Showcase Template (For MCP Community)
```markdown
Hey everyone! Just open-sourced a full enterprise integration tutorial demonstrating Model Context Protocol (MCP) with IBM watsonx Orchestrate:

**Title:** [Lab Title]
**What it does:** Connects an LLM agent directly to [Backend System e.g., IBM Planning Analytics TM1 / Code Engine] via FastMCP and SSE.
**Tech Stack:** Python 3.11, FastMCP, Server-Sent Events, IBM Cloud Code Engine, Granite 3.
**Repository & Guide:** https://github.com/markusvankempen/wxo-labs
```

---

## 7. SEO & Verification Checklist Before Launch

- [x] All images hosted on GitHub raw (`https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/assets/...`) to avoid broken links in third-party CMSs.
- [x] Canonical link tags `<link rel="canonical" href="...">` present in all HTML pages.
- [x] Open Graph (`og:title`, `og:image`, `og:description`) and Twitter Card tags configured.
- [x] Schema.org `TechArticle` JSON-LD structured data embedded.
- [x] GitHub Repository topics set (`watsonx-orchestrate`, `mcp`, `ai-agents`, `granite-3b`, `python`).
