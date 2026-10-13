# Watsonx Orchestrate RBAC Pre-Invoke Plugin

Author: Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)  
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)  
No bug too small, no syntax too weird.
This directory contains a complete example of an **Agent Pre-Invoke Plugin** that implements Role-Based Access Control (RBAC) in Watsonx Orchestrate.

## Overview

The `RBAC_plugin.py` script acts as a gatekeeper for an agent. Before the agent processes any user message, the plugin inspects the incoming request context, particularly the user's email address (`plugin_context.state["context"]["wxo_email_id"]`). 

The script checks the user's email against a predefined `USER_ROLES` list.
- If the user is found and has an **"admin"** role, the plugin allows the message to proceed to the agent (`continue_processing = True`).
- If the user is unrecognised or lacks the appropriate role, the plugin intercepts the request, stops further processing (`continue_processing = False`), and returns a custom unauthorized message directly to the user.

## Files

- **`RBAC_plugin.py`**: The Python pre-invoke tool containing the RBAC logic.
- **`rbac_agent_def.yaml`**: The native Agent configuration file linking the `RBAC_plugin` as a pre-invoke action.
- **`deploy_and_test.sh`**: A shell script that automates importing the tool, creating the agent, deploying it, and opening a chat interface to test the flow end-to-end.

## How to Test

1. Navigate to this directory in your terminal:
   ```bash
   cd path/to/vsc/test_tools/rbac_plugin
   ```

2. Run the automated deployment and test script. This script will source the necessary credentials (assuming a `.env` exists in `../mcp_user_context_test/`), import the tool/agent, deploy the agent, and start an interactive CLI chat session.
   ```bash
   ./deploy_and_test.sh
   ```

3. In the chat interface, try typing any message (e.g., `hello`).
   - If your email (configured in your WxO connection context) is listed as **admin** in `USER_ROLES`, the agent will respond normally.
   - If not, you will receive the message: *"I'm sorry... You are not authorized to run this agent."*

You can manually edit the `USER_ROLES` list in `RBAC_plugin.py` to add your email address and test the success/failure paths.
