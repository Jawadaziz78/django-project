pipeline {
    agent any

    environment {
        // --- CONFIGURATION ---
        // 1. Your Server Details
        DEPLOY_HOST = '172.31.77.148' 
        DEPLOY_USER = 'ubuntu'
        
        // 2. The Temporary Staging Folder (Where we build safely)
        BUILD_DIR = '/home/ubuntu/build-staging'
        
        // 3. Your REAL Live Website Folder
        // This is the path you confirmed you want to update safely
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
                            
                            # 4. Environment Setup (For Build Only)
                            cp .env.example .env
                            # --force prevents the 'Application In Production' interactive prompt error
                            php artisan key:generate --force
                            
                            # 5. Frontend Build
                            npm install
                            npm run build
                        "
                    '''
                }
            }
        }

        // --- STAGE 2: TEST ---
        stage('Remote Smoke Test') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            cd ${BUILD_DIR}
                            echo '--- Running Smoke Tests (Unit Only) ---'
                            # Use In-Memory Database to avoid touching Real DB
                            export DB_CONNECTION=sqlite
                            export DB_DATABASE=:memory:
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
                            # --exclude '.env': KEEPS your live database passwords safe
                            # --exclude 'storage': KEEPS your user uploads/logs safe
                            # --delete: Removes old code files you deleted from GitHub
                            
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
