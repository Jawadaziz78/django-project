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
    echo "🐘 Running Laravel Deployment Steps..."
    
    # Install dependencies FIRST
    composer install --no-dev --optimize-autoloader

    # Automated .env and Key Handling
    if [ ! -f ".env" ]; then
        echo "Creating .env from template..."
        cp .env.example .env
        sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
        sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
        sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
        sed -i "s|APP_URL=.*|APP_URL=https://demo2.flowsoftware.ky/laravel/$BRANCH/|" .env
        
        # Generate the application key
        php artisan key:generate --force
    fi
    
    # Optimization & Caching
    echo "Optimizing application..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    
    # Permissions and Migrations
    sudo chmod -R 775 storage bootstrap/cache
    sudo chgrp -R www-data storage bootstrap/cache
    
    if [ -f "artisan" ]; then
        php artisan migrate --force
    fi

elif [ "$PROJECT_TYPE" == "vue" ]; then
    # ... Vue steps remain as previously configured
    pnpm install --ignore-scripts 
    pnpm rebuild esbuild
fi

sudo chown -R ubuntu:www-data "$LIVE_DIR"
echo "--- ✅ Deployment Successfully Completed ---"
