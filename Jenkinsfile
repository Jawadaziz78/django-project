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
                            sudo rm -rf ${BUILD_DIR} 
                            mkdir -p ${BUILD_DIR} 
                             
                            git clone https://github.com/Jawadaziz78/django-project.git ${BUILD_DIR} 
                            cd ${BUILD_DIR} 
                             
                            TARGET_BRANCH=\"${BRANCH_NAME:-main}\" 
                            git checkout \\$TARGET_BRANCH 
                             
                            echo '✅ BUILD STAGE SUCCESS' 
                        " 
                    ''' 
                } 
            } 
        } 
 
        stage('Test Stage') { 
            steps { 
                echo '--- Test Stage (Empty) ---' 
            } 
        } 
 
        stage('Deploy Stage') { 
            steps { 
                sshagent(['deploy-server-key']) { 
                    sh ''' 
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} " 
                            if [ ! -d \"${BUILD_DIR}/public\" ]; then 
                                exit 1 
                            fi 
 
                            rsync -av --delete \ 
                                --exclude='.env' \ 
                                --exclude='.git' \ 
                                --exclude='storage' \ 
                                --exclude='public/storage' \ 
                                --exclude='node_modules' \ 
                                --exclude='vendor' \ 
                                --exclude='public/dist' \ 
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
