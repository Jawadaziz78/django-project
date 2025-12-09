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
                            # --- FIX: PERMISSION CLEANUP ---
                            # Uses sudo to ensure we can delete the folder even if permissions are locked
                            sudo rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            
                            git clone https://github.com/Jawadaziz78/django-project.git ${BUILD_DIR}
                            cd ${BUILD_DIR}
                            
                            # Checks out the branch that triggered the pipeline (main, development, or test)
                            TARGET_BRANCH="${BRANCH_NAME:-main}"
                            echo "Checking out branch: \$TARGET_BRANCH"
                            git checkout \$TARGET_BRANCH
                            
                            # Note: Composer and NPM commands are REMOVED as requested.
                            # We assume 'vendor' and 'public/dist' already exist on the live server.
                            
                            echo '✅ BUILD STAGE SUCCESS'
                        "
                    '''
                }
            }
        }

        stage('Deploy Stage') {
            when {
                expression {
                    // Logic: Allow deployment if the branch is main, development, OR test
                    return env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'development' || env.BRANCH_NAME == 'test'
                }
            }
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            
                            # --- SAFETY CHECK ---
                            # If the build failed or the folder structure is wrong, STOP.
                            if [ ! -d "${BUILD_DIR}/public" ]; then
                                echo 'ERROR: Build directory is empty or invalid. Deployment stopped.'
                                exit 1
                            fi

                            echo '--- Starting Deployment ---'
                            echo "Deploying branch: ${BRANCH_NAME}"
                            
                            # --- RSYNC WITH EXCLUDES ---
                            # We exclude 'vendor' and 'public/dist' so they are NOT deleted from the live server
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
