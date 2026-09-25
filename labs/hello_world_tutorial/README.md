# WXO Tutorial: Hello World (Python Tool)

**Author:** Markus van Kempen | mvk@ca.ibm.com  
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)  
*No bug too small, no syntax too weird.*

---

## 📖 Overview
This is an implementation of the [Official WXO Hello World Tutorial](https://developer.watson-orchestrate.ibm.com/tutorials/tutorial_1_hello_world). It demonstrates how to build and import a basic Python-based tool into Watsonx Orchestrate.

## 🛠️ Artifacts & Blog Post
*   **[ibm_community_post.html](./ibm_community_post.html)**: Clean, semantic HTML ready to copy & paste into IBM Community blog editor.
*   **[index.html](./index.html)**: Interactive, standalone blog presentation view.
*   **[IBM_COMMUNITY_BLOG_LAB1_BEGINNER.md](./IBM_COMMUNITY_BLOG_LAB1_BEGINNER.md)**: Full tutorial blog post in GitHub Markdown.
*   **[greetings.py](./greetings.py)**: The Python function that provides the greeting logic.
*   **[requirements.txt](./requirements.txt)**: Dependency list (MUST include `ibm-watsonx-orchestrate`).
*   **[hello_world_agent.yaml](./hello_world_agent.yaml)**: A native agent to test the tool.

## 💡 Troubleshooting: ModuleNotFoundError
If you see an error like `ModuleNotFoundError: No module named 'ibm_watsonx_orchestrate'`, it means the WXO runner environment cannot find the tool decorator library.

**Fix:**
1.  Ensure `ibm-watsonx-orchestrate` is listed in your `requirements.txt`.
2.  Explicitly include the requirements file during import:
    ```bash
    orchestrate tools import -k python -f greetings.py -r requirements.txt
    ```
    *Note: In some private cloud environments (like Azure AKS), the runner might not pre-cache the ADK library, making this step mandatory.*

## 🚀 Deployment Steps (Command Sequence)

Run these commands in order to deploy the tool and agent:

```bash
# 1. Import the Python tool
orchestrate tools import -k python -f greetings.py -r requirements.txt

# 2. Import the native agent
orchestrate agents import -f hello_world_agent.yaml

# 3. Test the agent via CLI
orchestrate chat ask -n hello_world_greeter "Say hello to Markus"
```

## 🧪 Execution Result

```text
[INFO] - Using agent: hello_world_greeter (ID: 00931c4a-2a6b-45a3-b401-a40ed1eb28b0)
╭────────────────────────────────────── 💬 Chat ──────────────────────────────────────╮
│ Chat Mode                                                                           │
│                                                                                     │
│ Type your messages and press Enter to send.                                         │
│ Commands: 'exit', 'quit', or 'q' to exit                                            │
╰─────────────────────────────────────────────────────────────────────────────────────╯
╭─ 👤 User ───────────────────────────────────────────────────────────────────────────╮
│                                                                                     │
│  Say hello to Markus                                                                │
│                                                                                     │
╰─────────────────────────────────────────────────────────────────────────────────────╯
╭─ 🤖 hello_world_greeter ────────────────────────────────────────────────────────────╮
│                                                                                     │
│  Here’s the greeting for Markus:                                                    │
│                                                                                     │
│  **Hello World, welcome to Watsonx Orchestrate!**                                   │
│                                                                                     │
╰─────────────────────────────────────────────────────────────────────────────────────╯
```
