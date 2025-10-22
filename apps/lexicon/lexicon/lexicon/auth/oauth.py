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
    
    # Create or update Frappe user
    email = user_info.get('email')
    if email:
        user = None
        if not frappe.db.exists('User', email):
            # Create new user
            user = frappe.get_doc({
                'doctype': 'User',
                'email': email,
                'first_name': user_info.get('given_name', email.split('@')[0]),
                'last_name': user_info.get('family_name', ''),
                'enabled': 1,
                'user_type': 'System User',
                'send_welcome_email': 0
            })
            user.insert(ignore_permissions=True)
            
            # Assign essential roles for full access
            user.add_roles('System Manager', 'Desk User', 'All')
            frappe.db.commit()
        else:
            user = frappe.get_doc('User', email)
            # Ensure user has essential roles
            essential_roles = ['System Manager', 'Desk User', 'All']
            current_roles = [d.role for d in user.roles]
            missing_roles = [r for r in essential_roles if r not in current_roles]
            if missing_roles:
                for role in missing_roles:
                    user.add_roles(role)
                user.save(ignore_permissions=True)
                frappe.db.commit()
        
        # Login the user
        frappe.local.login_manager.login_as(email)
        frappe.local.response['type'] = 'redirect'
        frappe.local.response['location'] = '/app'
    else:
        frappe.throw(_("Email not found in Auth0 user info"))
