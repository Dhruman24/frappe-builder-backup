# Auth0 Setup Guide - Quick Reference

## What You Get

Two separate Auth0 logins on the main login page:
- 🏢 **Vendor Manager** - Manage vendors and waitlists (`vendor-{email}` users)
- 📚 **Lexicon** - Vendor directory display (`lexicon-{email}` users)

Same Auth0 account = 2 separate Frappe users with full admin access

---

## Step 1: Configure Auth0 Credentials

Already done! Your credentials are in `config/auth0_credentials.json`:
- Auth0 Domain: `dev-wzk02vz8kiqth37j.us.auth0.com`
- Lexicon Client ID: `FZ91BA10wLaWskSsmBylYOSmBgnHHOsx`
- Vendor Manager Client ID: `RqpVD4Gb406cLbycNfVyK6yvf5jTiZoC`

---

## Step 2: Update Auth0 Callback URLs

**Lexicon Application:**
1. Go to: https://manage.auth0.com/dashboard/us/dev-wzk02vz8kiqth37j/applications
2. Click "Lexicon"
3. Set **Allowed Callback URLs**:
   ```
   http://builder.localhost:8000/api/method/lexicon.lexicon.auth.oauth.lexicon_callback
   ```
4. Save

**Vendor Manager Application (CRM Login):**
1. Click "CRM Login"
2. Set **Allowed Callback URLs**:
   ```
   http://builder.localhost:8000/api/method/vendor_manager.auth.oauth.vendor_manager_callback
   ```
3. Save

---

## Step 3: Apply Configuration

Run the configure script:
```bash
scripts\configure_auth0.bat
```

Or manually update `site_config.json` with Auth0 credentials.

---

## Step 4: Test Login

1. Go to: `http://builder.localhost:8000/login`
2. You'll see two Auth0 buttons
3. Click **"Login to Vendor Manager"** → Creates `vendor-{email}` → Full admin
4. Click **"Login to Lexicon"** → Creates `lexicon-{email}` → Full admin

---

## User Separation

| Button | User Created | Redirects To | Access |
|--------|-------------|--------------|--------|
| Vendor Manager | `vendor-john@example.com` | `/app/vendor` | Vendors, Waitlist |
| Lexicon | `lexicon-john@example.com` | `/app/vendors` | Vendor directory |

✅ **No credential sharing** - Each button creates a separate user
✅ **Both have System Manager role** - Full admin access
✅ **Same Auth0 account** - Convenience of single login

---

## Files Changed

**Login Page:** `apps/lexicon/lexicon/templates/pages/login.html`
**Lexicon OAuth:** `apps/lexicon/lexicon/lexicon/auth/oauth.py`
**Vendor Manager OAuth:** `apps/vendor-manager/vendor_manager/auth/oauth.py`
**Site Config:** Add Auth0 credentials to `sites/builder.localhost/site_config.json`

---

## ❌ DO NOT Use Social Login Keys

You do NOT need to configure "Social Login Keys" in Frappe admin. Our custom Auth0 integration bypasses that entirely.

---

## Production Setup

For production (e.g., `myapp.com`):
1. Update Auth0 callback URLs to use your domain
2. No code changes needed - OAuth auto-detects the domain
3. Enable HTTPS - Never use Auth0 over HTTP in production
