# 🔐 Microsoft Entra ID SAML Configuration Guide

Complete guide for configuring Microsoft Entra ID (formerly Azure AD) with WatsonX Orchestrate SSO.

---

## 📚 Official Documentation

### WatsonX Orchestrate SSO Documentation
- **Main SSO Guide**: [Configuring single sign-on](https://www.ibm.com/docs/en/watsonx/watson-orchestrate/current?topic=security-configuring-single-sign)
- **SAML Configuration**: [SAML 2.0 authentication](https://www.ibm.com/docs/en/watsonx/watson-orchestrate/current?topic=sign-saml-20-authentication)
- **Connection Authentication**: [Authenticating connections](https://www.ibm.com/docs/en/watsonx/watson-orchestrate/current?topic=connections-authenticating)

### Microsoft Entra ID Documentation
- **Enterprise Applications**: [Add an enterprise application](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal)
- **SAML SSO Setup**: [Configure SAML-based single sign-on](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso)

---

## 🎯 Step 1: Get Your WatsonX SAML Endpoints

### Option A: Use the Discovery Script (Recommended)

```bash
cd sso_entra_id_test
python3 find_saml_endpoints.py
```

**Output:**
```
📢 Watsonx Orchestrate SAML Endpoints for:
🔗 Base Instance: https://api.dl.watson-orchestrate.ibm.com/instances/YOUR-INSTANCE-ID

🔹 Identifier (Entity ID):
   https://api.dl.watson-orchestrate.ibm.com/instances/YOUR-INSTANCE-ID/saml/metadata

🔹 Reply URL (ACS URL):
   https://api.dl.watson-orchestrate.ibm.com/instances/YOUR-INSTANCE-ID/saml/acs

🔹 Sign-on URL:
   https://api.dl.watson-orchestrate.ibm.com/instances/YOUR-INSTANCE-ID/
```

### Option B: Manual Construction

If you know your WatsonX instance URL, construct the endpoints manually:

**Base Instance URL Format:**
```
https://api.{region}.watson-orchestrate.ibm.com/instances/{instance-id}
```

**Entity ID (Metadata URL):**
```
{BASE_INSTANCE_URL}/saml/metadata
```

**ACS URL (Assertion Consumer Service):**
```
{BASE_INSTANCE_URL}/saml/acs
```

**Sign-on URL:**
```
{BASE_INSTANCE_URL}/
```

### Example for Different Regions

| Region | Base URL Pattern |
|--------|------------------|
| **Dallas (US South)** | `https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/{id}` |
| **Frankfurt (EU Central)** | `https://api.eu-de.watson-orchestrate.cloud.ibm.com/instances/{id}` |
| **London (EU GB)** | `https://api.eu-gb.watson-orchestrate.cloud.ibm.com/instances/{id}` |
| **Sydney (AU)** | `https://api.au-syd.watson-orchestrate.cloud.ibm.com/instances/{id}` |
| **Development/Trial** | `https://api.dl.watson-orchestrate.ibm.com/instances/{id}` |

---

## 🔧 Step 2: Configure Microsoft Entra ID

### 2.1 Access Entra Admin Center

1. Go to [Microsoft Entra Admin Center](https://entra.microsoft.com)
2. Sign in with your admin credentials
3. Navigate to **Identity** → **Applications** → **Enterprise applications**

### 2.2 Create New Application

1. Click **+ New application**
2. Click **+ Create your own application**
3. Enter application name: `WatsonX Orchestrate SSO`
4. Select: **Integrate any other application you don't find in the gallery (Non-gallery)**
5. Click **Create**

### 2.3 Configure SAML Single Sign-On

1. In your new application, go to **Single sign-on** in the left menu
2. Select **SAML** as the single sign-on method
3. Click **Edit** on **Basic SAML Configuration**

### 2.4 Enter SAML Configuration

**Required Fields:**

| Field | Value | Example |
|-------|-------|---------|
| **Identifier (Entity ID)** | `{BASE_URL}/saml/metadata` | `https://api.dl.watson-orchestrate.ibm.com/instances/<your-instance-id>/saml/metadata` |
| **Reply URL (ACS URL)** | `{BASE_URL}/saml/acs` | `https://api.dl.watson-orchestrate.ibm.com/instances/<your-instance-id>/saml/acs` |
| **Sign on URL** (Optional) | `{BASE_URL}/` | `https://api.dl.watson-orchestrate.ibm.com/instances/<your-instance-id>/` |

**Important Notes:**
- ✅ Use the exact URLs from the discovery script
- ✅ URLs are case-sensitive
- ✅ Include the `/saml/metadata` and `/saml/acs` paths exactly as shown
- ❌ Do not add trailing slashes to metadata or acs URLs

### 2.5 Configure Attributes & Claims

**Default Claims (Usually Sufficient):**
- `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress` → `user.mail`
- `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname` → `user.givenname`
- `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname` → `user.surname`
- `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name` → `user.userprincipalname`

**Optional: Add Custom Claims**
If you need to pass additional user attributes:
1. Click **+ Add new claim**
2. Configure claim name and source attribute
3. Save

### 2.6 Download Federation Metadata

1. Scroll to **SAML Certificates** section
2. Find **Federation Metadata XML**
3. Click **Download** to save the XML file

**Alternative: Copy Metadata URL**
- Instead of downloading, you can copy the **App Federation Metadata Url**
- This URL can be used directly in WatsonX configuration

---

## 🔗 Step 3: Configure WatsonX Connection

### 3.1 Using Metadata URL (Recommended)

```bash
orchestrate connections configure \
  -a YOUR_CONNECTION_ID \
  -k oauth_auth_code_flow \
  --sso True \
  -e metadata_url=https://login.microsoftonline.com/YOUR-TENANT-ID/federationmetadata/2007-06/federationmetadata.xml
```

### 3.2 Using Downloaded Metadata File

If you downloaded the XML file:

```bash
# First, upload the file to a accessible location or use the file path
orchestrate connections configure \
  -a YOUR_CONNECTION_ID \
  -k oauth_auth_code_flow \
  --sso True \
  -e metadata_file=/path/to/federationmetadata.xml
```

### 3.3 Verify Configuration

```bash
# Check connection status
orchestrate connections list

# Look for your connection with SSO enabled
# Should show ✅ in credentials column
```

---

## 👥 Step 4: Assign Users

### 4.1 Assign Users to Application

1. In Entra Admin Center, go to your application
2. Navigate to **Users and groups**
3. Click **+ Add user/group**
4. Select users or groups who should have access
5. Click **Assign**

### 4.2 Test User Assignment

```bash
# Test with an assigned user
orchestrate chat ask -n YOUR_AGENT_NAME "Who am I?"
```

---

## 🧪 Step 5: Test SSO Integration

### Option 1: Test with Existing Connection

```bash
cd sso_entra_id_test
./run_sso_with_wxo_connection.sh
```

Select a connection (e.g., `box_ibm_184bdbd3`) and follow the prompts.

### Option 2: Test with Mock Service

```bash
cd sso_entra_id_test
./run_complete_test.sh
```

This will set up a mock service and test the complete SSO flow.

### Option 3: Manual Test

```bash
# Test with any agent that uses an SSO-enabled connection
orchestrate chat ask -n YOUR_AGENT_NAME "Test SSO"
```

---

## ✅ Verification Checklist

- [ ] Entity ID and ACS URL obtained from WatsonX
- [ ] Entra ID application created
- [ ] SAML configuration completed in Entra ID
- [ ] Federation Metadata XML downloaded or URL copied
- [ ] WatsonX connection configured with metadata
- [ ] Users assigned to Entra ID application
- [ ] SSO test completed successfully

---

## 🔍 Troubleshooting

### Issue: "Invalid Entity ID"

**Cause**: Entity ID doesn't match WatsonX instance

**Solution**:
```bash
# Re-run discovery script to get correct Entity ID
python3 find_saml_endpoints.py

# Verify it matches your .env file
grep WO_NEW_INSTANCE_URL ../../.env
```

### Issue: "ACS URL not found"

**Cause**: ACS URL is incorrect or missing `/saml/acs` path

**Solution**:
- Ensure ACS URL ends with `/saml/acs`
- Do not add trailing slash after `acs`
- Verify URL matches your instance exactly

### Issue: "Metadata URL not accessible"

**Cause**: Entra ID metadata URL is not public or incorrect

**Solution**:
```bash
# Test metadata URL accessibility
curl -I "YOUR_METADATA_URL"

# Should return 200 OK
# If not, download XML file and use file path instead
```

### Issue: "SSO login loop"

**Cause**: User not assigned to Entra ID application

**Solution**:
1. Go to Entra Admin Center
2. Navigate to your application → Users and groups
3. Add the user
4. Try again

### Issue: "SAML assertion invalid"

**Cause**: Clock skew or certificate issues

**Solution**:
1. Check system time on both sides
2. Verify SAML certificate is valid
3. Re-download metadata XML
4. Reconfigure WatsonX connection

---

## 📊 Common Scenarios

### Scenario 1: Multiple WatsonX Instances

If you have multiple WatsonX instances:

1. Create separate Entra ID applications for each instance
2. Use different Entity IDs for each (one per instance)
3. Name applications clearly: `WatsonX Prod`, `WatsonX Dev`, etc.

### Scenario 2: Different Regions

Entity ID format varies by region:

```bash
# US South
https://api.us-south.watson-orchestrate.cloud.ibm.com/instances/{id}/saml/metadata

# EU Frankfurt
https://api.eu-de.watson-orchestrate.cloud.ibm.com/instances/{id}/saml/metadata

# Development
https://api.dl.watson-orchestrate.ibm.com/instances/{id}/saml/metadata
```

### Scenario 3: Custom Domain

If using a custom domain, Entity ID might be:
```
https://your-custom-domain.com/instances/{id}/saml/metadata
```

---

## 🔐 Security Best Practices

1. **Use HTTPS Only**: Ensure all URLs use HTTPS
2. **Rotate Certificates**: Update SAML certificates before expiry
3. **Limit User Access**: Only assign necessary users to the application
4. **Monitor Access**: Review Entra ID sign-in logs regularly
5. **Test Regularly**: Run SSO tests after any configuration changes

---

## 📞 Support Resources

### WatsonX Support
- **Documentation**: https://www.ibm.com/docs/en/watsonx/watson-orchestrate
- **Community**: https://community.ibm.com/community/user/watsonai/communities/community-home?CommunityKey=7a3dc5ba-3018-452d-9a43-a49dc6819633

### Microsoft Entra ID Support
- **Documentation**: https://learn.microsoft.com/en-us/entra/
- **Support**: https://learn.microsoft.com/en-us/entra/fundamentals/how-to-get-support

### Script Author
**Markus van Kempen** | mvk@ca.ibm.com  
[Research | Floor 7½ 🏢🤏](https://pages.github.ibm.com/mvankempen/homepage/)

---

## 📝 Quick Reference Card

```
┌─────────────────────────────────────────────────────────────┐
│ WatsonX SAML Endpoints Quick Reference                      │
├─────────────────────────────────────────────────────────────┤
│ Entity ID:                                                   │
│ {BASE_URL}/saml/metadata                                     │
│                                                              │
│ ACS URL:                                                     │
│ {BASE_URL}/saml/acs                                          │
│                                                              │
│ Sign-on URL:                                                 │
│ {BASE_URL}/                                                  │
│                                                              │
│ Discovery Command:                                           │
│ python3 find_saml_endpoints.py                               │
│                                                              │
│ Configuration Command:                                       │
│ orchestrate connections configure \                          │
│   -a CONNECTION_ID \                                         │
│   -k oauth_auth_code_flow \                                  │
│   --sso True \                                               │
│   -e metadata_url=ENTRA_METADATA_URL                         │
└─────────────────────────────────────────────────────────────┘