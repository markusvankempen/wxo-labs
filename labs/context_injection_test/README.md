# watsonx Orchestrate Context Injection Python Tool Workaround
by [Floor 7½ 🏢🤏 Department of Low Overhead](https://pages.github.ibm.com/mvankempen/homepage/)

"No bug too small, no syntax too weird."

---

## The Issue
When authoring Python tools natively in watsonx Orchestrate and enabling `context_access_enabled: true`, you must annotate one parameter with `AgentRun` from the `ibm_watsonx_orchestrate.run.context` library. 

However, users frequently encounter this error when the platform executes the tool in the cloud sandbox runtime:
```python
ModuleNotFoundError: No module named 'ibm_watsonx_orchestrate.run.context'
```

**Why this happens:**
During the *import/generation* phase locally via the CLI, the ADK completely relies on the `ibm_watsonx_orchestrate` package to generate the OpenAPI specs correctly. 
However, when the cloud sandbox *actually executes* your python file to process data, it dynamically injects a duck-typed context object payload without necessarily loading the full `run.context` library natively, causing the bare import statement to crash.

---

## Diagnosing Locally

You can verify that your local `ibm_watsonx_orchestrate` installation **does** include `run.context` by running:

```bash
python3 -c "from ibm_watsonx_orchestrate.run.context import AgentRun; print('run.context module exists, AgentRun:', AgentRun)"
```

If this succeeds locally (confirmed on version **2.5.0**), it confirms that the error is **cloud-side, not package-side**.

> **⚠️ FAQ: Will adding `ibm_watsonx_orchestrate` to my tool's `requirements.txt` fix this?**
>
> **No.** The cloud sandbox runtime does not load the `run.context` submodule regardless of package version. The sandbox dynamically injects a duck-typed context object at runtime instead of relying on the library. Adding the package to `requirements.txt` will not change this behavior — the `try/except` workaround below is the correct and only solution.

---

## The Solution (Code Snippet)
To fix this, simply wrap the `AgentRun` import in a `try/except ImportError` block and fall back to assigning it to the base Python `object`.

This bypasses the strict module import in the execution container, while still correctly satisfying the type-checker during CLI importation.

### `context_test_tool.py`

```python
"""
Python tool testing the AgentRun context variable injection workaround.
"""

try:
    from ibm_watsonx_orchestrate.run.context import AgentRun
except ImportError:
    # Fallback for cloud execution sandbox: prevents ModuleNotFoundError during runtime execution
    AgentRun = object  

from ibm_watsonx_orchestrate.agent_builder.tools import tool

@tool
def read_user_email(context: AgentRun) -> str:
    """Read the user's email from the default context variable wxo_email_id.
    
    Args:
        context (AgentRun): The agent run context object.
        
    Returns:
        str: A string stating the user's email retrieved from the context.
    """
    req_context = context.request_context
    email = req_context.get("wxo_email_id", "EMAIL_NOT_FOUND")
    return f"The user's email from context is: {email}"
```

---

## Testing it Locally

To prove that the workaround is valid, we've provided a shell script that provisions a test agent in your WxO tenant.

### 1. Run the setup script:
This script imports the Python tool above and creates an agent named `context_test_agent` properly configured with `--context-variable wxo_email_id` access rights.

```bash
chmod +x setup.sh
./setup.sh
```

### 2. Open chat:
Launch the chat interface for the new agent:
```bash
orchestrate chat ask -n context_test_agent
```

### 3. Verify:
Type `TEST` in the chat to tell the agent to invoke the `read_user_email` tool. 
The agent will successfully extract your email address from the context runtime without throwing the `ModuleNotFoundError`!

---

## See also

- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** – Real-world debug findings: `override: 1.12.0rc2505` in `~/.config/orchestrate/config.yaml` causing `AttributeError: 'dict' has no attribute 'request_context'`; requirements.txt dashes vs underscores; full checklist.
- **[context_update_test](../context_update_test/README.md)** – Update and read custom context keys (`user_favorite_color`, `user_current_status`) via `request_context`.
- **[context_ids_test](../context_ids_test/README.md)** – Debug tool that dumps the **full** `AgentRun` to see what WxO injects at runtime (e.g. thread_id, trace_id, session_id). Use when you need a unique conversation identifier for backend tracking; the README there summarizes the platform question and how to run the test.

Author: Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)  
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)  
No bug too small, no syntax too weird.
