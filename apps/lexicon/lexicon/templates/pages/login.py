import frappe
from frappe import _

def get_context(context):
    context.no_cache = 1

    # Check if already logged in
    if frappe.session.user != "Guest":
        frappe.local.flags.redirect_location = "/app"
        raise frappe.Redirect

    # Get social login providers (if any configured via Frappe's Social Login Keys)
    social_login = []
    try:
        providers = frappe.get_all(
            "Social Login Key",
            filters={"enable_social_login": 1},
            fields=["name", "provider_name", "icon", "client_id"]
        )
        for provider in providers:
            social_login.append({
                "provider_name": provider.provider_name,
                "auth_url": f"/api/method/frappe.integrations.oauth2_logins.login_via_{provider.name.lower().replace(' ', '_')}",
                "icon": provider.icon
            })
    except:
        pass

    context.social_login = social_login

    # Check if LDAP is enabled
    context.ldap_settings = frappe._dict({"enabled": False})
    try:
        ldap_settings = frappe.get_doc("LDAP Settings")
        if ldap_settings.enabled:
            context.ldap_settings = ldap_settings
    except:
        pass

    return context
