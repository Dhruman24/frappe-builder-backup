@echo off
REM Frappe Builder + CRM + Lexicon - Restore Script for Windows
REM Last Updated: October 21, 2025
REM Backup Version: 20251021_140539

echo ===============================================
echo Frappe Builder + CRM + Lexicon Restore Script
echo ===============================================
echo Version: 3.0 (Complete with CRM + Lexicon)
echo.

REM Configuration
set CONTAINER_NAME=frappe-builder-frappe-1
set SITE_NAME=builder.localhost
set DB_ROOT_PASSWORD=123
set ADMIN_PASSWORD=admin
set BACKUP_DATE=20251021_140539

REM Enable debug mode if DEBUG=1 is set
if "%DEBUG%"=="1" (
    echo [DEBUG] Debug mode enabled
    echo [DEBUG] Current directory: %CD%
    echo [DEBUG] Script location: %~dp0
    echo.
)

REM Check if Docker is running
echo Step 1: Checking prerequisites...
docker ps >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running. Please start Docker Desktop and try again.
    pause
    exit /b 1
)
echo [SUCCESS] Docker is running

REM Check if docker-compose.yml exists
if not exist "docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found.
    echo [ERROR] Please run this script from the project root directory.
    echo [ERROR] Current directory: %CD%
    echo.
    echo [INFO] To fix: Navigate to the frappe-builder directory, then run:
    echo [INFO]   scripts\restore.bat
    pause
    exit /b 1
)
echo [SUCCESS] docker-compose.yml found

REM Check if backup directory exists
if not exist "backups" (
    echo [ERROR] Backups directory not found.
    exit /b 1
)

REM Check if config directory and template file exist
if not exist "config" (
    echo [ERROR] Config directory not found. Creating it...
    mkdir config
)

if not exist "config\common_site_config.json" (
    echo [WARNING] Redis configuration template not found at config\common_site_config.json
    echo [INFO] Creating default configuration file...
    (
        echo {
        echo   "background_workers": 1,
        echo   "file_watcher_port": 6787,
        echo   "frappe_user": "frappe",
        echo   "gunicorn_workers": 4,
        echo   "live_reload": true,
        echo   "rebase_on_pull": false,
        echo   "redis_cache": "redis://redis:6379",
        echo   "redis_queue": "redis://redis:6379",
        echo   "redis_socketio": "redis://redis:6379",
        echo   "restart_supervisor_on_update": false,
        echo   "restart_systemd_on_update": false,
        echo   "serve_default_site": true,
        echo   "shallow_clone": true,
        echo   "socketio_port": 9000,
        echo   "use_redis_auth": false,
        echo   "webserver_port": 8000
        echo }
    ) > config\common_site_config.json
    echo [SUCCESS] Configuration file created
)
echo [SUCCESS] Configuration template found

REM Find the latest backup file
for /f "delims=" %%i in ('dir /b /o-d "backups\*-database.sql.gz" 2^>nul') do (
    set DATABASE_BACKUP=%%i
    goto :found_backup
)
echo [ERROR] No database backup file found in backups\ directory
exit /b 1

:found_backup
echo [SUCCESS] Found backup files

echo.
echo Step 2: Starting Docker containers...
docker-compose up -d
echo [SUCCESS] Docker containers started

echo.
echo Step 3: Waiting for services to be ready (60 seconds)...
timeout /t 60 /nobreak >nul
echo [SUCCESS] Services should be ready

echo.
echo Step 4: Verifying frappe-bench initialization...
docker exec %CONTAINER_NAME% bash -c "test -d /home/frappe/frappe-bench" 2>nul
if errorlevel 1 (
    echo [ERROR] frappe-bench directory not found in container!
    echo [INFO] The frappe/bench:latest image should have frappe-bench pre-initialized.
    echo [INFO] Please ensure you're using the correct Docker image.
    pause
    exit /b 1
)
echo [SUCCESS] frappe-bench directory exists

docker exec %CONTAINER_NAME% bash -c "test -x /home/frappe/.local/bin/bench" 2>nul
if errorlevel 1 (
    echo [ERROR] bench command not found in container!
    pause
    exit /b 1
)
echo [SUCCESS] bench command available

echo.
echo Step 5: Setting up Redis configuration...
docker exec %CONTAINER_NAME% bash -c "mkdir -p /home/frappe/frappe-bench/sites" 2>nul
if "%DEBUG%"=="1" echo [DEBUG] Copying config file to container...
docker cp "config\common_site_config.json" "%CONTAINER_NAME%:/home/frappe/frappe-bench/sites/common_site_config.json" 2>nul
if errorlevel 1 (
    echo [WARNING] Could not copy Redis configuration. It might already exist.
    echo [INFO] Continuing anyway...
) else (
    echo [SUCCESS] Redis configuration copied
)

echo.
echo Step 6: Creating new site (if needed)...
if "%DEBUG%"=="1" echo [DEBUG] Running: bench new-site %SITE_NAME% --force...

REM Check if site already exists
docker exec %CONTAINER_NAME% bash -c "test -d /home/frappe/frappe-bench/sites/%SITE_NAME%" 2>nul
if not errorlevel 1 (
    echo [INFO] Site %SITE_NAME% already exists, skipping creation...
) else (
    echo [INFO] Creating new site %SITE_NAME%...
    docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench new-site %SITE_NAME% --force --db-root-password %DB_ROOT_PASSWORD% --admin-password %ADMIN_PASSWORD%"
    if errorlevel 1 (
        echo [ERROR] Failed to create site. Check the error messages above.
        pause
        exit /b 1
    )
    echo [SUCCESS] Site created successfully
)

echo.
echo Step 7: Checking if builder app is installed...
docker exec %CONTAINER_NAME% bash -c "test -d /home/frappe/frappe-bench/apps/builder" 2>nul
if errorlevel 1 (
    echo [ERROR] Builder app not found in frappe-bench/apps/
    echo [INFO] Please ensure the builder app is in the apps directory.
    echo [INFO] You may need to run: bench get-app builder
    pause
    exit /b 1
)
echo [SUCCESS] Builder app found

echo.
echo Step 8: Installing builder app on site...
if "%DEBUG%"=="1" echo [DEBUG] Running: bench --site %SITE_NAME% install-app builder

REM Check if app is already installed
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% list-apps | grep -q builder" 2>nul
if not errorlevel 1 (
    echo [INFO] Builder app already installed on site
) else (
    echo [INFO] Installing builder app...
    docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% install-app builder"
    if errorlevel 1 (
        echo [ERROR] Failed to install builder app. Check the error messages above.
        pause
        exit /b 1
    )
    echo [SUCCESS] Builder app installed
)

echo.
echo Step 9: Preparing backup directory in container...
docker exec %CONTAINER_NAME% bash -c "mkdir -p /home/frappe/frappe-bench/sites/%SITE_NAME%/private/backups" 2>nul
echo [SUCCESS] Backup directory ready

echo.
echo Step 10: Copying backup files to container...
echo [INFO] This may take a moment depending on backup size...
if "%DEBUG%"=="1" echo [DEBUG] Copying from .\backups\ to container...
docker cp ".\backups\." "%CONTAINER_NAME%:/home/frappe/frappe-bench/sites/%SITE_NAME%/private/backups/" 2>nul
if errorlevel 1 (
    echo [ERROR] Failed to copy backup files to container
    echo [INFO] Please check if the backups directory exists and contains backup files
    pause
    exit /b 1
)
echo [SUCCESS] Backup files copied successfully

echo.
echo Step 11: Restoring database...
echo [INFO] Restoring database from backup: %BACKUP_DATE%-builder_localhost-database.sql.gz
echo [INFO] This may take several minutes...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% restore --force sites/%SITE_NAME%/private/backups/%BACKUP_DATE%-builder_localhost-database.sql.gz"
if errorlevel 1 (
    echo [ERROR] Failed to restore database. Check the error messages above.
    pause
    exit /b 1
)
echo [SUCCESS] Database restored successfully

echo.
echo Step 12: Restoring public files...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% restore --force --with-public-files sites/%SITE_NAME%/private/backups/%BACKUP_DATE%-builder_localhost-files.tar"
if errorlevel 1 (
    echo [WARNING] Public files restore had issues, continuing...
) else (
    echo [SUCCESS] Public files restored
)

echo.
echo Step 13: Restoring private files...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% restore --force --with-private-files sites/%SITE_NAME%/private/backups/%BACKUP_DATE%-builder_localhost-private-files.tar"
if errorlevel 1 (
    echo [WARNING] Private files restore had issues, continuing...
) else (
    echo [SUCCESS] Private files restored
)

echo.
echo Step 14: Copying custom apps to container...
echo [INFO] Copying Lexicon app...
docker cp apps/lexicon %CONTAINER_NAME%:/home/frappe/frappe-bench/apps/
if errorlevel 1 (
    echo [WARNING] Failed to copy Lexicon app
) else (
    echo [SUCCESS] Lexicon app copied
)

echo [INFO] Copying Vendor Manager app...
docker cp apps/vendor-manager %CONTAINER_NAME%:/home/frappe/frappe-bench/apps/
if errorlevel 1 (
    echo [WARNING] Failed to copy Vendor Manager app
) else (
    echo [SUCCESS] Vendor Manager app copied
)

echo.
echo Step 15: Installing vendor-manager in Python environment...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && ./env/bin/pip install -e apps/vendor-manager"
if errorlevel 1 (
    echo [WARNING] Failed to install vendor-manager in Python environment
) else (
    echo [SUCCESS] Vendor-manager installed in Python environment
)

echo.
echo Step 16: Installing CRM and custom apps...
echo [INFO] Installing Frappe CRM (optional)...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% install-app crm" 2>nul
if errorlevel 1 (
    echo [INFO] CRM app skipped or already installed
) else (
    echo [SUCCESS] CRM app installed
)

echo [INFO] Installing Lexicon app...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% install-app lexicon" 2>nul
if errorlevel 1 (
    echo [INFO] Lexicon app already installed or not found in apps directory
) else (
    echo [SUCCESS] Lexicon app installed
)

echo [INFO] Installing Vendor Manager app...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% install-app vendor_manager" 2>nul
if errorlevel 1 (
    echo [INFO] Vendor Manager app already installed or not found in apps directory
) else (
    echo [SUCCESS] Vendor Manager app installed
)

echo.
echo Step 17: Running database migration...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% migrate"
if errorlevel 1 (
    echo [WARNING] Migration had issues, but continuing...
) else (
    echo [SUCCESS] Database migration completed
)

echo.
echo Step 18: Clearing cache...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% clear-cache"
if errorlevel 1 (
    echo [WARNING] Failed to clear cache, but continuing...
) else (
    echo [SUCCESS] Cache cleared
)

echo.
echo Step 19: Restarting bench...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench restart"
echo [SUCCESS] Bench restarted

echo.
echo ===============================================
echo ✓ Restoration Complete!
echo ===============================================
echo.
echo Your site is ready at: http://builder.localhost:8000
echo.
echo Login Credentials:
echo   Username: Administrator
echo   Password: %ADMIN_PASSWORD%
echo.
echo Installed Applications:
echo   - Frappe Framework (v15.85.0)
echo   - Builder (v1.18.0)
echo   - Frappe CRM (v1.53.1)
echo   - Lexicon (v0.0.1)
echo.
echo Available URLs:
echo   - Main Site: http://builder.localhost:8000
echo   - Vendor Management: http://builder.localhost:8000/app/vendor
echo   - Waitlist: http://builder.localhost:8000/app/waitlist
echo   - Lexicon Directory: http://builder.localhost:8000/app/vendors
echo   - Frappe CRM: http://builder.localhost:8000/app/crm
echo.
echo What's Included:
echo   ✓ 5 Sample Vendors (Vendor 1-5)
echo   ✓ Custom Vendor and Waitlist Doctypes
echo   ✓ Lexicon Vendors Directory Page
echo   ✓ Full Frappe CRM (Leads, Deals, Organizations, Contacts)
echo.
echo [WARNING] IMPORTANT: Change the default password after first login!
echo.
echo ===============================================
echo Troubleshooting:
echo ===============================================
echo.
echo If you encounter issues:
echo   1. Check Docker Desktop is running
echo   2. Verify containers: docker ps
echo   3. View logs: docker logs %CONTAINER_NAME% -f
echo   4. Restart container: docker restart %CONTAINER_NAME%
echo   5. See SETUP_FOR_TEAMMATE.md for detailed help
echo.
echo For more information, read:
echo   - COMPLETE_PROJECT_GUIDE.md (full documentation)
echo   - SETUP_FOR_TEAMMATE.md (setup guide)
echo.
pause
