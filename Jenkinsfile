pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DEPLOY_HOST = '172.31.77.148'
        DEPLOY_USER = 'ubuntu'
        BUILD_DIR   = '/home/ubuntu/build-staging'
        LIVE_DIR    = '/home/ubuntu/projects/laravel/BookStack'
    }

    stages {
        stage('Build Stage') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            # --- FIX 1: PERMISSION CLEANUP ---
                            # We use 'sudo' here to force delete the folder even if
                            # permissions are locked or files are owned by root.
                            sudo rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            
                            git clone https://github.com/Jawadaziz78/django-project.git ${BUILD_DIR}
                            cd ${BUILD_DIR}
                            
                            TARGET_BRANCH="${BRANCH_NAME:-main}"
                            echo "Checking out branch: \$TARGET_BRANCH"
                            git checkout \$TARGET_BRANCH
                            
                            composer install --no-interaction --prefer-dist --optimize-autoloader
                            cp .env.example .env
                            php artisan key:generate --force
                            npm install
                            
                            # --- FIX 2: MEMORY LIMIT ---
                            # Prevents npm from running out of RAM and crashing the server
                            NODE_OPTIONS='--max-old-space-size=2048' npm run build
                            
                            echo '✅ BUILD STAGE SUCCESS'
                        "
                    '''
                }
            }
        }

        stage('Test Stage') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            cd ${BUILD_DIR}
                            export DB_CONNECTION=sqlite
                            export DB_DATABASE=:memory:
                            php artisan test tests/Unit
                            echo '✅ TEST STAGE SUCCESS'
                        "
                    '''
                }
            }
        }

        stage('Deploy Stage') {
            when {
                expression {
                    return env.BRANCH_NAME == 'main' || env.BRANCH_NAME == null
                }
            }
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            
                            # --- FIX 3: SAFETY CHECK ---
                            # If the build failed and 'public' is missing, STOP here.
                            # This prevents rsync from wiping your live site.
                            if [ ! -d "${BUILD_DIR}/public" ]; then
                                echo 'ERROR: Build directory is empty or invalid. Deployment stopped.'
                                exit 1
                            fi

                            echo '--- Starting Deployment ---'
                            rsync -av --delete \\
                                --exclude='.env' \\
                                --exclude='.git' \\
                                --exclude='storage' \\
                                --exclude='public/storage' \\
                                --exclude='node_modules' \\
                                ${BUILD_DIR}/ ${LIVE_DIR}/
                            
                            cd ${LIVE_DIR}
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
