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
                            
                            echo '--- preparing Test Configuration ---'
                            # 1. Clear any cached config that might point to MySQL
                            php artisan config:clear
                            
                            # 2. FORCE 'phpunit.xml' to use SQLite
                            # We use 'sed' to replace the hardcoded MySQL values in the file.
                            # This overrides any <server name='DB_CONNECTION' value='mysql'/> tags.
                            sed -i 's/name=\"DB_CONNECTION\" value=\".*\"/name=\"DB_CONNECTION\" value=\"sqlite\"/' phpunit.xml
                            sed -i 's/name=\"DB_DATABASE\" value=\".*\"/name=\"DB_DATABASE\" value=\":memory:\"/' phpunit.xml
                            
                            echo '--- Running Smoke Tests (Unit Only) ---'
                            php artisan test tests/Unit
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
                            # Protections: Exclude .env, storage, and node_modules to be safe
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
