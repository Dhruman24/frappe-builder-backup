@echo off
REM Configure Auth0 for Frappe Builder Site
REM This script adds Auth0 credentials to your site configuration

echo ===============================================
echo Auth0 Configuration Script
echo ===============================================
echo.

set CONTAINER_NAME=frappe-builder-frappe-1
set SITE_NAME=builder.localhost

echo Checking if container is running...
docker ps | findstr %CONTAINER_NAME% >nul
if errorlevel 1 (
    echo [ERROR] Container %CONTAINER_NAME% is not running
    echo Please start the container with: docker-compose up -d
    pause
    exit /b 1
)
echo [SUCCESS] Container is running
echo.

echo Step 1: Backing up current site configuration...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench/sites/%SITE_NAME% && cp site_config.json site_config.json.backup.%date:~-4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
if errorlevel 1 (
    echo [WARNING] Failed to create backup, but continuing...
) else (
    echo [SUCCESS] Backup created
)
echo.

echo Step 2: Adding Auth0 configuration to site_config.json...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench/sites/%SITE_NAME% && python3 << 'PYTHON_SCRIPT'
import json

# Read existing config
with open('site_config.json', 'r') as f:
    config = json.load(f)

# Add Auth0 configuration
config['auth0_domain'] = 'dev-wzk02vz8kiqth37j.us.auth0.com'
config['auth0_lexicon_client_id'] = 'FZ91BA10wLaWskSsmBylYOSmBgnHHOsx'
config['auth0_lexicon_client_secret'] = 'sS-g1Kexyqbm09IIybJaoIrZF4HspnlzYm837GSf3FAW5HI7KPsb3KmHbwtmsmJO'
config['auth0_crm_client_id'] = 'RqpVD4Gb406cLbycNfVyK6yvf5jTiZoC'
config['auth0_crm_client_secret'] = 'eOxy9FTOBbxXSGefbxoUesindoDPQnqCEBfQyJm-liamfTyyU0Q7y8r-4EcgSYly'

# Write updated config
with open('site_config.json', 'w') as f:
    json.dump(config, f, indent=2)

print('[SUCCESS] Auth0 configuration added')
PYTHON_SCRIPT"

if errorlevel 1 (
    echo [ERROR] Failed to update site configuration
    pause
    exit /b 1
)
echo.

echo Step 3: Restarting Frappe to apply changes...
docker exec %CONTAINER_NAME% bash -c "cd /home/frappe/frappe-bench && bench restart"
if errorlevel 1 (
    echo [WARNING] Bench restart had issues, trying container restart...
    docker restart %CONTAINER_NAME%
    echo [INFO] Waiting for container to restart (30 seconds)...
    timeout /t 30 /nobreak >nul
)
echo [SUCCESS] Frappe restarted
echo.

echo ===============================================
echo ✓ Auth0 Configuration Complete!
echo ===============================================
echo.
echo Next steps:
echo.
echo 1. Update Auth0 Callback URLs:
echo    - Go to: https://manage.auth0.com/dashboard/
echo.
echo 2. For LEXICON app, set:
echo    Allowed Callback URLs:
echo      http://builder.localhost:8000/api/method/lexicon.lexicon.auth.oauth.lexicon_callback
echo.
echo 3. For CRM app, set:
echo    Allowed Callback URLs:
echo      http://builder.localhost:8000/api/method/crm.auth.oauth.crm_callback
echo.
echo 4. Test Login:
echo    - Lexicon: http://builder.localhost:8000/lexicon_login
echo    - CRM: http://builder.localhost:8000/crm_login
echo.
echo ===============================================
pause
