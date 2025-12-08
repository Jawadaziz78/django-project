pipeline {
    agent any

    environment {
        DEPLOY_HOST = '172.31.77.148' 
        DEPLOY_USER = 'ubuntu'
        BUILD_DIR = '/home/ubuntu/build-staging'
        
        // ADDED: The path to your actual live website
        LIVE_DIR = '/home/ubuntu/projects/laravel/BookStack'
    }

    stages {
        // --- STAGE 1: BUILD (Your Code - Untouched) ---
        stage('Remote Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            # Build steps remain the same...
                            rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            git clone https://github.com/Jawadaziz78/django-project.git ${BUILD_DIR}
                            cd ${BUILD_DIR}
                            composer install --no-interaction --prefer-dist --optimize-autoloader
                            cp .env.example .env
                            php artisan key:generate --force
                            npm install
                            npm run build
                        "
                    '''
                }
            }
        }

        // --- STAGE 2: TEST (Your Code - Untouched) ---
        stage('Remote Smoke Test') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            cd ${BUILD_DIR}
                            
                            echo '--- Running LIMITED PHP Tests (Unit Only) ---'
                            export DB_CONNECTION=sqlite
                            export DB_DATABASE=:memory:
                            
                            # LIMIT 1: Run only the 'tests/Unit' folder (Very fast)
                            # If this folder is empty in your repo, change it to --filter ExampleTest
                            php artisan test tests/Unit
                            
                            echo '--- Skipping JS Tests for Speed ---'
                            # To run JS tests later, uncomment the line below:
                            # export CI=true && npm run test -- --ci --bail
                        "
                    '''
                }
            }
        }

        // --- STAGE 3: DEPLOY (New Addition) ---
        stage('Remote Deploy') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            echo '--- Starting Safe Deployment ---'
                            
                            # 1. Sync Files from Staging to Live
                            # rsync moves the built files to your live folder.
                            # --delete: Removes old PHP files you deleted from the code.
                            # --exclude: CRITICAL! These protect your live data from being wiped.
                            
                            rsync -av --delete \\
                                --exclude='.env' \\
                                --exclude='.git' \\
                                --exclude='storage' \\
                                --exclude='public/storage' \\
                                --exclude='node_modules' \\
                                ${BUILD_DIR}/ ${LIVE_DIR}/
                            
                            # 2. Enter Live Directory to finalize
                            cd ${LIVE_DIR}
                            
                            echo '--- Running Database Migrations ---'
                            # Updates the database schema without data loss
                            php artisan migrate --force
                            
                            echo '--- Optimizing Caches ---'
                            php artisan config:cache
                            php artisan route:cache
                            php artisan view:cache
                            
                            echo '--- Reloading Web Server ---'
                            # Restarts Nginx to serve the new code
                            sudo systemctl reload nginx
                            
                            echo '✅ DEPLOYMENT SUCCESSFUL'
                        "
                    '''
                }
            }
        }
    }
}
