# Frappe Builder + CRM + Lexicon - Complete Project Guide

**Last Updated:** October 21, 2025
**Environment:** Frappe Framework v15.85.0 on Docker (Windows)
**Site URL:** http://builder.localhost:8000

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [System Overview](#system-overview)
3. [What We Built](#what-we-built)
4. [How to Access](#how-to-access)
5. [Architecture](#architecture)
6. [Technical Details](#technical-details)
7. [API Reference](#api-reference)
8. [Troubleshooting](#troubleshooting)
9. [ChatGPT Context Prompt](#chatgpt-context-prompt)
10. [Project History](#project-history)

---

## Quick Start

### Access Your System

1. **Login:** `http://builder.localhost:8000`
2. **Credentials:** Administrator / (your password)

### Available Applications

| Application | URL | Purpose |
|------------|-----|---------|
| **Vendor Management** | `/app/vendor` | Manage vendors (CRUD) |
| **Waitlist Management** | `/app/waitlist` | Track potential vendors |
| **Vendors Directory** | `/app/vendors` | Public-facing vendor display (Lexicon) |
| **Frappe CRM** | `/app/crm` | Full CRM (Leads, Deals, Organizations) |
| **Builder** | `/builder` | Page builder tool |

### Common Commands

```bash
# Start Docker containers
docker-compose up -d

# Access container shell
docker exec -it frappe-builder-frappe-1 bash

# Clear cache
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost clear-cache"

# Restart container
docker restart frappe-builder-frappe-1

# View logs
docker logs frappe-builder-frappe-1 -f

# Database access
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost mariadb"

# Create backup
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost backup --with-files"
```

---

## System Overview

### Installed Apps

```
Container: frappe-builder-frappe-1
├── Frappe Framework (v15.85.0) - Core
├── Builder (v1.18.0) - Page builder
├── CRM (v1.53.1) - Official Frappe CRM
└── Lexicon (v0.0.1) - Custom vendor directory
```

### Custom Doctypes

1. **Vendor** (Module: Vendor Manager)
   - Fields: vendor_name, type, email, phone, status, description
   - Sample Data: 5 vendors

2. **Waitlist** (Module: Vendor Manager)
   - Fields: full_name, email, vendor_type, notes
   - Links to Vendor doctype

### Current State

✅ **Working:**
- Vendor management (full CRUD)
- Waitlist tracking
- Lexicon vendors directory page
- Frappe CRM (50+ doctypes)
- REST API access
- Standard Frappe authentication

❌ **Not Implemented:**
- Auth0 OAuth integration (attempted but rolled back)
- Separate user bases for CRM/Lexicon
- vendor-manager app installation (using Custom doctypes instead)

---

## What We Built

### 1. Vendor DocType

**Purpose:** Track vendors/suppliers/partners

**Fields:**
- `vendor_name` (Data, Required) - Auto-naming field
- `type` (Select) - Supplier, Partner, or Distributor
- `email` (Data)
- `phone` (Data)
- `status` (Select) - Active or Inactive
- `description` (Text)

**Sample Data:**
```
Vendor 1 - Supplier - vendor1@example.com - Active
Vendor 2 - Supplier - vendor2@example.com - Active
Vendor 3 - Partner - vendor3@example.com - Active
Vendor 4 - Distributor - vendor4@example.com - Active
Vendor 5 - Supplier - vendor5@example.com - Inactive
```

**Access:**
- List View: `http://builder.localhost:8000/app/vendor`
- API: `http://builder.localhost:8000/api/resource/Vendor`

### 2. Waitlist DocType

**Purpose:** Track potential vendors before onboarding

**Fields:**
- `full_name` (Data, Required)
- `email` (Data, Required)
- `vendor_type` (Link to Vendor)
- `notes` (Text)

**Naming:** Auto-generated as WL-0001, WL-0002, etc.

**Access:**
- List View: `http://builder.localhost:8000/app/waitlist`
- API: `http://builder.localhost:8000/api/resource/Waitlist`

### 3. Lexicon Vendors Directory

**Purpose:** Display vendors as styled cards on a public-facing page

**Location:**
- Frontend: `/home/frappe/frappe-bench/apps/lexicon/lexicon/lexicon/page/vendors/vendors.js`
- Backend: `/home/frappe/frappe-bench/apps/lexicon/lexicon/lexicon/page/vendors/vendors.py`

**Features:**
- Card-based layout
- Color-coded status badges (Active=green, Inactive=gray)
- Shows: Vendor Name, Type, Email, Phone, Status
- Real-time data from Vendor doctype

**Access:** `http://builder.localhost:8000/app/vendors`

### 4. Frappe CRM

**Official Frappe CRM** with 50+ doctypes:

**Core Features:**
- **Leads:** Track potential customers
- **Deals:** Sales pipeline management
- **Organizations:** Company/account management
- **Contacts:** Individual contact records
- **Call Logs:** Communication tracking
- **Tasks:** Activity management
- **Dashboard:** Analytics and reports

**Access:** `http://builder.localhost:8000/app/crm`

---

## How to Access

### Login
1. Navigate to: `http://builder.localhost:8000`
2. Login with: **Administrator** / (your password)

### Manage Vendors
1. Go to: `/app/vendor`
2. Click **"New"** to create a vendor
3. Fill in details and **Save**
4. Edit/Delete from list view

### Manage Waitlist
1. Go to: `/app/waitlist`
2. Click **"New"** to create entry
3. Fill in Full Name, Email
4. Select Vendor from dropdown (optional)
5. Add notes and **Save**

### View Vendors Directory (Lexicon)
1. Go to: `/app/vendors`
2. See all vendors displayed as cards
3. Updates automatically when vendors are added/edited

### Use Frappe CRM
1. Go to: `/app/crm`
2. Access Leads, Deals, Organizations, Contacts
3. Create deals, track pipeline, manage customers

---

## Architecture

### Data Flow

```
User Creates/Edits Vendor
         ↓
   Vendor DocType
   (tabVendor table)
         ↓
   Lexicon API Call
   (get_vendors method)
         ↓
   Vendors Page Display
   (Card-based UI)
```

### Database Schema

**tabVendor:**
```sql
CREATE TABLE `tabVendor` (
  name VARCHAR(140) PRIMARY KEY,
  vendor_name VARCHAR(140) NOT NULL,
  type VARCHAR(140),
  email VARCHAR(140),
  phone VARCHAR(140),
  status VARCHAR(140),
  description TEXT,
  creation DATETIME(6),
  modified DATETIME(6),
  owner VARCHAR(140),
  modified_by VARCHAR(140)
);
```

**tabWaitlist:**
```sql
CREATE TABLE `tabWaitlist` (
  name VARCHAR(140) PRIMARY KEY,
  full_name VARCHAR(140) NOT NULL,
  email VARCHAR(140) NOT NULL,
  vendor_type VARCHAR(140), -- Links to Vendor
  notes TEXT,
  creation DATETIME(6),
  modified DATETIME(6),
  owner VARCHAR(140),
  modified_by VARCHAR(140)
);
```

### File Structure

```
/home/frappe/frappe-bench/
├── apps/
│   ├── frappe/              # Core framework
│   ├── builder/             # Page builder app
│   ├── crm/                 # Official Frappe CRM
│   ├── lexicon/             # Custom vendor directory
│   │   └── lexicon/
│   │       └── lexicon/
│   │           └── page/
│   │               └── vendors/
│   │                   ├── vendors.py   # Backend API
│   │                   ├── vendors.js   # Frontend UI
│   │                   └── vendors.json # Page config
│   └── vendor-manager/      # Renamed custom app (not installed)
├── sites/
│   ├── builder.localhost/
│   │   ├── site_config.json
│   │   └── private/backups/
│   └── apps.txt
└── env/                     # Python virtual environment
```

---

## Technical Details

### Environment

- **OS:** Windows with Docker Desktop
- **Container:** `frappe-builder-frappe-1`
- **Framework:** Frappe v15.85.0
- **Python:** 3.11.6
- **Database:** MariaDB 10.8
- **Cache/Queue:** Redis 7

### Container Paths

- **Bench Directory:** `/home/frappe/frappe-bench`
- **Apps Directory:** `/home/frappe/frappe-bench/apps`
- **Site Directory:** `/home/frappe/frappe-bench/sites/builder.localhost`
- **Backups:** `/home/frappe/frappe-bench/sites/builder.localhost/private/backups`

### Configuration Files

**Site Config:** `/home/frappe/frappe-bench/sites/builder.localhost/site_config.json`
```json
{
  "db_host": "mariadb",
  "db_name": "_f2c59d1a6ecb43cb",
  "db_type": "mariadb",
  "redis_cache": "redis://redis:6379",
  "redis_queue": "redis://redis:6379",
  "redis_socketio": "redis://redis:6379"
}
```

### Backend Code

**Lexicon API** (`vendors.py`):
```python
import frappe

@frappe.whitelist()
def get_vendors():
    """Fetch vendors from Vendor doctype"""
    return frappe.get_all(
        'Vendor',
        fields=['vendor_name', 'type', 'email', 'phone', 'status', 'description'],
        order_by='vendor_name asc'
    )
```

**Frontend Code** (`vendors.js`):
```javascript
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
            }
        }
    });
};
```

---

## API Reference

### Authentication

Generate API keys:
1. Login → User → Administrator
2. Click "API Access" tab
3. Click "Generate Keys"
4. Save API Key and API Secret

Use in requests:
```http
Authorization: token <api_key>:<api_secret>
```

### Vendor Endpoints

#### Get All Vendors
```http
GET http://builder.localhost:8000/api/resource/Vendor
Authorization: token <api_key>:<api_secret>
```

**Response:**
```json
{
  "data": [
    {
      "name": "Vendor 1",
      "vendor_name": "Vendor 1",
      "type": "Supplier",
      "email": "vendor1@example.com",
      "phone": "+1-555-0101",
      "status": "Active",
      "description": "Primary supplier"
    }
  ]
}
```

#### Get Specific Vendor
```http
GET http://builder.localhost:8000/api/resource/Vendor/Vendor%201
Authorization: token <api_key>:<api_secret>
```

#### Create Vendor
```http
POST http://builder.localhost:8000/api/resource/Vendor
Authorization: token <api_key>:<api_secret>
Content-Type: application/json

{
  "vendor_name": "New Vendor",
  "type": "Supplier",
  "email": "newvendor@example.com",
  "phone": "+1-555-0199",
  "status": "Active",
  "description": "New supplier"
}
```

#### Update Vendor
```http
PUT http://builder.localhost:8000/api/resource/Vendor/Vendor%201
Authorization: token <api_key>:<api_secret>
Content-Type: application/json

{
  "status": "Inactive"
}
```

#### Delete Vendor
```http
DELETE http://builder.localhost:8000/api/resource/Vendor/Vendor%201
Authorization: token <api_key>:<api_secret>
```

### Lexicon Page API

#### Get Vendors (via Lexicon method)
```http
GET http://builder.localhost:8000/api/method/lexicon.lexicon.page.vendors.vendors.get_vendors
Authorization: token <api_key>:<api_secret>
```

### Waitlist Endpoints

Same pattern as Vendor, replace `/Vendor` with `/Waitlist`

### CRM Endpoints

```http
GET /api/resource/CRM%20Lead
GET /api/resource/CRM%20Deal
GET /api/resource/CRM%20Organization
GET /api/resource/CRM%20Contact
```

---

## Troubleshooting

### Common Issues

#### 1. Lexicon Page Shows "No vendors found"

**Symptoms:** `/app/vendors` displays empty or error message

**Solutions:**
```bash
# Check if vendors exist
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost mariadb -e 'SELECT * FROM tabVendor;'"

# Clear cache
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost clear-cache"

# Restart container
docker restart frappe-builder-frappe-1

# Check browser console for JavaScript errors
# Open DevTools (F12) and look for red errors
```

#### 2. Can't Access /app URLs

**Symptoms:** Getting "Not Found" or 404 errors

**Solutions:**
```bash
# Make sure container is running
docker ps | grep frappe-builder

# Check if you're logged in
# Go to http://builder.localhost:8000 and login

# Verify site is accessible
curl http://builder.localhost:8000

# Restart if needed
docker restart frappe-builder-frappe-1
```

#### 3. Permission Denied Errors

**Symptoms:** Can't create/edit vendors or waitlist entries

**Solutions:**
- Login as Administrator
- Go to User settings
- Ensure user has "System Manager" role

#### 4. Database Connection Issues

**Symptoms:** "Database connection failed" or similar errors

**Solutions:**
```bash
# Check MariaDB container
docker ps | grep mariadb

# Restart all containers
docker-compose restart

# Check site_config.json
docker exec frappe-builder-frappe-1 cat /home/frappe/frappe-bench/sites/builder.localhost/site_config.json
```

#### 5. Container Won't Start

**Symptoms:** `docker ps` doesn't show frappe-builder-frappe-1

**Solutions:**
```bash
# Check logs
docker logs frappe-builder-frappe-1

# Start container
docker start frappe-builder-frappe-1

# Rebuild if necessary
docker-compose up -d --build
```

### Debugging Commands

```bash
# View container logs
docker logs frappe-builder-frappe-1 --tail 100

# Access Python console
docker exec -it frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost console"

# Check database connection
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost mariadb -e 'SHOW TABLES;'"

# List installed apps
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost list-apps"

# Check site status
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost doctor"
```

### Error: "Module not found"

If you see `ModuleNotFoundError: No module named 'vendor_manager'`:

**This is expected!** We created Vendor and Waitlist as Custom Doctypes, not as part of the vendor_manager app. Everything works fine; ignore this error in logs.

### Backup and Restore

**Create Backup:**
```bash
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost backup --with-files"
```

**Restore Backup:**
```bash
# List backups
docker exec frappe-builder-frappe-1 ls /home/frappe/frappe-bench/sites/builder.localhost/private/backups/

# Restore specific backup
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost restore /home/frappe/frappe-bench/sites/builder.localhost/private/backups/[filename].sql.gz"
```

---

## ChatGPT Context Prompt

**Copy and paste this to ChatGPT for detailed help:**

```
I'm working with a Frappe Framework (v15.85.0) project running in Docker on Windows.

ENVIRONMENT:
- Site URL: http://builder.localhost:8000
- Container: frappe-builder-frappe-1
- Database: MariaDB 10.8
- Working Directory: C:\Users\dhrum\frappe-builder

INSTALLED APPS:
1. Frappe (v15.85.0) - Core framework
2. Builder (v1.18.0) - Page builder
3. CRM (v1.53.1) - Official Frappe CRM
4. Lexicon (v0.0.1) - Custom vendor directory app

CUSTOM DOCTYPES:
1. Vendor (Module: Vendor Manager)
   - Fields: vendor_name, type (Supplier/Partner/Distributor), email, phone, status (Active/Inactive), description
   - Access: /app/vendor
   - 5 sample vendors created

2. Waitlist (Module: Vendor Manager)
   - Fields: full_name, email, vendor_type (Links to Vendor), notes
   - Access: /app/waitlist

LEXICON VENDORS PAGE:
- Location: /home/frappe/frappe-bench/apps/lexicon/lexicon/lexicon/page/vendors/
- Backend API (vendors.py): Fetches vendors from Vendor doctype
- Frontend (vendors.js): Displays vendors as Bootstrap cards
- Access: http://builder.localhost:8000/app/vendors

WHAT'S WORKING:
✅ Vendor management (full CRUD)
✅ Waitlist tracking
✅ Lexicon vendors directory display
✅ Frappe CRM features
✅ REST API access
✅ Standard Frappe authentication

WHAT'S NOT WORKING:
❌ Auth0 integration (rolled back)
❌ vendor-manager app installation (using Custom doctypes instead)

SAMPLE VENDOR DATA:
- Vendor 1 (Supplier, Active)
- Vendor 2 (Supplier, Active)
- Vendor 3 (Partner, Active)
- Vendor 4 (Distributor, Active)
- Vendor 5 (Supplier, Inactive)

DOCKER COMMANDS I USE:
docker exec -it frappe-builder-frappe-1 bash
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost [command]"

MY QUESTION:
[Write your specific question here]
```

---

## Project History

### Timeline

**October 16, 2025 - Initial Setup**
- Set up Frappe Docker environment
- Created basic site configuration
- Installed Builder app

**October 17, 2025 - Custom Apps**
- Created custom CRM app
- Created Vendor and Waitlist doctypes
- Created Lexicon app for vendor directory
- Built vendors.py and vendors.js
- Populated 5 sample vendors

**October 21, 2025 Morning - Auth0 Integration Attempt**
- Attempted Auth0 OAuth integration
- Created Social Login Keys
- Built custom login page
- Encountered multiple technical issues:
  - `user_id_property` field missing
  - OAuth callback redirect loops
  - Deprecated `is_xhr` attribute
  - Module naming conflicts
- **Decision:** Rolled back all Auth0 changes

**October 21, 2025 Afternoon - Frappe CRM Installation**
- Uninstalled custom CRM app
- Renamed to vendor-manager
- Installed official Frappe CRM v1.53.1
- Successfully migrated database
- Now have 50+ CRM doctypes available

**October 21, 2025 Evening - Vendor System Recreation**
- Recreated Vendor and Waitlist as Custom Doctypes
- Populated 5 sample vendors again
- Reconnected Lexicon page to Vendor doctype
- ✅ Everything working as originally designed!

### Lessons Learned

1. **Custom Doctypes are Simpler**
   - Creating doctypes as "Custom" is easier than app-based
   - No module installation issues
   - Works perfectly for simple use cases

2. **Auth0 Integration is Complex**
   - Frappe's OAuth system has specific requirements
   - `user_id_property` field crucial for user mapping
   - Social Login Key naming must use underscores
   - Multiple redirect handlers can conflict

3. **Frappe CRM is Powerful**
   - Official CRM provides 50+ doctypes out of the box
   - Can run alongside custom doctypes
   - Better to use CRM for complex needs

4. **Docker Simplifies Development**
   - Single container for everything
   - Easy backup and restore
   - Consistent environment

5. **Python Module Naming Matters**
   - Use underscores in module names
   - Match pyproject.toml configuration
   - Clear cache after renaming

### Key Decisions

- ✅ Use Custom Doctypes instead of vendor-manager app
- ✅ Install official Frappe CRM alongside custom doctypes
- ✅ Keep Lexicon as simple display layer
- ✅ Use standard Frappe authentication
- ❌ Postpone Auth0 integration until better understanding

---

## Next Steps & Recommendations

### Immediate (This Week)

1. **Test All Features**
   - [ ] Create vendors via `/app/vendor`
   - [ ] Create waitlist entries via `/app/waitlist`
   - [ ] Verify Lexicon display at `/app/vendors`
   - [ ] Explore Frappe CRM at `/app/crm`

2. **Add Real Data**
   - [ ] Replace sample vendors with real ones
   - [ ] Import existing vendor data if available
   - [ ] Set up waitlist workflow

3. **User Training**
   - [ ] Train team on vendor management
   - [ ] Show how to use Lexicon page
   - [ ] Demonstrate CRM features if needed

### Short Term (Next 2 Weeks)

1. **Customize Lexicon Page**
   - Add search/filter functionality
   - Add pagination for large vendor lists
   - Improve card styling
   - Add vendor categories/tags

2. **Set Up Permissions**
   - Create "Vendor Manager" role
   - Restrict access to specific users
   - Set up read-only users for Lexicon

3. **Add Workflows**
   - Vendor approval process
   - Waitlist to vendor conversion
   - Status change notifications

4. **External App Integration**
   - Generate API keys
   - Connect external app to fetch vendors
   - Implement webhook notifications

### Medium Term (Next Month)

1. **Decide on CRM Strategy**
   - **Option A:** Keep both systems separate
   - **Option B:** Migrate vendors to CRM Organizations
   - **Option C:** Link Vendor doctype to CRM Organization

2. **Enhance Features**
   - Add document attachments to vendors
   - Create vendor rating system
   - Build vendor analytics dashboard
   - Add email notifications

3. **Reporting**
   - Create vendor summary reports
   - Waitlist conversion reports
   - Status distribution charts

4. **Mobile Access**
   - Test mobile responsiveness
   - Consider Frappe mobile app integration

### Long Term (2-3 Months)

1. **Advanced Integrations**
   - If needed, revisit Auth0 with proper setup
   - Integrate with accounting systems
   - Connect to inventory management
   - Build vendor portal

2. **Automation**
   - Automated vendor onboarding emails
   - Scheduled status checks
   - Auto-archiving inactive vendors

3. **Scaling**
   - Consider multi-site setup if needed
   - Implement caching strategies
   - Optimize database queries

---

## Appendix

### Useful Links

- **Frappe Documentation:** https://frappeframework.com/docs
- **Frappe CRM GitHub:** https://github.com/frappe/crm
- **Frappe Forum:** https://discuss.frappe.io
- **Frappe Discord:** https://discord.gg/frappe

### Contact

- **Developer:** Dhruman
- **Email:** dhruman@regos.ai
- **Organization:** APAS

### Version History

- **v1.0** (Oct 21, 2025) - Initial complete setup
  - Vendor & Waitlist doctypes
  - Lexicon vendors page
  - Frappe CRM installation
  - 5 sample vendors

---

**Last Updated:** October 21, 2025
**Document Version:** 1.0
**Project Status:** ✅ Fully Operational
