# Resolving User Email in watsonx Orchestrate Slack Integration

A complete recipe and reference implementation for resolving a Slack user's **corporate email address** inside IBM watsonx Orchestrate.

---

## The Challenge

When integrating watsonx Orchestrate agents with Slack (`byo_slack`):

1. **Slack Privacy Restrictions**: Slack message events (`app_mention`, `message.im`, `message.channels`) **never send user emails**. Slack only provides the user's Slack User ID (e.g., `U0123456789`).
2. **Context Gap**: Unlike the WxO Web Chat (which automatically extracts `wxo_email_id` from the web SSO session), the native Slack channel integration does not automatically query the Slack Directory API to translate the Slack ID into an email address.

---

## Solution Architecture

```mermaid
sequenceDiagram
    autonumber
    actor User as 👤 Slack User (Alice)
    participant Slack as 💬 Slack Workspace
    participant WxO as 🤖 watsonx Orchestrate
    participant Tool as 🐍 get_slack_user_email
    participant SlackAPI as 🌐 Slack Web API (users.info)

    User->>Slack: "@SupportBot check my open tickets"
    Slack->>WxO: Inbound Event (user: "U0123456789", text: "check my tickets")
    WxO->>WxO: Agent LLM sees Slack User ID "U0123456789"
    WxO->>Tool: Call get_slack_user_email(slack_user_id="U0123456789")
    Tool->>SlackAPI: GET /api/users.info?user=U0123456789<br/>(Bearer xoxb-... with scope users:read.email)
    SlackAPI-->>Tool: Return profile: { email: "alice@company.com", real_name: "Alice Smith" }
    Tool-->>WxO: { user_id: "U0123456789", email: "alice@company.com" }
    WxO->>WxO: Agent queries backend services using alice@company.com
    WxO-->>Slack: "Alice, you have 1 open ticket (#1042)..."
    Slack-->>User: Display threaded response
```

---

## Step 1: Configure Slack App Permissions

In your Slack App configuration portal ([api.slack.com/apps](https://api.slack.com/apps)):

1. Open your Slack App.
2. In the left navigation, click **OAuth & Permissions**.
3. Scroll down to **Scopes** → **Bot Token Scopes** and add:
   * **`users:read.email`** *(Required to access profile email)*
   * **`users:read`** *(Required to query user directory)*
4. Scroll to the top and click **Reinstall to Workspace** to apply the updated scopes.
5. Copy your **Bot User OAuth Token** (`xoxb-...`).

---

## Step 2: Configure Credentials in watsonx Orchestrate

You can provide the Slack Bot Token to the tool in either of two ways:

### Option A: Via WxO Connection (Recommended for Cloud)
Create an application connection named `slack_bearer_token`:
```yaml
# connection_slack.yaml
name: slack_bearer_token
app_id: slack_bearer_token
security_scheme:
  type: bearer
  token: ${SLACK_BOT_TOKEN}
```

### Option B: Via Environment Variable
Set the environment variable in your execution environment:
```bash
export SLACK_BOT_TOKEN="xoxb-your-slack-bot-token"
```

---

## Step 3: Import the Python Tool into WxO

Use the WxO CLI to import the tool:

```bash
cd labs/slack_user_email_resolution

# Import the Python tool
orchestrate tools import \
  -k python \
  -f slack_user_tool.py \
  -r requirements.txt
```

Verify that the tool is registered:
```bash
orchestrate tools list | grep get_slack_user_email
```

---

## Step 4: Attach the Tool to Your Agent

Add `get_slack_user_email` to your agent YAML:

```yaml
name: slack_support_agent
description: Enterprise Support Agent integrated with Slack with automatic email resolution
model: watsonx/meta-llama/llama-3-2-90b-vision-instruct
style: react

tools:
  - get_slack_user_email

instructions: |
  You are an Enterprise Support Agent integrated with Slack.
  
  User Identity Handling:
  1. In Slack interactions, incoming messages will reference the user by their Slack User ID (e.g. U0123456789 or <@U0123456789>).
  2. Whenever an action requires the user's corporate email (such as ticket lookup, approvals, or notifications), call `get_slack_user_email` with the user's Slack ID.
  3. Once the email is retrieved, confirm actions with the user using their corporate email address.
  4. Do not prompt the user to type their email manually if you can look it up with `get_slack_user_email`.
```

Deploy the agent:
```bash
orchestrate agents import -f agent_example.yaml
```

---

## Step 5: Test the Tool Locally

You can test the tool directly from Python before deploying:

```bash
export SLACK_BOT_TOKEN="xoxb-your-token"
python3 -c '
from slack_user_tool import get_slack_user_email
print(get_slack_user_email("U0123456789"))
'
```

Expected output:
```json
{
  "user_id": "U0123456789",
  "email": "alice@company.com",
  "real_name": "Alice Smith",
  "display_name": "Alice",
  "is_bot": false
}
```

---

## Alternative: Webhook Middleware Interception

If you want `{wxo_email_id}` injected **before** the LLM runs (without requiring an LLM tool call), use a lightweight middleware proxy (like [wxo-slack-middleware](https://github.com/markusvankempen/slack-wxo-mcp-gateway)):

1. Inbound Slack event arrives at middleware webhook.
2. Middleware calls `slack_client.users_info(user=event["user"])` to fetch email.
3. Middleware invokes WxO Runs API (`POST /v1/orchestrate/runs`) passing:
   ```json
   {
     "message": {
       "role": "user",
       "content": event["text"],
       "context": {
         "wxo_email_id": "alice@company.com",
         "slack_user_id": "U0123456789"
       }
     }
   }
   ```
4. Agent natively receives `{wxo_email_id}` in its context without invoking any tools.
