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
                            sudo rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            
                            git clone https://github.com/Jawadaziz78/django-project.git ${BUILD_DIR}
                            cd ${BUILD_DIR}
                            
                            TARGET_BRANCH="${BRANCH_NAME:-main}"
                            echo "Checking out branch: \$TARGET_BRANCH"
                            git checkout \$TARGET_BRANCH
                            
                            # --- REMOVED DEPENDENCIES ---
                            # Composer (Backend) and NPM (Frontend) commands removed as requested.
                            # Note: You must ensure 'vendor' and 'public/dist' exist on the live server manually.
                            
                            echo '✅ BUILD STAGE SUCCESS'
                        "
                    '''
                }
            }
        }

        # --- REMOVED TEST STAGE ---

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
                                --exclude='vendor' \\
                                --exclude='public/dist' \\
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
