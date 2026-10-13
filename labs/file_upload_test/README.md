# File Upload & Data Reader Pattern

**Author:** Markus van Kempen | [mvk@ca.ibm.com](mailto:mvk@ca.ibm.com) | [markus.van.kempen@gmail.com](mailto:markus.van.kempen@gmail.com)  
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)  
*No bug too small, no syntax too weird.*

---

## Overview
This directory demonstrates how to handle file uploads in Watsonx Orchestrate and process them using a Python tool. It specifically covers reading Excel (`.xlsx`) files using the `pandas` library.

## Logic Flow
1. **User Upload**: The user uploads an Excel file in the WXO Chat.
2. **Tool Invocation**: The agent identifies the uploaded file and passes its local path to the `vt_template_header_reader_tool`.
3. **Data Processing**: The Python tool uses `pandas.read_excel()` to load the data, process it, and return a summary string.

## Contents
- `file_tool.py`: The Python tool implementation using `pandas`.
- `sample.xlsx`: A sample Excel file for testing.
- `test_runner.py`: A local script to simulate tool execution with a file path.

## Local Test
You can test the tool logic locally before importing it into WXO:
```bash
python3 test_runner.py
```
*(Ensure `pandas` and `openpyxl` are installed)*
