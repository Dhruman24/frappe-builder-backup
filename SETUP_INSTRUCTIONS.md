# Frappe Builder Setup Instructions for Windows

Welcome! This guide will help you set up the Frappe Builder project on your Windows machine and restore the latest backup to see the current progress.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Installation Steps](#installation-steps)
3. [Restoring the Backup](#restoring-the-backup)
4. [Accessing the Application](#accessing-the-application)
5. [Troubleshooting](#troubleshooting)
6. [Common Tasks](#common-tasks)

---

## Prerequisites

Before starting, ensure your Windows machine meets these requirements:

### System Requirements
- **Operating System:** Windows 10 or Windows 11
- **RAM:** Minimum 4GB (8GB recommended)
- **Disk Space:** At least 10GB free
- **Internet Connection:** Required for initial download

### Required Software

#### 1. Docker Desktop for Windows
Docker is essential for running this project. Follow these steps:

**Download & Install:**
1. Visit [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
2. Download the installer
3. Run the installer and follow the prompts
4. Restart your computer when prompted

**Verify Installation:**
1. Open PowerShell or Command Prompt
2. Run: `docker --version`
3. Run: `docker-compose --version`
4. Both commands should return version numbers

**Start Docker Desktop:**
- Launch Docker Desktop from the Start menu
- Wait for the Docker icon in the system tray to show "Docker Desktop is running"

#### 2. Git (Optional but Recommended)
If you haven't cloned the repository yet:

1. Download from [git-scm.com](https://git-scm.com/download/win)
2. Install with default settings
3. Verify: `git --version`

---

## Installation Steps

### Step 1: Get the Project Files

If you received the project as a ZIP file:
1. Extract it to a location like `C:\Users\YourName\frappe-builder`
2. Open Command Prompt and navigate to the folder:
   ```cmd
   cd C:\Users\YourName\frappe-builder
   ```

If cloning from a repository:
```cmd
git clone <repository-url>
cd frappe-builder
```

### Step 2: Configure Hosts File

This step allows you to access the application using `builder.localhost`.

**Important: You need Administrator privileges for this step.**

1. Open Notepad as Administrator:
   - Press Windows key
   - Type "Notepad"
   - Right-click on Notepad
   - Select "Run as administrator"

2. In Notepad, open the hosts file:
   - Click File → Open
   - Navigate to: `C:\Windows\System32\drivers\etc`
   - Change file type filter to "All Files (*.*)"
   - Select and open the file named `hosts`

3. Add this line at the end of the file:
   ```
   127.0.0.1 builder.localhost
   ```

4. Save the file (Ctrl+S) and close Notepad

### Step 3: Start Docker Containers

1. Open Command Prompt or PowerShell
2. Navigate to the project directory:
   ```cmd
   cd C:\Users\YourName\frappe-builder
   ```

3. Start the Docker containers:
   ```cmd
   docker-compose up -d
   ```

4. Wait for all containers to start (this may take 2-5 minutes on first run)

5. Verify containers are running:
   ```cmd
   docker ps
   ```
   You should see 3 containers running: frappe, mariadb, and redis

---

## Restoring the Backup

You have two options: **Automated (Recommended)** or **Manual**.

### Option A: Automated Restoration (Recommended)

This is the easiest method using the provided script.

1. Open Command Prompt in the project directory:
   ```cmd
   cd C:\Users\YourName\frappe-builder
   ```

2. Run the restore script:
   ```cmd
   scripts\restore.bat
   ```

3. The script will automatically:
   - Check if Docker is running
   - Start containers if needed
   - Create the Frappe site
   - Install the Builder app
   - Restore the latest backup
   - Clear caches
   - Start the development server

4. Wait for the message: "Setup complete! Access your site at http://localhost:8000"

5. **Keep the Command Prompt window open** - this is running your development server

### Option B: Manual Restoration

If you prefer to do it step-by-step or if the script doesn't work:

1. **Access the Frappe container:**
   ```cmd
   docker exec -it frappe-builder-frappe-1 bash
   ```

2. **Create a new site:**
   ```bash
   bench new-site builder.localhost --mariadb-root-password root --admin-password admin
   ```

3. **Install the Builder app:**
   ```bash
   bench --site builder.localhost install-app builder
   ```

4. **Exit the container temporarily:**
   ```bash
   exit
   ```

5. **Find the latest backup** (check the `backups` folder for the newest timestamp):
   ```
   Latest backup: 20251017_064229
   ```

6. **Copy backup files to the container:**
   ```cmd
   docker cp backups\20251017_064229-builder_localhost-database.sql.gz frappe-builder-frappe-1:/home/frappe/frappe-bench/sites/builder.localhost/
   docker cp backups\20251017_064229-builder_localhost-files.tar frappe-builder-frappe-1:/home/frappe/frappe-bench/sites/builder.localhost/
   docker cp backups\20251017_064229-builder_localhost-private-files.tar frappe-builder-frappe-1:/home/frappe/frappe-bench/sites/builder.localhost/
   docker cp backups\20251017_064229-builder_localhost-site_config_backup.json frappe-builder-frappe-1:/home/frappe/frappe-bench/sites/builder.localhost/
   ```

7. **Access the container again:**
   ```cmd
   docker exec -it frappe-builder-frappe-1 bash
   ```

8. **Restore the backup:**
   ```bash
   cd /home/frappe/frappe-bench/sites/builder.localhost
   bench --site builder.localhost --force restore 20251017_064229-builder_localhost-database.sql.gz --with-public-files 20251017_064229-builder_localhost-files.tar --with-private-files 20251017_064229-builder_localhost-private-files.tar
   ```

9. **Clear all caches:**
   ```bash
   bench --site builder.localhost clear-cache
   bench --site builder.localhost clear-website-cache
   ```

10. **Start the development server:**
    ```bash
    bench start
    ```

11. **Keep this terminal open** - the server is now running

---

## Accessing the Application

Once the setup is complete:

### Web Interface
1. Open your web browser (Chrome, Firefox, or Edge)
2. Navigate to: **http://localhost:8000**
3. Or directly to Builder: **http://builder.localhost:8000/builder/**

### Default Login Credentials
- **Username:** `Administrator`
- **Password:** `admin`

**IMPORTANT:** Change the password after your first login!

### What You'll See
After logging in, you'll see:
- The Frappe desk interface
- Access to the Builder app
- All restored web pages and content
- The current progress of the project

---

## Troubleshooting

### Issue: Docker containers won't start

**Solution:**
1. Make sure Docker Desktop is running (check system tray)
2. Restart Docker Desktop
3. Try again: `docker-compose up -d`

### Issue: "Port 8000 is already in use"

**Solution:**
1. Check what's using port 8000: `netstat -ano | findstr :8000`
2. Either:
   - Stop the application using that port
   - Or modify `docker-compose.yml` to use a different port (e.g., change `8000:8000` to `8080:8000`)

### Issue: Cannot access http://localhost:8000

**Solutions:**
1. Verify containers are running: `docker ps`
2. Check if the Frappe container is healthy: `docker logs frappe-builder-frappe-1`
3. Ensure the hosts file was modified correctly (Step 2 of Installation)
4. Try accessing http://127.0.0.1:8000 directly
5. Restart the containers:
   ```cmd
   docker-compose down
   docker-compose up -d
   ```

### Issue: "Site builder.localhost already exists"

**Solution:**
If you need to start fresh:
```cmd
docker exec -it frappe-builder-frappe-1 bash
bench drop-site builder.localhost --force
exit
```
Then run the restore script again.

### Issue: Restore script fails

**Solution:**
1. Check Docker is running: `docker ps`
2. Check Docker logs: `docker logs frappe-builder-frappe-1`
3. Try the manual restoration method instead (Option B)
4. Ensure backup files exist in the `backups` folder

### Issue: Redis connection error "ValueError: Redis URL must specify one of the following schemes"

**This error occurs when the Redis configuration is missing or incorrect.**

**Solution:**
Run these commands to fix the Redis configuration:
```cmd
docker exec frappe-builder-frappe-1 bash -c "mkdir -p /home/frappe/frappe-bench/sites && cat > /home/frappe/frappe-bench/sites/common_site_config.json << 'EOF'
{
  \"background_workers\": 1,
  \"file_watcher_port\": 6787,
  \"frappe_user\": \"frappe\",
  \"gunicorn_workers\": 4,
  \"live_reload\": true,
  \"rebase_on_pull\": false,
  \"redis_cache\": \"redis://redis:6379\",
  \"redis_queue\": \"redis://redis:6379\",
  \"redis_socketio\": \"redis://redis:6379\",
  \"restart_supervisor_on_update\": false,
  \"restart_systemd_on_update\": false,
  \"serve_default_site\": true,
  \"shallow_clone\": true,
  \"socketio_port\": 9000,
  \"use_redis_auth\": false,
  \"webserver_port\": 8000
}
EOF"
```

Then restart the containers and run the restore script again:
```cmd
docker-compose restart
scripts\restore.bat
```

**Note:** The latest version of the restore script (updated after Oct 16, 2025) includes this fix automatically.

### Issue: Login doesn't work

**Solution:**
1. Verify you're using the correct credentials (Administrator / admin)
2. Clear browser cache and cookies
3. Try in an incognito/private window
4. Restore the backup again to reset the password

---

## Common Tasks

### Starting the Application (After First Setup)

1. Make sure Docker Desktop is running
2. Open Command Prompt:
   ```cmd
   cd C:\Users\YourName\frappe-builder
   docker-compose up -d
   docker exec -it frappe-builder-frappe-1 bash
   bench start
   ```
3. Access at http://localhost:8000

### Stopping the Application

If running with `bench start`:
1. Press `Ctrl+C` in the terminal where bench is running
2. Exit the container: `exit`

To stop all containers:
```cmd
docker-compose down
```

### Creating a New Backup

From inside the Frappe container:
```bash
docker exec -it frappe-builder-frappe-1 bash
bench --site builder.localhost backup --with-files
exit
```

The backup will be created in: `/home/frappe/frappe-bench/sites/builder.localhost/private/backups/`

To copy it to your local backups folder:
```cmd
docker cp frappe-builder-frappe-1:/home/frappe/frappe-bench/sites/builder.localhost/private/backups/. backups/
```

### Viewing Logs

For Frappe application logs:
```cmd
docker logs frappe-builder-frappe-1
```

For database logs:
```cmd
docker logs frappe-builder-mariadb-1
```

For live logs (streaming):
```cmd
docker logs -f frappe-builder-frappe-1
```

### Clearing Cache

If you experience issues or need to see fresh changes:
```cmd
docker exec -it frappe-builder-frappe-1 bash
bench --site builder.localhost clear-cache
bench --site builder.localhost clear-website-cache
exit
```

### Completely Resetting Everything

**WARNING: This will delete all data!**

```cmd
docker-compose down -v
docker-compose up -d
```

Then run the restore script again: `scripts\restore.bat`

---

## Understanding the Backup Files

The `backups` folder contains timestamped backup sets. Each set has 4 files:

| File | Purpose |
|------|---------|
| `*-database.sql.gz` | Compressed database dump (all data and configuration) |
| `*-files.tar` | Public files (images, CSS, JavaScript, web assets) |
| `*-private-files.tar` | Private files (internal system files) |
| `*-site_config_backup.json` | Site configuration (database credentials, Redis config) |

**Latest Backup:** `20251017_064229` (October 17, 2025, 6:42 AM)

This backup contains all the current progress and web pages, including the Redis configuration fix.

---

## Additional Resources

- **Frappe Documentation:** https://frappeframework.com/docs
- **Frappe Builder Guide:** https://frappe.io/builder
- **Docker Documentation:** https://docs.docker.com/

---

## Getting Help

If you encounter issues not covered in this guide:

1. Check the main `README.md` file for additional information
2. Review Docker container logs: `docker logs frappe-builder-frappe-1`
3. Contact the team member who shared this project with you
4. Check Frappe community forums: https://discuss.frappe.io/

---

## Quick Reference

### Essential Commands

```cmd
# Start everything
docker-compose up -d
docker exec -it frappe-builder-frappe-1 bash
bench start

# Stop everything
# Press Ctrl+C (if bench is running)
docker-compose down

# Restart containers
docker-compose restart

# View running containers
docker ps

# Access Frappe container shell
docker exec -it frappe-builder-frappe-1 bash

# Run automated restore
scripts\restore.bat
```

### Important Paths

| Item | Location |
|------|----------|
| Project folder | `C:\Users\YourName\frappe-builder` |
| Backup files | `backups\` folder |
| Hosts file | `C:\Windows\System32\drivers\etc\hosts` |
| Web interface | http://localhost:8000 |
| Builder app | http://builder.localhost:8000/builder/ |

---

## Next Steps

After successful setup:

1. Log in with the default credentials
2. Change the Administrator password immediately
3. Explore the Frappe Builder interface
4. Review the created web pages and content
5. Start making your own changes
6. Create regular backups of your work

**Happy Building!**
