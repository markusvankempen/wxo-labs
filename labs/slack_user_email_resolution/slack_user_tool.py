"""
slack_user_tool.py
==================
WxO Python Tool: Resolves a Slack User ID (e.g. U0123456789) to the user's corporate email address.

Prerequisites:
  1. In your Slack App (api.slack.com/apps):
     - Go to OAuth & Permissions -> Bot Token Scopes
     - Add 'users:read.email' and 'users:read'
     - Reinstall app to workspace
  2. Configure Slack Bot Token in WxO:
     - As a WxO Connection: 'slack_bearer_token'
     - Or as environment variable: SLACK_BOT_TOKEN="xoxb-..."
"""

import json
import logging
import os
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Dict

from ibm_watsonx_orchestrate.agent_builder.tools import tool

try:
    from ibm_watsonx_orchestrate.run import connections
except ImportError:
    connections = None

log = logging.getLogger(__name__)

SLACK_API_BASE = "https://slack.com/api"
CONNECTION_APP_ID = "slack_bearer_token"


def _get_token() -> str:
    """Retrieve Slack Bot Token from WxO connection or environment."""
    if connections:
        try:
            creds = connections.bearer_token(CONNECTION_APP_ID)
            if creds and creds.token:
                return creds.token
        except Exception as e:
            log.warning("Could not load connection '%s': %s", CONNECTION_APP_ID, e)
    return os.environ.get("SLACK_BOT_TOKEN", "")


@tool(
    description=(
        "Resolve a Slack User ID to their corporate email address and user profile. "
        "Use this tool whenever an interaction originates from Slack and the agent "
        "needs the user's email address for authentication, ticket lookup, or notifications."
    )
)
def get_slack_user_email(slack_user_id: str) -> str:
    """
    Fetch the corporate email and profile for a given Slack User ID.

    Args:
        slack_user_id: The Slack user identifier, e.g., 'U0123456789' or mention '<@U0123456789>'.

    Returns:
        JSON string containing user_id, email, real_name, and display_name.
    """
    token = _get_token()
    if not token:
        return json.dumps({
            "error": "Slack Bot Token not configured. Set SLACK_BOT_TOKEN environment variable or add 'slack_bearer_token' connection in WxO."
        })

    # Clean Slack mention syntax like <@U012345678> -> U012345678
    clean_user_id = slack_user_id.strip("<@>").strip()
    if not clean_user_id:
        return json.dumps({"error": "slack_user_id cannot be empty"})

    url = f"{SLACK_API_BASE}/users.info?user={urllib.parse.quote(clean_user_id)}"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json; charset=utf-8",
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))

            if not data.get("ok"):
                return json.dumps({
                    "error": f"Slack API returned error: {data.get('error', 'unknown')}",
                    "hint": "Ensure your Slack Bot Token has the 'users:read.email' and 'users:read' OAuth scopes."
                })

            user = data.get("user", {})
            profile = user.get("profile", {})
            email = profile.get("email", "")

            if not email:
                return json.dumps({
                    "user_id": clean_user_id,
                    "email": None,
                    "real_name": profile.get("real_name", user.get("real_name", "")),
                    "warning": "User profile does not contain an email address, or Slack App lacks 'users:read.email' scope."
                })

            return json.dumps({
                "user_id": clean_user_id,
                "email": email,
                "real_name": profile.get("real_name", user.get("real_name", "")),
                "display_name": profile.get("display_name", ""),
                "is_bot": user.get("is_bot", False)
            })

    except urllib.error.HTTPError as exc:
        return json.dumps({"error": f"HTTP error {exc.code} calling Slack API: {exc.reason}"})
    except Exception as exc:
        return json.dumps({"error": f"Failed to contact Slack API: {str(exc)}"})
