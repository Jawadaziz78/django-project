pipeline {
    agent any

    environment {
        DEPLOY_HOST = '172.31.77.148' 
        DEPLOY_USER = 'ubuntu'
        BUILD_DIR = '/home/ubuntu/build-staging' 
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
                            php artisan config:clear
                            
                            # --- FIX: Match the EXACT string with quotes ---
                            sed -i 's/value=\"mysql_testing\"/value=\"sqlite\"/g' phpunit.xml
                            
                            # Create dummy database file
                            touch database/database.sqlite
                            
                            echo '--- Running Smoke Tests ---'
                            # Force environment variables inline to override everything else
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
                            
                            # Sync files but PROTECT the live .env and storage
                            rsync -av --delete \\
                                --exclude='.env' \\
                                --exclude='.git' \\
                                --exclude='storage' \\
                                --exclude='public/storage' \\
                                --exclude='node_modules' \\
                                ${BUILD_DIR}/ ${LIVE_DIR}/
                            
                            cd ${LIVE_DIR}
                            
                            echo '--- Finalizing Deployment ---'
                            php artisan migrate --force
                            php artisan config:cache
                            php artisan route:cache
                            php artisan view:cache
                            sudo systemctl reload nginx
                            
                            echo '✅ DEPLOYMENT SUCCESSFUL'
                        "
                    '''
                }
            }
        }
    }
}
