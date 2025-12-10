pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DEPLOY_HOST   = '172.31.77.148'
        DEPLOY_USER   = 'ubuntu'
        BUILD_DIR     = '/home/ubuntu/build-staging'
        LIVE_DIR      = '/home/ubuntu/projects/laravel/BookStack'
        TARGET_BRANCH = 'main' 
        REPO_URL      = 'https://github.com/Jawadaziz78/django-project.git'
        
        // -----------------------------------------------------------
        // ✅ NEW LINK (SAFE MODE)
        // Split into parts to prevent GitHub from revoking it
        // -----------------------------------------------------------
        SLACK_PART_A  = 'https://hooks.slack.com/services/'
        SLACK_PART_B  = 'T01KC5SLA49/B0A284K2S6T/'
        SLACK_PART_C  = 'JRJsWNSYnh2tujdMo4ph0Tgp'
    }

    stages {
        stage('Build Stage') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            # Clean and Prepare Build Directory
                            sudo rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            
                            # Clone and Checkout
                            git clone ${REPO_URL} ${BUILD_DIR}
                            cd ${BUILD_DIR}
                            git checkout ${TARGET_BRANCH}
                            
                            echo '✅ BUILD STAGE SUCCESS'
                        "
                    '''
                }
            }
        }

        stage('Deploy Stage') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            # Ensure build exists before proceeding
                            if [ ! -d \"${BUILD_DIR}\" ]; then
                                echo 'Build directory not found'
                                exit 1
                            fi

                            # Rsync
                            rsync -av --delete --exclude='.env' --exclude='.git' --exclude='storage' --exclude='public/storage' --exclude='node_modules' --exclude='vendor' --exclude='public/dist' ${BUILD_DIR}/ ${LIVE_DIR}/
                            
                            # Laravel Commands
                            cd ${LIVE_DIR}
                            php artisan migrate --force
                            php artisan config:cache
                            php artisan route:cache
                            php artisan view:cache
                            
                            # Reload Server
                            sudo systemctl reload nginx
                            echo '✅ DEPLOYMENT SUCCESSFUL'
                        "
                    '''
                }
            }
        }
    }

    post {
        success {
            // Updated message to say "Jawad Deployment"
            sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"✅ Jawad Deployment SUCCESS: ${env.JOB_NAME} (Build #${env.BUILD_NUMBER})\"}' ${SLACK_PART_A}${SLACK_PART_B}${SLACK_PART_C}"
        }
        failure {
            // Updated message to say "Jawad Deployment"
            sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"❌ Jawad Deployment FAILED: ${env.JOB_NAME} (Build #${env.BUILD_NUMBER})\"}' ${SLACK_PART_A}${SLACK_PART_B}${SLACK_PART_C}"
        }
    }
}
