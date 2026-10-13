# ---
# **Author:** Markus van Kempen | mvk@ca.ibm.com
# [Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)
# *No bug too small, no syntax too weird.*
# ---
import requests
import os
from dotenv import load_dotenv

load_dotenv()

base_url = os.getenv("WXO_BASE_URL", "https://api.dl.watson-orchestrate.ibm.com/instances/<your-instance-id>")
api_key = os.getenv("WXO_API_KEY", "your_api_key_here")

def check_auth():
    print(f"🔍 Checking auth for {base_url}...")
    headers = {
        "Authorization": f"Basic {api_key}",
        "Content-Type": "application/json"
    }
    # Try to list toolkits
    url = f"{base_url}/toolkits"
    response = requests.get(url, headers=headers)
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")

if __name__ == "__main__":
    check_auth()
