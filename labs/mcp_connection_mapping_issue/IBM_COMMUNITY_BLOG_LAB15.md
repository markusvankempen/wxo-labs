# Deploying Remote Containerized MCP Servers on IBM Cloud Code Engine: Overcoming 422 Gateway Errors & SSE Handshakes

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 15 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  

---

## Why This Pattern Matters

In production, Model Context Protocol servers run as microservices on serverless platforms like IBM Cloud Code Engine, Kubernetes, or OpenShift. When connecting Watsonx Orchestrate to a remote MCP server, developers often encounter 'Gateway creation failed: 422' due to protocol mismatches or authentication header stripping. This lab provides the battle-tested blueprint.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`server.js`)

```python
import express from "express";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { SSEServerTransport } from "@modelcontextprotocol/sdk/server/sse.js";
import { z } from "zod";

const app = express();
const server = new McpServer({
  name: "enterprise-ticket-mcp",
  version: "1.0.0"
});

server.tool(
  "query_incident",
  "Lookup incident details from enterprise ITSM",
  { incident_id: z.string().describe("Incident ticket identifier, e.g. INC-1029") },
  async ({ incident_id }) => {
    return {
      content: [{
        type: "text",
        text: `Incident ${incident_id}: High CPU Alert in cluster ca-tor. Status: Investigating.`
      }]
    };
  }
);

let transport = null;

app.get("/sse", async (req, res) => {
  console.log("👉 [WxO Handshake] SSE Connection established");
  transport = new SSEServerTransport("/message", res);
  await server.connect(transport);
});

app.post("/message", async (req, res) => {
  if (transport) {
    await transport.handlePostMessage(req, res);
  } else {
    res.status(400).send("No active transport");
  }
});

app.get("/health", (req, res) => res.json({ status: "healthy", timestamp: new Date() }));

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => console.log(`🚀 Remote MCP server listening on port ${PORT}`));
```

---

## 📦 Step 2: Declare Dependencies (`requirements.txt`)

```text
express>=4.18.2
@modelcontextprotocol/sdk>=1.0.1
zod>=3.22.0
```

---

## 🤖 Step 3: Configure the AI Agent (`agent.yaml`)

```yaml
spec_version: v1
kind: native
name: remote_incident_agent
title: "Remote Incident Commander"
description: "Connects to containerized MCP microservices running on IBM Cloud Code Engine."
model: ibm/granite-3-8b-instruct
tools:
  - query_incident
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
curl -i https://mcp-ticket-demo.ca-tor.codeengine.appdomain.cloud/health
```

**Live Response:**

```text
HTTP/2 200 
content-type: application/json; charset=utf-8
{
  "status": "healthy",
  "timestamp": "2026-09-24T20:30:00.000Z"
}
```

---

## 💡 Pro Tips & Gotchas

- **Gateway creation failed: 422:** This occurs when the WXO gateway expects Streamable HTTP (`/mcp`) but the server only implements SSE (`/sse`), or when required authentication headers are missing from the toolkit connection YAML.
- **SSE Keep-Alive:** Ensure your container reverse proxy (Nginx or Cloudflare) does not buffer Server-Sent Events with `proxy_buffering off;`.


---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
