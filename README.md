# WXO Labs — Watsonx Orchestrate Tutorial Guide

**Author:** Markus van Kempen · [markusvankempen.github.io](https://markusvankempen.github.io/)

Hands-on learning path for **IBM watsonx Orchestrate** — 15 progressive labs from your first Python tool to MCP integration, SSO, RBAC, observability, and RAG evaluation.

## Start here

| Resource | Link |
|----------|------|
| **Interactive lab catalog** | [markusvankempen.github.io/wxo-labs](https://markusvankempen.github.io/wxo-labs/) |
| **Full tutorial (Markdown)** | [WXO_LABS_TUTORIAL_GUIDE.md](./WXO_LABS_TUTORIAL_GUIDE.md) |
| **Lab source code** | [`labs/`](./labs/) — runnable examples for each lab |

## Lab overview

| Level | Labs | Topics |
|-------|------|--------|
| 🟢 Easy | 1–3 | Hello World, Pydantic defaults, file upload |
| 🟡 Intermediate | 4–8 | Context injection, async jobs, downloads, **MCP basics & advanced** |
| 🔴 Advanced | 9–11, 15 | RBAC plugins, Entra ID SSO, agent CI/CD, **Remote MCP (Streamable HTTP, SSE & Observability)** |
| 🏆 Expert | 12–14 | Audit logging, observability dashboard, RAG evaluation |

## Prerequisites

```bash
pip install ibm-watsonx-orchestrate
orchestrate --version
orchestrate env activate
```

## Repository layout

```
wxo-labs/
├── docs/                      # GitHub Pages site (lab catalog UI)
├── WXO_LABS_TUTORIAL_GUIDE.md # Complete step-by-step guide
└── labs/                      # Reference implementations per lab
    ├── hello_world_tutorial/
    ├── mcp_discovery_test/
    ├── mcp_user_context_test/
    ├── mcp_ticket_demo_e2e/
    └── ...
```

## Related projects

- [WxO ToolBox VS Code Extension](https://github.com/markusvankempen/WxO-ToolBox-vsc) — export/import/compare WxO resources
- [WxO Builder MCP Server](https://github.com/markusvankempen/wxo-builder-mcp-server) — manage agents & tools from Cursor
- [WxO Agent MCP](https://github.com/markusvankempen/wxo-agent-mcp) — invoke a single WxO agent via MCP

## License

Apache License 2.0 — see [LICENSE](./LICENSE).

*No bug too small, no syntax too weird.*
