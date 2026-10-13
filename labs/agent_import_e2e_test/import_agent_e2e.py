# ---
# **Author:** Markus van Kempen | mvk@ca.ibm.com
# [Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)
# *No bug too small, no syntax too weird.*
# ---
import os
import json
import time
from pathlib import Path
from ibm_watsonx_orchestrate.client.toolkit.toolkit_client import ToolKitClient
from ibm_watsonx_orchestrate.client.agents.agent_client import AgentClient
from ibm_watsonx_orchestrate.client.utils import instantiate_client
from ibm_watsonx_orchestrate.agent_builder.toolkits.base_toolkit import BaseToolkit
from ibm_watsonx_orchestrate.agent_builder.toolkits.types import ToolkitKind, ToolkitPythonInputSpec
from ibm_watsonx_orchestrate.agent_builder.agents.agent import Agent
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from ibm_watsonx_orchestrate.cli.commands.toolkit.toolkit_controller import ToolkitController
from ibm_watsonx_orchestrate.agent_builder.toolkits.types import ToolkitKind

def run_e2e_import():
    print("🚀 Starting Agent Import E2E Test (ToolkitController)...")
    
    # Credentials from environment / .env
    base_url = os.getenv("WXO_BASE_URL", "https://api.dl.watson-orchestrate.ibm.com/instances/<your-instance-id>")
    api_key = os.getenv("WXO_API_KEY", "your_api_key_here")
    
    try:
        # Initialize controller
        # Note: We need to set the internal client to use our credentials
        from ibm_watsonx_orchestrate.client.toolkit.toolkit_client import ToolKitClient
        tk_client = ToolKitClient(base_url=base_url, api_key=api_key)
        
        controller = ToolkitController()
        controller.client = tk_client
        
        # 1. Import Toolkit
        print("📦 Importing Toolkit...")
        toolkit = controller.create_toolkit(
            kind=ToolkitKind.PYTHON,
            name="long_running_toolkitv3",
            description="Toolkit for long-running operations",
            package_root="input_blocking_test_agentv3/tools/long_running_toolv3"
        )
        controller.publish_or_update_toolkits([toolkit])
        
        # 2. Import Plugin
        print("🔌 Importing Plugin...")
        plugin = controller.create_toolkit(
            kind=ToolkitKind.PYTHON,
            name="blocking_pluginv3",
            description="Pre-invoke plugin for input blocking",
            package_root="input_blocking_test_agentv3/plugins/blocking_pluginv3"
        )
        controller.publish_or_update_toolkits([plugin])
        
        # 3. Import Agent
        print("🤖 Importing Agent...")
        agent_client = AgentClient(base_url=base_url, api_key=api_key)
        
        agent_manifest = "input_blocking_test_agentv3/agents/agent.agent.yaml"
        agent = Agent.from_spec(agent_manifest)
        
        payload = agent.model_dump(mode='json', exclude_none=True, by_alias=True)
        response = agent_client.create(payload)
        print(f"✅ Agent imported successfully! ID: {response.get('id')}")

    except Exception as e:
        print(f"❌ E2E Import failed: {e}")

if __name__ == "__main__":
    run_e2e_import()
