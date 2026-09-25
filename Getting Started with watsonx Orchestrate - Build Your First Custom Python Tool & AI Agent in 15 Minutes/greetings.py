"""
Greetings tool for Watsonx Orchestrate Hello World Tutorial.

Author: Markus van Kempen | mvk@ca.ibm.com
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)
No bug too small, no syntax too weird.
"""
from ibm_watsonx_orchestrate.agent_builder.tools import tool

@tool
def greeting() -> str:
    """
    Greeting for everyone   
    """
    return "Hello World, welcome to Watsonx Orchestrate!"
