@echo off
REM Frappe Builder - Automated Restore Script for Windows
REM This script automates the process of restoring the Frappe Builder site

echo ================================================
echo Frappe Builder - Automated Restore Script
echo ================================================
echo.

REM Configuration
set CONTAINER_NAME=frappe-builder-frappe-1
set SITE_NAME=builder.localhost
set DB_ROOT_PASSWORD=root
set ADMIN_PASSWORD=admin

REM Check if Docker is running
echo Step 1: Checking prerequisites...
docker ps >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running. Please start Docker Desktop and try again.
    exit /b 1
)
echo [SUCCESS] Docker is running

REM Check if docker-compose.yml exists
if not exist "docker-compose.yml" (
    echo [ERROR] docker-compose.yml not found. Please run this script from the project root.
    exit /b 1
)
echo [SUCCESS] docker-compose.yml found

REM Check if backup directory exists
if not exist "backups" (
    echo [ERROR] Backups directory not found.
    exit /b 1
)

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
echo Step 4: Setting up Redis configuration...
docker exec %CONTAINER_NAME% bash -c "mkdir -p /home/frappe/frappe-bench/sites && cat > /home/frappe/frappe-bench/sites/common_site_config.json << 'EOF'
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
echo [SUCCESS] Redis configuration created

echo.
echo Step 5: Creating new site (if needed)...
docker exec %CONTAINER_NAME% bash -c "cd frappe-bench && bench new-site %SITE_NAME% --force --db-root-password %DB_ROOT_PASSWORD% --admin-password %ADMIN_PASSWORD%" 2>nul
if errorlevel 1 (
    echo [WARNING] Site might already exist, continuing...
) else (
    echo [SUCCESS] Site created
)

echo.
echo Step 6: Installing builder app...
docker exec %CONTAINER_NAME% bash -c "cd frappe-bench && bench --site %SITE_NAME% install-app builder"
echo [SUCCESS] Builder app installed

echo.
echo Step 7: Copying backup files to container...
docker cp ".\backups\." "%CONTAINER_NAME%:/home/frappe/frappe-bench/sites/%SITE_NAME%/private/backups/"
echo [SUCCESS] Backup files copied

echo.
echo Step 8: Restoring database and files...
docker exec %CONTAINER_NAME% bash -c "cd frappe-bench && bench --site %SITE_NAME% restore --force --with-public-files --with-private-files sites/%SITE_NAME%/private/backups/%DATABASE_BACKUP%"
echo [SUCCESS] Backup restored

echo.
echo Step 9: Clearing cache...
docker exec %CONTAINER_NAME% bash -c "cd frappe-bench && bench --site %SITE_NAME% clear-cache"
echo [SUCCESS] Cache cleared

echo.
echo Step 10: Setting up site for access...
docker exec %CONTAINER_NAME% bash -c "cd frappe-bench && bench use %SITE_NAME%"
echo [SUCCESS] Site configured

echo.
echo ================================================
echo Restoration Complete!
echo ================================================
echo.
echo To start the Frappe development server:
echo   1. Run: docker exec -it %CONTAINER_NAME% bash
echo   2. Run: cd frappe-bench
echo   3. Run: bench start
echo.
echo Then access your site at: http://localhost:8000
echo.
echo Login Credentials:
echo   Username: Administrator
echo   Password: %ADMIN_PASSWORD%
echo.
echo [WARNING] IMPORTANT: Change the default password after first login!
echo.
pause
