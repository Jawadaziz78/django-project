#!/bin/bash
set -e

# Arguments passed from Jenkins
BRANCH=$1
PROJECT_TYPE=$2
GIT_USER=$3
GIT_PASS=$4

# Database details matching your master_setup.sh
DB_NAME="laravel_stage_db"
DB_USER="laravel_user"
DB_PASS="SecurePassword123"

REPO_URL="https://$GIT_USER:$GIT_PASS@github.com/Jawadaziz78/django-project.git"
LIVE_DIR="/var/www/html/$BRANCH/$PROJECT_TYPE-project"

echo "--- 🛠️ Preparing Project: $BRANCH ($PROJECT_TYPE) ---"

# 1. Self-Healing Folder Setup
if [ ! -d "$LIVE_DIR/.git" ]; then
    echo "⚠️ Initializing fresh directory for $BRANCH..."
    sudo rm -rf "$LIVE_DIR"
    sudo mkdir -p $(dirname "$LIVE_DIR")
    sudo git clone -b "$BRANCH" "$REPO_URL" "$LIVE_DIR"
fi

cd "$LIVE_DIR"
sudo chown -R ubuntu:ubuntu .

# 2. Project-Specific Setup
if [ "$PROJECT_TYPE" == "laravel" ]; then
    echo "🐘 Running Laravel Pre-Deployment Steps..."
    
    # --- STEP A: Install dependencies FIRST ---
    # This creates the vendor/ folder required for artisan commands
    composer install --no-dev --optimize-autoloader

    # --- STEP B: Automated .env Handling ---
    if [ ! -f ".env" ]; then
        echo "Creating .env from template..."
        cp .env.example .env
        sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
        sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
        sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
        sed -i "s|APP_URL=.*|APP_URL=https://demo2.flowsoftware.ky/laravel/$BRANCH/|" .env
        
        # Now this will work because 'vendor' exists
        php artisan key:generate
    fi
    
    # Deep Permission Fixes
    sudo chmod -R 775 storage bootstrap/cache
    sudo chgrp -R www-data storage bootstrap/cache
    
    # Run Database Migrations
    if [ -f "artisan" ]; then
        echo "Running Database Migrations..."
        php artisan migrate --force
    fi

elif [ "$PROJECT_TYPE" == "vue" ]; then
    # ... (Vue logic remains the same)
    pnpm install --ignore-scripts 
    sudo find node_modules/.pnpm -name 'esbuild' -exec chmod +x {} +
    sudo chmod -R +x node_modules/.bin
    pnpm rebuild esbuild
fi

# 3. Final Permissions for Nginx
sudo chown -R ubuntu:www-data "$LIVE_DIR"

echo "--- ✅ Prep Complete ---"
