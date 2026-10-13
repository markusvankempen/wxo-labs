**Author:** Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)
*No bug too small, no syntax too weird.*

---

# Agent Import E2E Test Automation

This directory contains an automated end-to-end workflow for registering Watsonx Orchestrate (WxO) agents along with their toolkits and plugins using the Orchestrate CLI.

## Overview

The workflow automates the following steps:
1. **Environment Activation**: Log in and activate a target WxO environment.
2. **Toolkit Registration**: Register Python-based toolkits containing custom tools.
3. **Plugin Registration**: Register pre-invoke/post-invoke plugins.
4. **Agent Import**: Import the agent manifest, correctly linking the previously registered toolkits and plugins.
5. **Verification**: Verify that the agent is correctly registered and its dependencies are linked.

## Setup & Prerequisites

- **Orchestrate ADK**: Ensure the `ibm-watsonx-orchestrate` package is installed.
- **API Key**: A valid WxO API key is required.
- **Environment URL**: The URL of your WxO instance.

## Usage

1. **Set Environment Variables**:
   Update your `.env` file with `WO_INSTANCE_URL` and `WO_API_KEY`.

2. **Activate Environment**:
   ```bash
   source .env
   orchestrate env activate NEW --api-key "$WO_API_KEY"
   ```

3. **Run E2E Import**:
   ```bash
   bash run_agent_import_e2e.sh
   ```

To ensure the CLI can correctly resolve dependencies during import, the following changes were made to the `agent.agent.yaml`:

### 1. Qualified Tool Names
Tools must be referenced using the `toolkit_name:tool_name` format if they are part of a registered toolkit.
```yaml
tools:
  - long_running_toolkitv3:long_running_toolv3
  - long_running_toolkitv3:check_tool_statusv3
  - long_running_toolkitv3:clear_tool_state
```

### 2. Plugin Structure
Plugins must use the `agent_pre_invoke` or `agent_post_invoke` field names and follow the `plugin_name` structure.
```yaml
plugins:
  agent_pre_invoke:
    - plugin_name: blocking_pluginv3:blocking_pluginv3
```

## E2E Script: `run_agent_import_e2e.sh`

The shell script automates the entire process. Here is a breakdown of the commands:

```bash
#!/bin/bash
set -e

# 1. Import Toolkit
# Uses --kind python and --package-root to autodiscover tools
orchestrate toolkits add --name long_running_toolkitv3 --kind python \
  --description "Toolkit for long-running operations" \
  --package-root input_blocking_test_agentv3/tools/long_running_toolv3

# 2. Import Plugin
# Plugins are also registered as toolkits of kind python
orchestrate toolkits add --name blocking_pluginv3 --kind python \
  --description "Pre-invoke plugin for input blocking" \
  --package-root input_blocking_test_agentv3/plugins/blocking_pluginv3

# 3. Import Agent
# Links to the registered toolkits and plugins via the manifest
orchestrate agents import -f input_blocking_test_agentv3/agents/agent.agent.yaml

# 4. Verification
# Checks the agent list in verbose mode to confirm presence
orchestrate agents list --verbose | grep -q "input_blocking_test_agentv3"
```

## Results & Output

Successful execution of the script produces the following output:

```text
🚀 Starting Agent Import E2E Test...
📦 Importing Toolkit...
[INFO] - Successfully updated toolkit long_running_toolkitv3

🔌 Importing Plugin...
[INFO] - Successfully updated toolkit blocking_pluginv3

🤖 Importing Agent...
[INFO] - Existing Agent 'input_blocking_test_agentv3' found. Updating...
[INFO] - Agent 'input_blocking_test_agentv3' updated successfully

🔍 Verifying Agent Status...
✅ Success! Agent and dependencies imported successfully.
```

## Verification via Export

To verify that all dependencies (toolkits and plugins) are correctly linked, you can perform a full export. This creates a `.zip` bundle containing the agent and all its associated resources.

```bash
orchestrate agents export -n "input_blocking_test_agentv3" -k native -o verification_export.zip
```

The output confirms the export of all linked toolkits:
```text
[INFO] - Exporting agent definition for 'input_blocking_test_agentv3'
[INFO] - Exporting toolkit 'long_running_toolkitv3' to 'export/tools/long_running_toolkitv3:long_running_toolv3'
[INFO] - Exporting toolkit 'blocking_pluginv3' to 'export/plugins/blocking_pluginv3:blocking_pluginv3'
[INFO] - Successfully wrote agents and tools to 'verification_export.zip'
```

## Bulk Importing via ZIP

The Orchestrate CLI supports importing entire agent environments from a single ZIP file. This is the recommended way to move agents between environments.

```bash
orchestrate agents import -f my_agent_bundle.zip
```

### Required ZIP Structure
For the CLI to successfully autodiscover and register all resources, the ZIP file should follow this structure:

```text
my_agent_bundle.zip/
├── agents/
│   ├── native/             # Native agent YAMLs
│   ├── external/           # External agent YAMLs
│   └── assistant/          # Assistant agent YAMLs
├── toolkits/               # Toolkit YAML/Python files
├── tools/                  # Directories for individual tools (Python/OpenAPI)
├── connections/            # Connection YAML/JSON files
├── knowledge-base/         # Knowledge base definitions
├── models/                 # Virtual model and policy definitions
└── requirements.txt        # Optional global requirements
```

### Automation Benefits
When importing from a ZIP, the CLI automatically:
- **Topologically sorts** resources to import dependencies (connections, toolkits) before agents.
- **Resolves collaborators** between agents included in the bundle.
- **Validates references** ensuring all tools and plugins mentioned in the agent manifests exist within the bundle or environment.

## Troubleshooting

- **Authentication Errors**: Ensure you have run `orchestrate env activate --api-key <KEY>` before running the script.
- **Tool Not Found**: Double-check that the toolkit name in the manifest matches the name used in `toolkits add`.
- **Plugin Not Linked**: Ensure you are using `agent_pre_invoke` and the `plugin_name` field in the manifest.
