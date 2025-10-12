# 🚀 Quick Start - 3 Simple Steps

Get your Frappe Builder web page running in minutes!

## Prerequisites
✅ Docker Desktop installed and running
✅ 10GB free disk space

## Option 1: Automated Script (Easiest)

### For Windows:
```batch
scripts\restore.bat
```

### For Linux/Mac:
```bash
chmod +x scripts/restore.sh
./scripts/restore.sh
```

Then start the server:
```bash
docker exec -it frappe-builder-frappe-1 bash
cd frappe-bench
bench start
```

---

## Option 2: Manual Steps (3 Commands)

### Step 1: Start Containers
```bash
docker-compose up -d
```
*Wait 60 seconds for services to start*

### Step 2: Setup Site
```bash
# Access container
docker exec -it frappe-builder-frappe-1 bash

# Inside container:
cd frappe-bench
bench new-site builder.localhost --force --db-root-password root --admin-password admin
bench --site builder.localhost install-app builder
```

### Step 3: Restore Backup
```bash
# Exit container (Ctrl+D or type 'exit')
exit

# Copy backups to container
docker cp ./backups/. frappe-builder-frappe-1:/home/frappe/frappe-bench/sites/builder.localhost/private/backups/

# Access container again
docker exec -it frappe-builder-frappe-1 bash

# Inside container - restore backup (use the latest backup file)
cd frappe-bench
bench --site builder.localhost restore --force --with-public-files --with-private-files sites/builder.localhost/private/backups/20251012_075233-builder_localhost-database.sql.gz

# Start the server
bench use builder.localhost
bench start
```

---

## Access Your Site

🌐 **URL:** http://localhost:8000
""Builder URL:**http://builder.localhost:8000/builder/

👤 **Login:**
- Username: `Administrator`
- Password: `admin`

⚠️ **Important:** Change the default password after first login!

---

## Troubleshooting

**Containers won't start?**
```bash
docker-compose down -v
docker-compose up -d
```

**Port 8000 already in use?**
Edit `docker-compose.yml` and change port 8000 to 8080

**Can't access the site?**
Add this line to your hosts file:
- Windows: `C:\Windows\System32\drivers\etc\hosts`
- Mac/Linux: `/etc/hosts`

```
127.0.0.1 builder.localhost
```

---

For detailed documentation, see [README.md](README.md)
