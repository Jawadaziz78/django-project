pipeline {
    agent any

    // Trigger pipeline automatically on Git Push
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
                            rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            
                            git clone https://github.com/Jawadaziz78/django-project.git ${BUILD_DIR}
                            cd ${BUILD_DIR}
                            
                            # Ensure we build the correct branch being processed by Jenkins
                            git checkout ${BRANCH_NAME}
                            
                            composer install --no-interaction --prefer-dist --optimize-autoloader
                            
                            cp .env.example .env
                            php artisan key:generate --force
                            
                            npm install
                            npm run build
                            
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
                            
                            # Attempting to switch to SQLite using standard Environment Variables
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
            // --- SAFETY GUARD ---
            // This stage runs ONLY if the branch name is 'main'
            when {
                branch 'main'
            }
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            # 1. Sync files to Live Directory
                            # --exclude ensures we DO NOT delete your .env or storage folders
                            rsync -av --delete \\
                                --exclude='.env' \\
                                --exclude='.git' \\
                                --exclude='storage' \\
                                --exclude='public/storage' \\
                                --exclude='node_modules' \\
                                ${BUILD_DIR}/ ${LIVE_DIR}/
                            
                            # 2. Finalize Live Site
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
