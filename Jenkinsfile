pipeline {
    agent any

    environment {
        // --- CONFIGURATION ---
        DEPLOY_HOST = '172.31.77.148' 
        DEPLOY_USER = 'ubuntu'
        
        // Staging Folder (Temporary Build Area)
        BUILD_DIR = '/home/ubuntu/build-staging'
        
        // Live Website Folder (Production)
        LIVE_DIR  = '/home/ubuntu/projects/laravel/BookStack'
    }

    stages {
        // --- STAGE 1: BUILD (Unchanged & Working) ---
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
                            
                            echo '--- 1. Clearing Config Cache ---'
                            php artisan config:clear
                            
                            echo '--- 2. Forcing SQLite in Configuration ---'
                            # We use sed to physically rewrite the config files to point to SQLite
                            # This fixes the 'mysql_testing' error you saw in the logs
                            
                            # Update phpunit.xml (The root cause)
                            sed -i 's/value=\"mysql_testing\"/value=\"sqlite\"/g' phpunit.xml
                            
                            # Update .env (Just in case)
                            sed -i 's/DB_CONNECTION=mysql/DB_CONNECTION=sqlite/g' .env
                            
                            # Create the database file locally (required as a fallback)
                            touch database/database.sqlite
                            
                            echo '--- 3. Running Smoke Tests (Unit Only) ---'
                            # We pass env vars INLINE to guarantee they override everything else
                            DB_CONNECTION=sqlite DB_DATABASE=:memory: php artisan test tests/Unit
                        "
                    '''
                }
            }
        }

        // --- STAGE 3: DEPLOY (SAFE MODE) ---
        stage('Remote Deploy') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            echo '--- Starting Safe Deployment ---'
                            
                            # 1. Sync Files from Staging to Live
                            # --delete: Removes old code files (keeps folders clean)
                            # --exclude: PROTECTS your live .env and user uploads (storage)
                            
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
