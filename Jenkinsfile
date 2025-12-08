pipeline {
    agent any

    environment {
        // --- CONFIGURATION ---
        DEPLOY_HOST = '172.31.77.148' 
        DEPLOY_USER = 'ubuntu'
        
        // Staging Folder
        BUILD_DIR = '/home/ubuntu/build-staging'
        
        // Live Website Folder
        LIVE_DIR  = '/home/ubuntu/projects/laravel/BookStack'
    }

    stages {
        // --- STAGE 1: BUILD ---
        stage('Remote Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            # 1. Clean Staging Area
                            rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            
                            # 2. Clone Repository
                            git clone https://github.com/Jawadaziz78/django-project.git ${BUILD_DIR}
                            cd ${BUILD_DIR}
                            
                            # 3. Backend Dependencies
                            composer install --no-interaction --prefer-dist --optimize-autoloader
                            
                            # 4. Environment Setup
                            cp .env.example .env
                            # --force prevents interactive prompts
                            php artisan key:generate --force
                            
                            # 5. Frontend Build
                            npm install
                            npm run build
                        "
                    '''
                }
            }
        }

        // --- STAGE 2: TEST (FIXED) ---
        stage('Remote Smoke Test') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            cd ${BUILD_DIR}
                            
                            echo '--- Configuring SQLite for Testing ---'
                            
                            # 1. Clear Config Cache first
                            php artisan config:clear
                            
                            # 2. PRECISE FIX: Replace 'mysql_testing' with 'sqlite' in phpunit.xml
                            # We use the exact string found in your file content
                            sed -i 's/value=\"mysql_testing\"/value=\"sqlite\"/g' phpunit.xml
                            
                            # 3. Create a fallback sqlite file (required by some setups)
                            touch database/database.sqlite
                            
                            # 4. Run Tests with explicit inline ENV variables
                            # This overrides any remaining settings to ensure :memory: is used
                            echo '--- Running Smoke Tests ---'
                            DB_CONNECTION=sqlite DB_DATABASE=:memory: php artisan test tests/Unit
                        "
                    '''
                }
            }
        }

        // --- STAGE 3: DEPLOY ---
        stage('Remote Deploy') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            echo '--- Starting Safe Deployment ---'
                            
                            # 1. Sync Files from Staging to Live
                            # Excludes .env and storage to protect your live data
                            rsync -av --delete \\
                                --exclude='.env' \\
                                --exclude='.git' \\
                                --exclude='storage' \\
                                --exclude='public/storage' \\
                                --exclude='node_modules' \\
                                ${BUILD_DIR}/ ${LIVE_DIR}/
                            
                            # 2. Finalize Live Site
                            cd ${LIVE_DIR}
                            
                            echo '--- Updating Database Schema ---'
                            php artisan migrate --force
                            
                            echo '--- Clearing Caches ---'
                            php artisan config:cache
                            php artisan route:cache
                            php artisan view:cache
                            
                            echo '--- Reloading Web Server ---'
                            sudo systemctl reload nginx
                            
                            echo '✅ DEPLOYMENT SUCCESSFUL'
                        "
                    '''
                }
            }
        }
    }
}
