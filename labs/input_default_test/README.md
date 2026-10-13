# Tool Input Defaults Pattern

**Author:** Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)  
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)  
*No bug too small, no syntax too weird.*

---

## Overview
This directory demonstrates how to set and manage **default values** for tool input fields in Watsonx Orchestrate using Pydantic models.

## Key Concepts
- **Pydantic Defaults**: Using `Field(default=...)` in the input schema to provide initial values shown in the UI.
- **Dynamic Context Initial Values**: Logic to override the static Pydantic default by fetching values from the `AgentRun` context (e.g., predicted amounts from a previous flow step).

## Contents
- `financial_tool.py`: Python tool demonstrating both static and dynamic default value handling.
- `setup.sh`: Script to import the tool and create a test agent.

## Usage
Import the tool and observe how the input field for `inferred_financial_amount` prepopulates in the WXO Chat UI.
