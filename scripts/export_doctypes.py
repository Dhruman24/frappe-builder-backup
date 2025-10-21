import frappe
import json
import os

frappe.connect()

# Export Vendor DocType
vendor_doc = frappe.get_doc('DocType', 'Vendor')
with open('/tmp/vendor_doctype.json', 'w') as f:
    json.dump(vendor_doc.as_dict(), f, indent=2, default=str)
print('✓ Vendor DocType exported')

# Export Waitlist DocType
waitlist_doc = frappe.get_doc('DocType', 'Waitlist')
with open('/tmp/waitlist_doctype.json', 'w') as f:
    json.dump(waitlist_doc.as_dict(), f, indent=2, default=str)
print('✓ Waitlist DocType exported')

# Export sample vendor data
vendors = frappe.get_all('Vendor', fields=['*'])
with open('/tmp/vendors_data.json', 'w') as f:
    json.dump(vendors, f, indent=2, default=str)
print(f'✓ Exported {len(vendors)} vendors')

print('\nExport complete! Files saved to /tmp/')
