**Author:** Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)
*No bug too small, no syntax too weird.*

---

# Import bundle (Orchestrate CLI)

This folder was created by **WxO Builder** when you exported agents, tools, and related assets. The ZIP is laid out for the Watson Orchestrate CLI **import bundle** flow.

## Import with the CLI

1. [Install the Orchestrate / wxo CLI](https://developer.watson-orchestrate.ibm.com/getting_started/installing) and sign in to your target instance (API key or trial key as per IBM docs).
2. From a terminal, run (use the real ZIP name in this folder):

```bash
orchestrate agents import -f "orchestrate-import-bundle_20260423_113525.zip"
```

Or with an absolute path:

```bash
orchestrate agents import -f "/full/path/to/ImportBundle/orchestrate-import-bundle_20260423_113525.zip"
```

The CLI will discover `agents/native/`, `tools/`, `toolkits/`, `connections/`, and `knowledge-base/` at the **root of the ZIP** and apply dependencies in the right order.

## What is in the bundle

| Path (inside ZIP) | Purpose |
|-------------------|--------|
| `agents/native/*.yaml` | Native agent definitions |
| `tools/**` | Tool source (Python, OpenAPI assets, zips, etc.) |
| `toolkits/**` | Toolkit YAMLs (e.g. MCP) |
| `connections/**` | Connection YAML/JSON |
| `knowledge-base/**` | Knowledge base YAMLs (if present in export) |

If your export had no items for a section, that folder may be absent—this is normal.

## After import

Use your usual CLI or UI commands to list agents, tools, and to test. See the [Watson Orchestrate documentation](https://developer.watson-orchestrate.ibm.com/) for `orchestrate` subcommands and options.

---
*Generated next to: `orchestrate-import-bundle_20260423_113525.zip`*
