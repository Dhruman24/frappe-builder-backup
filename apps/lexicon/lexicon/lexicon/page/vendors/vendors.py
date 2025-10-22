import frappe

@frappe.whitelist()
def get_vendors():
    """Fetch vendors from Vendor doctype"""
    return frappe.get_all(
        'Vendor',
        fields=['vendor_name', 'type', 'email', 'phone', 'status', 'description'],
        order_by='vendor_name asc'
    )
