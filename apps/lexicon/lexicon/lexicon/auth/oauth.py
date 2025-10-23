import frappe
import requests
from frappe import _
from urllib.parse import urlencode
import json

@frappe.whitelist(allow_guest=True)
def auth0_login():
    """Initiate Auth0 login flow for Lexicon"""
    auth0_domain = frappe.conf.get('auth0_domain')
    client_id = frappe.conf.get('auth0_lexicon_client_id')
    redirect_uri = f"{frappe.utils.get_url()}/api/method/lexicon.lexicon.auth.oauth.lexicon_callback"
    
    params = {
        'response_type': 'code',
        'client_id': client_id,
        'redirect_uri': redirect_uri,
        'scope': 'openid profile email',
        'state': frappe.generate_hash(length=20)
    }
    
    auth_url = f"https://{auth0_domain}/authorize?{urlencode(params)}"
    frappe.local.response['type'] = 'redirect'
    frappe.local.response['location'] = auth_url

@frappe.whitelist(allow_guest=True)
def lexicon_callback(code=None, state=None, error=None):
    """Handle Auth0 callback for Lexicon"""
    if error:
        frappe.throw(_(f"Auth0 Error: {error}"))
    
    if not code:
        frappe.throw(_("Authorization code not received"))
    
    auth0_domain = frappe.conf.get('auth0_domain')
    client_id = frappe.conf.get('auth0_lexicon_client_id')
    client_secret = frappe.conf.get('auth0_lexicon_client_secret')
    redirect_uri = f"{frappe.utils.get_url()}/api/method/lexicon.lexicon.auth.oauth.lexicon_callback"
    
    # Exchange code for token
    token_url = f"https://{auth0_domain}/oauth/token"
    token_data = {
        'grant_type': 'authorization_code',
        'client_id': client_id,
        'client_secret': client_secret,
        'code': code,
        'redirect_uri': redirect_uri
    }
    
    response = requests.post(token_url, json=token_data)
    tokens = response.json()
    
    if 'access_token' not in tokens:
        frappe.throw(_("Failed to get access token"))
    
    # Get user info
    userinfo_url = f"https://{auth0_domain}/userinfo"
    headers = {'Authorization': f"Bearer {tokens['access_token']}"}
    user_response = requests.get(userinfo_url, headers=headers)
    user_info = user_response.json()
    
    # Create or update Frappe user (NO prefix - use actual email)
    auth0_email = user_info.get('email')
    if auth0_email:
        user = None
        if not frappe.db.exists('User', auth0_email):
            # Create new user without any roles (Admin assigns roles via GUI)
            user = frappe.get_doc({
                'doctype': 'User',
                'email': auth0_email,
                'first_name': user_info.get('given_name', auth0_email.split('@')[0]),
                'last_name': user_info.get('family_name', ''),
                'enabled': 1,
                'user_type': 'System User',
                'send_welcome_email': 0,
                'bio': f"User authenticated via Auth0"
            })
            user.insert(ignore_permissions=True)

            # Only add basic Desk User role - Admin assigns specific app roles via GUI
            user.add_roles('Desk User')
            frappe.db.commit()

            frappe.logger().info(f"Created new user: {auth0_email} via Auth0. Admin needs to assign roles.")
        else:
            user = frappe.get_doc('User', auth0_email)

        # Login the user - they'll see only apps they have permission for
        frappe.local.login_manager.login_as(auth0_email)
        frappe.local.response['type'] = 'redirect'
        frappe.local.response['location'] = '/app'  # Redirect to Frappe home
    else:
        frappe.throw(_("Email not found in Auth0 user info"))
