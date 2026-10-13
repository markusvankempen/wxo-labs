# 🎯 SSO E2E Test - Ready to Run

## ✅ What's Been Set Up

Your SSO testing environment is now ready! Here's what has been configured:

### 📦 Components Created

1. **Mock Identity Service** ([`mock_identity_service.py`](mock_identity_service.py))
   - Flask-based service that receives SSO identity information
   - Logs all headers and authentication details
   - Runs on port 5000

2. **Setup Script** ([`setup_mock_service.sh`](setup_mock_service.sh))
   - Installs Python dependencies
   - Validates prerequisites
   - Provides step-by-step instructions

3. **Complete Test Runner** ([`run_complete_test.sh`](run_complete_test.sh))
   - Automated end-to-end test execution
   - Starts mock service + ngrok automatically
   - Deploys WxO components
   - Provides cleanup on exit

4. **WxO Connection Tester** ([`run_sso_with_wxo_connection.sh`](run_sso_with_wxo_connection.sh))
   - Tests SSO with existing WatsonX connections (Box, Salesforce, etc.)
   - Discovers available connections and tools
   - Creates test agent dynamically
   - Verifies identity propagation through real connections

5. **Quick Start Guide** ([`QUICKSTART.md`](QUICKSTART.md))
   - Comprehensive documentation
   - Troubleshooting tips
   - Architecture diagrams

---

## 🚀 How to Run the Test

### Option 1: Test with Existing WatsonX Connection (Recommended)

Test SSO identity propagation through an existing WxO connection like Box, Salesforce, ServiceNow, etc.:

```bash
cd sso_entra_id_test
./run_sso_with_wxo_connection.sh
```

This will:
- ✅ List all available connections in your WxO instance
- ✅ Let you select which connection to test
- ✅ Create a test agent that uses tools from that connection
- ✅ Verify SSO identity propagation through the connection

**Benefits:**
- Tests with real WxO connections (no mock service needed)
- Verifies actual identity propagation to third-party services
- Works with Box, Salesforce, ServiceNow, and other SSO-enabled connections

### Option 2: Fully Automated with Mock Service

```bash
cd sso_entra_id_test
./run_complete_test.sh
```

This will:
- ✅ Start the mock service
- ✅ Start ngrok tunnel
- ✅ Deploy WxO components (connection, tool, agent)
- ✅ Run verification test
- ✅ Clean up on exit

### Option 3: Manual Step-by-Step with Mock Service

**Terminal 1 - Mock Service:**
```bash
cd sso_entra_id_test
python3 mock_identity_service.py
```

**Terminal 2 - ngrok:**
```bash
ngrok http 5000
```

**Terminal 3 - Deploy & Test:**
```bash
cd sso_entra_id_test
./run_sso_e2e_test.sh https://YOUR-NGROK-URL.ngrok-free.app
```

---

## 📋 Your WxO SAML Configuration

Based on your current environment:

| Parameter | Value |
|-----------|-------|
| **Instance URL** | `https://api.dl.watson-orchestrate.ibm.com/instances/<your-instance-id>` |
| **Entity ID** | `https://api.dl.watson-orchestrate.ibm.com/instances/<your-instance-id>/saml/metadata` |
| **ACS URL** | `https://api.dl.watson-orchestrate.ibm.com/instances/<your-instance-id>/saml/acs` |

Use these values when configuring Microsoft Entra ID.

---

## 🔧 Microsoft Entra ID Configuration

Before running the test, configure Entra ID:

1. **Go to**: [Microsoft Entra Admin Center](https://entra.microsoft.com)
2. **Navigate**: Enterprise Applications → New Application → Create your own
3. **Select**: Non-gallery application
4. **Configure SAML**:
   - Identifier (Entity ID): Use value from table above
   - Reply URL (ACS URL): Use value from table above
5. **Download**: Federation Metadata XML
6. **Configure WxO Connection**:
   ```bash
   orchestrate connections configure \
     -a entra-id-sso-app \
     -k oauth_auth_code_flow \
     --sso True \
     -e metadata_url=YOUR_ENTRA_METADATA_XML_URL
   ```

---

## 🧪 What the Test Does

### Deployment Phase
1. Creates SSO connection bridge: `entra-id-sso-app`
2. Imports OpenAPI tool with SAML authentication
3. Deploys SSO Verifier Agent
4. Waits for platform sync (15 seconds)

### Verification Phase
1. Initiates chat with agent: "Who am I?"
2. Agent calls Identity Probe tool
3. Tool triggers SSO authentication flow
4. Checks for login prompt or active session

### Expected Outcomes
- ✅ **SSO Login Prompt**: SAML flow triggered correctly
- ✅ **Active Session**: User already authenticated
- ❌ **Timeout**: SSO not configured or connection issue

---

## 📊 Test Results Interpretation

### Success Indicators
```
[TEST] SSO LOGIN PROMPT DETECTED! ✅
```
or
```
[TEST] ACTIVE SESSION DETECTED! ✅
```

### What This Means
- Connection bridge is working
- Tool is correctly bound to SSO
- SAML flow is initiated
- Identity propagation path is established

### Next Steps After Success
1. Complete Entra ID metadata configuration
2. Test with actual user login
3. Verify identity headers in mock service logs
4. Check that username/roles are propagated correctly

---

## 🔍 Debugging

### Check Mock Service Logs
```bash
tail -f sso_entra_id_test/mock_service.log
```

### Check ngrok Traffic
Open: http://localhost:4040

### Verify WxO Components
```bash
orchestrate connections list
orchestrate tools list | grep "Entra ID"
orchestrate agents list | grep "sso_identity"
```

### Manual Chat Test
```bash
orchestrate chat ask -n sso_identity_verifier_agent "Who am I?"
```

---

## 📁 File Structure

```
sso_entra_id_test/
├── README.md                    # Detailed architecture & guide
├── QUICKSTART.md               # Quick start instructions
├── TEST_SUMMARY.md             # This file
├── find_saml_endpoints.py      # Discover SAML endpoints
├── run_sso_e2e_test.sh         # Main E2E test script
├── run_complete_test.sh        # Automated test runner (NEW)
├── setup_mock_service.sh       # Setup script (NEW)
├── mock_identity_service.py    # Mock service (NEW)
├── requirements.txt            # Python dependencies (NEW)
├── sso_identity_probe.yaml     # OpenAPI tool spec
└── sso_verifier_agent.yaml     # Agent manifest
```

---

## 💡 Tips

- **Keep mock service running** during tests to see real-time identity data
- **Check ngrok admin UI** (http://localhost:4040) to inspect HTTP traffic
- **Use verbose mode** in orchestrate CLI for detailed debugging
- **Save ngrok URL** if you need to rerun tests without restarting ngrok

---

## 🆘 Common Issues

### Issue: "ngrok not found"
**Solution**: Install ngrok
```bash
brew install ngrok  # macOS
# or download from https://ngrok.com/download
```

### Issue: "Flask not installed"
**Solution**: Install dependencies
```bash
pip3 install -r requirements.txt
```

### Issue: "Connection refused"
**Solution**: Ensure mock service is running
```bash
python3 mock_identity_service.py
```

### Issue: "No SSO prompt"
**Solution**: Configure Entra ID metadata first (see configuration section above)

---

## 📞 Support

**Author:** Markus van Kempen | mvk@ca.ibm.com  
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)  
*No bug too small, no syntax too weird.*

For detailed architecture and flow diagrams, see [`README.md`](README.md)