import frappe
import requests
from frappe import _
from urllib.parse import urlencode
import json

@frappe.whitelist(allow_guest=True)
def auth0_login():
    """Initiate Auth0 login flow for Vendor Manager"""
    auth0_domain = frappe.conf.get('auth0_domain')
    client_id = frappe.conf.get('auth0_vendor_manager_client_id')
    redirect_uri = f"{frappe.utils.get_url()}/api/method/vendor_manager.auth.oauth.vendor_manager_callback"

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
def vendor_manager_callback(code=None, state=None, error=None):
    """Handle Auth0 callback for Vendor Manager"""
    if error:
        frappe.throw(_(f"Auth0 Error: {error}"))

    if not code:
        frappe.throw(_("Authorization code not received"))

    auth0_domain = frappe.conf.get('auth0_domain')
    client_id = frappe.conf.get('auth0_vendor_manager_client_id')
    client_secret = frappe.conf.get('auth0_vendor_manager_client_secret')
    redirect_uri = f"{frappe.utils.get_url()}/api/method/vendor_manager.auth.oauth.vendor_manager_callback"

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

    # Create or update Frappe user with Vendor Manager prefix
    auth0_email = user_info.get('email')
    if auth0_email:
        # Use prefixed email for Vendor Manager users to separate from Lexicon users
        vendor_manager_email = f"vendor-{auth0_email}"

        # IMPORTANT: Check if Lexicon user exists with same base email
        # This prevents accidental cross-login
        lexicon_email = f"lexicon-{auth0_email}"
        if frappe.db.exists('User', lexicon_email):
            frappe.logger().warning(f"Lexicon user {lexicon_email} exists. Creating separate Vendor Manager user: {vendor_manager_email}")

        user = None
        if not frappe.db.exists('User', vendor_manager_email):
            # Create new Vendor Manager user
            user = frappe.get_doc({
                'doctype': 'User',
                'email': vendor_manager_email,
                'first_name': user_info.get('given_name', auth0_email.split('@')[0]),
                'last_name': user_info.get('family_name', ''),
                'enabled': 1,
                'user_type': 'System User',
                'send_welcome_email': 0,
                'bio': f"Vendor Manager user authenticated via Auth0 ({auth0_email})"
            })
            user.insert(ignore_permissions=True)

            # Assign admin roles for full access
            user.add_roles('System Manager', 'Desk User')
            frappe.db.commit()

            frappe.logger().info(f"Created new Vendor Manager user: {vendor_manager_email} from Auth0 email: {auth0_email}")
        else:
            user = frappe.get_doc('User', vendor_manager_email)
            # Ensure user has essential roles
            essential_roles = ['System Manager', 'Desk User']
            current_roles = [d.role for d in user.roles]
            missing_roles = [r for r in essential_roles if r not in current_roles]
            if missing_roles:
                for role in missing_roles:
                    user.add_roles(role)
                user.save(ignore_permissions=True)
                frappe.db.commit()

        # Login the Vendor Manager-specific user
        frappe.local.login_manager.login_as(vendor_manager_email)
        frappe.local.response['type'] = 'redirect'
        frappe.local.response['location'] = '/app/vendor'  # Redirect to Vendor list
    else:
        frappe.throw(_("Email not found in Auth0 user info"))
