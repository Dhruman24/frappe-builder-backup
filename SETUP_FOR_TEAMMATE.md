# Frappe Builder + CRM + Lexicon - Setup Guide for Teammates

**Last Updated:** October 21, 2025
**Backup Created:** 20251021_140539
**Environment:** Windows with Docker Desktop

---

## Prerequisites

Before you start, ensure you have:

1. **Docker Desktop** installed and running on Windows
   - Download from: https://www.docker.com/products/docker-desktop/
   - Minimum 8GB RAM, 50GB disk space
   - WSL 2 enabled

2. **Git** installed
   - Download from: https://git-scm.com/download/win

3. **Port 8000** available (not used by other applications)

---

## Step 1: Clone the Repository

Open PowerShell or Command Prompt:

```bash
cd C:\Users\[YourUsername]
git clone [YOUR_GITHUB_REPO_URL] frappe-builder
cd frappe-builder
```

---

## Step 2: Start Docker Containers

Make sure Docker Desktop is running, then:

```bash
docker-compose up -d
```

This will:
- Pull Frappe Docker images
- Create containers for Frappe, MariaDB, Redis
- Start all services

**Wait 2-3 minutes** for containers to fully start.

Verify containers are running:
```bash
docker ps
```

You should see:
- frappe-builder-frappe-1
- frappe-builder-mariadb-1
- frappe-builder-redis-1

---

## Step 3: Create the Site

```bash
docker exec -it frappe-builder-frappe-1 bash
cd frappe-bench
bench new-site builder.localhost --admin-password [CHOOSE_A_PASSWORD] --db-root-password 123 --install-app builder
exit
```

Replace `[CHOOSE_A_PASSWORD]` with a secure password (save it for later!).

---

## Step 4: Restore the Backup

### Option A: Using the Restore Script (Recommended)

Double-click `scripts/restore.bat` or run from Command Prompt:

```bash
cd scripts
restore.bat
```

This script will:
- Restore the database
- Restore files
- Install all apps (builder, crm, lexicon)
- Migrate the database
- Set up Redis configuration

### Option B: Manual Restore

If the script doesn't work, run these commands:

```bash
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost restore backups/20251021_140539-builder_localhost-database.sql.gz"

docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost --force restore backups/20251021_140539-builder_localhost-files.tar"

docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost --force restore backups/20251021_140539-builder_localhost-private-files.tar"
```

---

## Step 5: Install Custom Apps

First, copy the custom apps from the repository to the container:

```bash
# Copy Lexicon app (Custom Vendor Directory)
docker cp apps/lexicon frappe-builder-frappe-1:/home/frappe/frappe-bench/apps/

# Copy Vendor Manager app
docker cp apps/vendor-manager frappe-builder-frappe-1:/home/frappe/frappe-bench/apps/
```

Then install all apps:

```bash
docker exec -it frappe-builder-frappe-1 bash
cd frappe-bench

# Install Frappe CRM (from official repo)
bench get-app crm
bench --site builder.localhost install-app crm

# Install Custom Apps (already copied to container)
bench --site builder.localhost install-app lexicon
bench --site builder.localhost install-app vendor-manager

# Migrate database
bench --site builder.localhost migrate

# Clear cache
bench --site builder.localhost clear-cache

# Restart
bench restart

exit
```

---

## Step 6: Access the System

1. Open browser: http://builder.localhost:8000
2. Login with:
   - **Username:** Administrator
   - **Password:** [The password you set in Step 3]

---

## Step 7: Verify Everything Works

### Test Vendor Management
1. Go to: http://builder.localhost:8000/app/vendor
2. You should see 5 sample vendors (Vendor 1-5)
3. Try creating a new vendor

### Test Waitlist
1. Go to: http://builder.localhost:8000/app/waitlist
2. Create a new waitlist entry

### Test Lexicon Vendors Directory
1. Go to: http://builder.localhost:8000/app/vendors
2. You should see vendor cards displayed with styling

### Test Frappe CRM
1. Go to: http://builder.localhost:8000/app/crm
2. Explore Leads, Deals, Organizations

---

## Applications Installed

| Application | Version | Purpose |
|------------|---------|---------|
| **Frappe Framework** | v15.85.0 | Core framework |
| **Builder** | v1.18.0 | Page builder tool |
| **Frappe CRM** | v1.53.1 | Official CRM with 50+ doctypes |
| **Lexicon** | v0.0.1 | Custom vendor directory |

---

## Custom Doctypes

### 1. Vendor (Module: Vendor Manager)
- **Fields:** vendor_name, type, email, phone, status, description
- **Sample Data:** 5 vendors included
- **Access:** http://builder.localhost:8000/app/vendor

### 2. Waitlist (Module: Vendor Manager)
- **Fields:** full_name, email, vendor_type (links to Vendor), notes
- **Access:** http://builder.localhost:8000/app/waitlist

---

## Common Commands

### Container Management
```bash
# Start containers
docker-compose up -d

# Stop containers
docker-compose down

# Restart a specific container
docker restart frappe-builder-frappe-1

# View logs
docker logs frappe-builder-frappe-1 -f

# Access container shell
docker exec -it frappe-builder-frappe-1 bash
```

### Frappe Bench Commands (run inside container)
```bash
# Access container
docker exec -it frappe-builder-frappe-1 bash
cd frappe-bench

# Clear cache
bench --site builder.localhost clear-cache

# Migrate database
bench --site builder.localhost migrate

# Restart bench
bench restart

# Create backup
bench --site builder.localhost backup --with-files

# Access database
bench --site builder.localhost mariadb

# Check site status
bench --site builder.localhost doctor

# List installed apps
bench --site builder.localhost list-apps
```

---

## Troubleshooting

### Issue 1: Can't access http://builder.localhost:8000

**Solution:**
```bash
# Check if containers are running
docker ps

# Restart containers
docker-compose restart

# Check logs for errors
docker logs frappe-builder-frappe-1 --tail 50
```

### Issue 2: "Site does not exist"

**Solution:**
```bash
# List sites
docker exec frappe-builder-frappe-1 ls /home/frappe/frappe-bench/sites

# If builder.localhost doesn't exist, create it (Step 3)
```

### Issue 3: Vendors page shows no data

**Solution:**
```bash
docker exec frappe-builder-frappe-1 sh -c "cd frappe-bench && bench --site builder.localhost clear-cache"
docker restart frappe-builder-frappe-1
```

### Issue 4: Permission denied errors

**Solution:**
- Make sure you're logged in as Administrator
- Check user has "System Manager" role

### Issue 5: Database connection failed

**Solution:**
```bash
# Check MariaDB container
docker ps | grep mariadb

# Restart all containers
docker-compose restart
```

---

## Project Structure

```
C:\Users\[YourUsername]\frappe-builder\
├── docker-compose.yml         # Docker configuration
├── apps\                      # Custom Frappe apps
│   ├── lexicon\              # Custom vendor directory app
│   └── vendor-manager\       # Vendor management app
├── backups\                   # Database and file backups
│   ├── 20251021_140539-builder_localhost-database.sql.gz
│   ├── 20251021_140539-builder_localhost-site_config_backup.json
│   ├── 20251021_140539-builder_localhost-files.tar
│   └── 20251021_140539-builder_localhost-private-files.tar
├── scripts\
│   └── restore.bat            # Automated restore script
├── COMPLETE_PROJECT_GUIDE.md  # Comprehensive project documentation
├── SETUP_FOR_TEAMMATE.md      # This file
└── README.md                  # Original project README
```

---

## What's Included in the Backup

✅ **Database:**
- All Vendor records (5 samples)
- All Waitlist entries
- Frappe CRM data (Leads, Deals, Organizations, Contacts)
- User accounts and permissions
- Custom DocType definitions

✅ **Files:**
- Uploaded documents
- Generated reports
- System files

✅ **Configuration:**
- Site settings
- App configurations
- Database connection details

---

## API Access (Optional)

If you need to integrate with external applications:

### Generate API Keys
1. Login → User → Administrator
2. Click "API Access" tab
3. Click "Generate Keys"
4. Save API Key and API Secret

### Example API Calls

**Get All Vendors:**
```bash
curl -X GET http://builder.localhost:8000/api/resource/Vendor \
  -H "Authorization: token API_KEY:API_SECRET"
```

**Create a Vendor:**
```bash
curl -X POST http://builder.localhost:8000/api/resource/Vendor \
  -H "Authorization: token API_KEY:API_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "vendor_name": "New Vendor",
    "type": "Supplier",
    "email": "new@example.com",
    "status": "Active"
  }'
```

See `COMPLETE_PROJECT_GUIDE.md` for full API documentation.

---

## Next Steps

1. **Change Administrator Password**
   - Go to User settings
   - Update to a secure password

2. **Add Real Vendor Data**
   - Replace sample vendors with actual data
   - Import from CSV if needed

3. **Customize Lexicon Page**
   - Modify `/home/frappe/frappe-bench/apps/lexicon/lexicon/lexicon/page/vendors/vendors.js`
   - Add search, filters, pagination as needed

4. **Explore Frappe CRM**
   - Create Leads
   - Set up Deal pipelines
   - Add Organizations and Contacts

5. **Set Up Permissions**
   - Create custom roles
   - Assign users to specific modules

---

## Getting Help

1. **Check Documentation:**
   - Read `COMPLETE_PROJECT_GUIDE.md` for detailed information
   - Check `TROUBLESHOOTING.md` for common issues

2. **View Logs:**
   ```bash
   docker logs frappe-builder-frappe-1 -f
   ```

3. **Frappe Resources:**
   - Documentation: https://frappeframework.com/docs
   - Forum: https://discuss.frappe.io
   - Discord: https://discord.gg/frappe

4. **Contact Original Developer:**
   - Email: dhruman@regos.ai
   - Organization: APAS

---

## Important Notes

⚠️ **Windows-Specific:**
- Use PowerShell or Command Prompt (not Git Bash for Docker commands)
- Ensure Docker Desktop is set to Linux containers (not Windows containers)
- WSL 2 must be enabled

⚠️ **Passwords:**
- Save your Administrator password securely
- Database root password is set to `123` (change in production)

⚠️ **First Run:**
- Initial setup may take 5-10 minutes
- Some operations require container restart
- Clear browser cache if pages don't load correctly

---

**Setup Complete!** 🎉

You now have a fully functional Frappe Builder + CRM + Lexicon system running on your Windows machine with Docker.

For detailed information about the project architecture, API reference, and development guidelines, see `COMPLETE_PROJECT_GUIDE.md`.
