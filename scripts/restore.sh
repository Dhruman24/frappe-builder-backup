#!/bin/bash

# Frappe Builder - Automated Restore Script
# This script automates the process of restoring the Frappe Builder site

set -e  # Exit on any error

echo "================================================"
echo "Frappe Builder - Automated Restore Script"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="frappe-builder-frappe-1"
SITE_NAME="builder.localhost"
DB_ROOT_PASSWORD="root"
ADMIN_PASSWORD="admin"

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if Docker is running
echo "Step 1: Checking prerequisites..."
if ! docker ps > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi
print_success "Docker is running"

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found. Please run this script from the project root."
    exit 1
fi
print_success "docker-compose.yml found"

# Check if backup directory exists
if [ ! -d "backups" ]; then
    print_error "Backups directory not found."
    exit 1
fi

# Find the latest backup files
DATABASE_BACKUP=$(ls -t backups/*-database.sql.gz 2>/dev/null | head -1)
if [ -z "$DATABASE_BACKUP" ]; then
    print_error "No database backup file found in backups/ directory"
    exit 1
fi
print_success "Found backup files"

echo ""
echo "Step 2: Starting Docker containers..."
docker-compose up -d
print_success "Docker containers started"

echo ""
echo "Step 3: Waiting for services to be ready (60 seconds)..."
sleep 60
print_success "Services should be ready"

echo ""
echo "Step 4: Checking if site already exists..."
if docker exec $CONTAINER_NAME bash -c "cd frappe-bench && [ -d sites/$SITE_NAME ]" 2>/dev/null; then
    print_warning "Site $SITE_NAME already exists. Skipping site creation."
else
    echo "Creating new site..."
    docker exec $CONTAINER_NAME bash -c "cd frappe-bench && bench new-site $SITE_NAME --force --db-root-password $DB_ROOT_PASSWORD --admin-password $ADMIN_PASSWORD"
    print_success "Site created"

    echo ""
    echo "Step 5: Installing builder app..."
    docker exec $CONTAINER_NAME bash -c "cd frappe-bench && bench --site $SITE_NAME install-app builder"
    print_success "Builder app installed"
fi

echo ""
echo "Step 6: Copying backup files to container..."
docker cp ./backups/. $CONTAINER_NAME:/home/frappe/frappe-bench/sites/$SITE_NAME/private/backups/
print_success "Backup files copied"

echo ""
echo "Step 7: Restoring database and files..."
BACKUP_FILENAME=$(basename "$DATABASE_BACKUP")
docker exec $CONTAINER_NAME bash -c "cd frappe-bench && bench --site $SITE_NAME restore --force --with-public-files --with-private-files sites/$SITE_NAME/private/backups/$BACKUP_FILENAME"
print_success "Backup restored"

echo ""
echo "Step 8: Clearing cache..."
docker exec $CONTAINER_NAME bash -c "cd frappe-bench && bench --site $SITE_NAME clear-cache"
print_success "Cache cleared"

echo ""
echo "Step 9: Setting up site for access..."
docker exec $CONTAINER_NAME bash -c "cd frappe-bench && bench use $SITE_NAME"
print_success "Site configured"

echo ""
echo "================================================"
echo "✓ Restoration Complete!"
echo "================================================"
echo ""
echo "To start the Frappe development server:"
echo "  1. Run: docker exec -it $CONTAINER_NAME bash"
echo "  2. Run: cd frappe-bench"
echo "  3. Run: bench start"
echo ""
echo "Then access your site at: http://localhost:8000"
echo ""
echo "Login Credentials:"
echo "  Username: Administrator"
echo "  Password: $ADMIN_PASSWORD"
echo ""
print_warning "IMPORTANT: Change the default password after first login!"
echo ""
