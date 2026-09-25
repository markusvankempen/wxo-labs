# Processing User Files & Spreadsheets in watsonx Orchestrate: Building an Automated Data Analyst Agent

![WXO Labs Banner](https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_blog_banner.jpg)

<img src="https://raw.githubusercontent.com/markusvankempen/wxo-labs/main/docs/blog/getting-started-watsonx-orchestrate/wxo_labs_icon.jpg" width="48" height="48" style="border-radius:10px; vertical-align:middle; margin-right:8px;" /> **By Markus van Kempen** | *Series: WXO Labs & Tutorial Guide (Part 3 of 15)*  
- **Community Group:** [watsonx Orchestrate - IBM Community](https://community.ibm.com/community/user/groups/community-home/recent-community-blogs?communitykey=3ad46381-9535-462e-85c9-568b21f4b067)  
- **Interactive Lab Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)  
- **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)  

---

## Why This Pattern Matters

Managers often receive spreadsheet rosters or sales dumps and need instant summaries without opening Excel. In this lab, we build an agent capable of ingesting uploaded Excel (.xlsx) workbooks directly from the chat interface, running automated Pandas analytics, and returning instant KPI summaries.

---

## 📋 Prerequisites & Setup

Ensure the Orchestrate CLI is installed:

```bash
pip install ibm-watsonx-orchestrate
orchestrate env list
```

---

## 🛠️ Step 1: Implement the Logic (`file_processor.py`)

```python
from ibm_watsonx_orchestrate import tool
import pandas as pd
import os

@tool
def analyze_employee_data(file_path: str) -> str:
    """
    Analyze employee data from an uploaded Excel spreadsheet.

    Args:
        file_path: Absolute filesystem path to the uploaded Excel file.

    Returns:
        Structured summary statistics and department breakdown.
    """
    try:
        if not os.path.exists(file_path):
            return f"❌ File not found at path: {file_path}"

        df = pd.read_excel(file_path)
        total_records = len(df)
        columns = ", ".join(df.columns.tolist())
        
        dept_counts = df['Department'].value_counts().to_dict() if 'Department' in df.columns else {}
        avg_salary = f"${df['Salary'].mean():,.2f}" if 'Salary' in df.columns else "N/A"

        return f"""
📊 Spreadsheet Analytics Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Headcount:    {total_records}
Detected Columns:   {columns}
Average Base Pay:   {avg_salary}

Department Breakdown:
{chr(10).join([f"  • {dept}: {count}" for dept, count in dept_counts.items()])}
"""
    except Exception as e:
        return f"❌ Error processing Excel file: {str(e)}"
```

---

## 📦 Step 2: Declare Dependencies (`requirements.txt`)

```text
ibm-watsonx-orchestrate>=2.9.0
pandas>=2.0.0
openpyxl>=3.1.0
```

---

## 🤖 Step 3: Configure the AI Agent (`agent.yaml`)

```yaml
spec_version: v1
kind: native
name: hr_data_analyst
title: "HR Data Analyst"
description: "Ingests user-uploaded spreadsheets to extract headcount and department statistics."
model: ibm/granite-3-8b-instruct
instructions: |
  You are an HR analytics assistant. When a user uploads or references an Excel file,
  call `analyze_employee_data` passing the file path, and summarize the key findings.
tools:
  - analyze_employee_data
```

---

## 🚀 Step 4: Import & Test Live in Terminal

```bash
orchestrate chat ask -n hr_data_analyst "Analyze this spreadsheet: /tmp/sample_employees.xlsx"
```

**Live Response:**

```text
╭─ 🤖 hr_data_analyst ───────────────────────────────────────────────────╮
│                                                                        │
│  📊 Spreadsheet Analytics Summary                                      │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━                                     │
│  Total Headcount:    3                                                 │
│  Detected Columns:   Employee_ID, Name, Department, Salary             │
│  Average Base Pay:   $78,333.33                                        │
│                                                                        │
│  Department Breakdown:                                                 │
│    • Engineering: 1                                                    │
│    • Sales: 1                                                          │
│    • HR: 1                                                             │
╰────────────────────────────────────────────────────────────────────────╯
```

---

## 💡 Pro Tips & Gotchas

- **File Path Hand-off:** In watsonx Orchestrate WebChat, uploaded files are staged in the execution container. Always pass the exact file_path string supplied by the runtime.
- **Excel Engine:** Ensure `openpyxl` is specified in `requirements.txt` whenever reading `.xlsx` files with pandas.


---

## 🗺️ Series Roadmap (15 Hands-On Labs)

Explore all 15 parts of the hands-on journey:
- 🌐 **Interactive Portal:** [markusvankempen.github.io/wxo-labs/](https://markusvankempen.github.io/wxo-labs/)
- 📦 **GitHub Repository:** [github.com/markusvankempen/wxo-labs](https://github.com/markusvankempen/wxo-labs)
- 🏢 **Author Research:** [markusvankempen.github.io/](https://markusvankempen.github.io/)
