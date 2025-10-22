frappe.pages["vendors"].on_page_load = function(wrapper) {
    let page = frappe.ui.make_app_page({
        parent: wrapper,
        title: "Vendors Directory",
        single_column: true
    });

    frappe.call({
        method: "lexicon.lexicon.page.vendors.vendors.get_vendors",
        callback: function(r) {
            if (r.message) {
                let html = "";
                r.message.forEach(vendor => {
                    const statusClass = vendor.status === "Active" ? "success" : "secondary";
                    html += `
                        <div class="card p-3 m-2 shadow-sm" style="border-left: 4px solid #007bff">
                            <h4 class="mb-2">${vendor.vendor_name}</h4>
                            <p class="mb-1"><strong>Type:</strong> ${vendor.type}</p>
                            <p class="mb-1"><strong>Email:</strong> ${vendor.email}</p>
                            <p class="mb-1"><strong>Phone:</strong> ${vendor.phone}</p>
                            <span class="badge bg-${statusClass}">${vendor.status}</span>
                        </div>
                    `;
                });
                $(page.body).html(html);
            } else {
                $(page.body).html("<p class=\"text-muted p-3\">No vendors found.</p>");
            }
        },
        error: function() {
            $(page.body).html("<p class=\"text-danger p-3\">Error loading vendors.</p>");
        }
    });
};
