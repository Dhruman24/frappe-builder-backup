@echo off
REM Frappe Builder - Automated Restore Script for Windows
REM This script automates the process of restoring the Frappe Builder site

echo ================================================
echo Frappe Builder - Automated Restore Script
echo ================================================
echo Version: 2.0 (Enhanced)
echo.

REM Configuration
set CONTAINER_NAME=frappe-builder-frappe-1
set SITE_NAME=builder.localhost
set DB_ROOT_PASSWORD=root
set ADMIN_PASSWORD=admin

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
echo Step 11: Restoring database and files...
echo [INFO] Restoring from backup: %DATABASE_BACKUP%
echo [INFO] This may take several minutes...
if "%DEBUG%"=="1" echo [DEBUG] Running: bench --site %SITE_NAME% restore...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% restore --force --with-public-files --with-private-files sites/%SITE_NAME%/private/backups/%DATABASE_BACKUP%"
if errorlevel 1 (
    echo [ERROR] Failed to restore backup. Check the error messages above.
    pause
    exit /b 1
)
echo [SUCCESS] Backup restored successfully

echo.
echo Step 12: Clearing cache...
if "%DEBUG%"=="1" echo [DEBUG] Running: bench --site %SITE_NAME% clear-cache
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench --site %SITE_NAME% clear-cache"
if errorlevel 1 (
    echo [WARNING] Failed to clear cache, but continuing...
) else (
    echo [SUCCESS] Cache cleared
)

echo.
echo Step 13: Setting up site for access...
if "%DEBUG%"=="1" echo [DEBUG] Running: bench use %SITE_NAME%
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench use %SITE_NAME%"
if errorlevel 1 (
    echo [WARNING] Failed to set default site, but continuing...
) else (
    echo [SUCCESS] Site configured as default
)

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
echo ================================================
echo Troubleshooting Tips:
echo ================================================
echo.
echo If you encounter errors:
echo   1. Make sure Docker Desktop is running
echo   2. Run from the project root directory (not scripts/)
echo   3. Check that backups\ directory contains backup files
echo   4. Enable debug mode: set DEBUG=1 ^&^& scripts\restore.bat
echo   5. Check container logs: docker logs %CONTAINER_NAME%
echo.
echo For common issues:
echo   - "bench not found": Container might not be properly initialized
echo   - "No such option --site": Wrong directory or bench version issue
echo   - "Permission denied": Docker may need admin privileges
echo.
pause
