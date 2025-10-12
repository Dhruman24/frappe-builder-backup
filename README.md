# Frappe Builder - Web Page Project

This repository contains a complete backup of a Frappe Builder site with custom web pages. This package can be easily deployed on any machine with Docker installed.

## 📋 Prerequisites

Before you begin, ensure you have the following installed on your system:

- **Docker Desktop** (Windows/Mac) or **Docker Engine** (Linux)
  - Download from: https://www.docker.com/products/docker-desktop
- **Docker Compose** (usually included with Docker Desktop)
- **Git** (to clone this repository)

### System Requirements
- Minimum 4GB RAM
- 10GB free disk space
- Windows 10/11, macOS 10.15+, or Linux

## 🚀 Quick Start Guide

Follow these steps to get the web page running on your local machine:

### Step 1: Clone the Repository

```bash
git clone <your-repository-url>
cd frappe-builder
```

### Step 2: Start Docker Containers

```bash
docker-compose up -d
```

This will download and start three containers:
- MariaDB (database)
- Redis (cache)
- Frappe Bench (application server)

Wait for 1-2 minutes for all services to start properly.

### Step 3: Verify Containers are Running

```bash
docker ps
```

You should see three running containers: `frappe-builder-frappe-1`, `frappe-builder-redis-1`, and `frappe-builder-mariadb-1`.

### Step 4: Access the Container

```bash
docker exec -it frappe-builder-frappe-1 bash
```

### Step 5: Initialize Frappe Bench (First Time Only)

Inside the container, run these commands:

```bash
cd frappe-bench

# Create a new site
bench new-site builder.localhost --force --db-root-password root --admin-password admin

# Install the builder app
bench --site builder.localhost install-app builder
```

### Step 6: Restore the Backup

Still inside the container, run:

```bash
# Exit the container first
exit

# Copy backup files to the container
docker cp ./backups/. frappe-builder-frappe-1:/home/frappe/frappe-bench/sites/builder.localhost/private/backups/

# Access the container again
docker exec -it frappe-builder-frappe-1 bash

# Navigate to bench directory and restore
cd frappe-bench

# Find the backup file name
ls -lh sites/builder.localhost/private/backups/

# Restore the database backup (replace with your actual backup filename)
bench --site builder.localhost restore --with-public-files --with-private-files sites/builder.localhost/private/backups/20251012_041319-builder_localhost-database.sql.gz

# Clear cache
bench --site builder.localhost clear-cache
```

### Step 7: Start the Development Server

```bash
# Set builder.localhost as the default site
bench use builder.localhost

# Start the bench server
bench start
```

### Step 8: Access the Web Page

Open your browser and navigate to:

```
http://localhost:8000
```

**Default Login Credentials:**
- Username: `Administrator`
- Password: `admin`

## 📁 Project Structure

```
frappe-builder/
├── backups/                    # Site backup files
│   ├── *-database.sql.gz      # Database backup
│   ├── *-files.tar            # Public files (images, assets)
│   ├── *-private-files.tar    # Private files
│   └── *-site_config_backup.json
├── docker-compose.yml          # Docker configuration
├── scripts/                    # Utility scripts
│   └── restore.sh             # Automated restore script
├── docs/                       # Additional documentation
└── README.md                   # This file
```

## 🔧 Alternative: Automated Restore Script

For easier setup, you can use the automated restore script:

```bash
# Make the script executable (Linux/Mac)
chmod +x scripts/restore.sh

# Run the script
./scripts/restore.sh
```

For Windows, use Git Bash or WSL to run the script.

## 🛠️ Troubleshooting

### Container Won't Start
```bash
# Stop all containers
docker-compose down

# Remove old containers and volumes
docker-compose down -v

# Start fresh
docker-compose up -d
```

### Database Connection Error
```bash
# Check if MariaDB is ready
docker exec frappe-builder-mariadb-1 mysql -uroot -proot -e "SELECT 1"

# Wait 30 seconds if not ready, then try again
```

### Port Already in Use
If port 8000 or 9000 is already in use, edit `docker-compose.yml`:

```yaml
ports:
  - "8080:8000"  # Change 8000 to 8080 or any free port
  - "9090:9000"  # Change 9000 to 9090 or any free port
```

### Can't Access via Browser
Make sure to add this line to your hosts file:

**Windows:** `C:\Windows\System32\drivers\etc\hosts`
**Mac/Linux:** `/etc/hosts`

Add:
```
127.0.0.1 builder.localhost
```

## 📊 Backup Files Included

This package includes:
- **Database backup**: All data, configurations, and web pages
- **Public files**: Images, CSS, JavaScript, and other assets
- **Private files**: Internal system files
- **Site configuration**: Site-specific settings

## 🌐 Uploading to Production Server

To deploy this to a production server:

1. **Using Frappe Cloud** (Recommended):
   - Sign up at https://frappecloud.com
   - Create a new site
   - Upload the backup files through the dashboard

2. **Using Your Own Server**:
   - Set up a Frappe production environment
   - Copy backup files to the server
   - Restore using `bench restore`
   - Configure nginx/SSL certificates

3. **Using Docker on Remote Server**:
   - Copy this entire folder to the server
   - Run `docker-compose up -d`
   - Follow the restore steps above
   - Configure a reverse proxy (nginx) for proper domain access

## 📞 Support & Contact

If you encounter any issues:
1. Check the logs: `docker-compose logs -f frappe`
2. Refer to the troubleshooting section above
3. Check Frappe documentation: https://frappeframework.com/docs

## 📝 Notes

- The default admin password is `admin` - **Change this immediately** after first login
- All data is stored in Docker volumes for persistence
- Stopping containers won't delete your data
- To completely remove everything: `docker-compose down -v`

## 🔐 Security Recommendations

For production deployment:
1. Change default passwords
2. Enable HTTPS/SSL
3. Set up firewall rules
4. Regular backups
5. Keep Frappe and apps updated

---

**Created:** October 12, 2025
**Frappe Version:** Latest
**Builder Version:** Latest
