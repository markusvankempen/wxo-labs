# ---
# **Author:** Markus van Kempen | mvk@ca.ibm.com
# [Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)
# *No bug too small, no syntax too weird.*
# ---
import requests
import os
from dotenv import load_dotenv

load_dotenv()

token_url = "https://iam.platform.saas.ibm.com/siusermgr/api/1.0/apikeys/token"
api_key = os.getenv("WXO_API_KEY", "your_api_key_here")

def get_token():
    print(f"🔑 Exchanging API Key for token at {token_url}...")
    headers = {
        "Authorization": f"Basic {api_key}",
        "Accept": "application/json"
    }
    response = requests.post(token_url, headers=headers)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        token_data = response.json()
        print("✅ Token received!")
        return token_data.get("accessToken")
    else:
        print(f"❌ Failed to get token: {response.text}")
        return None

if __name__ == "__main__":
    token = get_token()
    if token:
        print(f"Token (first 20 chars): {token[:20]}...")
