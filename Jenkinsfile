pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DEPLOY_HOST     = '172.31.77.148'
        DEPLOY_USER     = 'ubuntu'
        BUILD_DIR       = '/home/ubuntu/build-staging'
        PROJECT_TYPE    = 'laravel' 
        
        // SLACK CONFIGURATION
        SLACK_PART_A  = 'https://hooks.slack.com/services/'
        SLACK_PART_B  = 'T01KC5SLA49/B0A284K2S6T/'
        SLACK_PART_C  = 'JRJsWNSYnh2tujdMo4ph0Tgp'
    }

    stages {
        
        stage('Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                    ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                        set -e

                        cd ${BUILD_DIR}
                        
                        # FIX: Replaced 'git pull' with fetch + reset --hard
                        # This prevents the 'divergent branches' error.
                        git fetch origin ${BRANCH_NAME:-main}
                        git reset --hard origin/${BRANCH_NAME:-main}
                        git checkout ${BRANCH_NAME:-main} 

                        case \\"${PROJECT_TYPE}\\" in
                            laravel)
                                # FIX: Copy .env if missing so artisan commands don't fail
                                if [ ! -f .env ]; then cp .env.example .env; fi
                                
                                echo 'Running Laravel Optimization Tasks...'
                                php artisan key:generate --force
                                php artisan config:cache
                                php artisan route:cache
                                php artisan view:cache
                                ;;
                            
                            vue)
                                echo '⚙️ Vue code updated. Skipping build/install.'
                                ;;
                            
                            nextjs)
                                echo '⚙️ Next.js code updated. Skipping build/install.'
                                ;;
                        esac
                        
                        echo '✅ Build/Update Successful'
                    "
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                // FIX: Define LIVE_DIR in Groovy to prevent 'mkdir missing operand' error
                script {
                    def projectDirs = [
                        'laravel': '/home/ubuntu/projects/laravel/BookStack',
                        'vue':     '/home/ubuntu/projects/vue/app',
                        'nextjs':  '/home/ubuntu/projects/nextjs/blog'
                    ]
                    env.LIVE_DIR = projectDirs[env.PROJECT_TYPE]
                }

                sshagent(['deploy-server-key']) {
                    sh '''
                    # We use ${LIVE_DIR} directly now because Jenkins injects it safely
                    ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                        set -e
                        

                        # RSYNC TO LIVE 
                        # We exclude cache files so we don't copy the 'build' config to 'live'
                        mkdir -p ${LIVE_DIR}
                        rsync -av --delete --exclude='.env' --exclude='.git' --exclude='bootstrap/cache/*.php' --exclude='storage' --exclude='public/storage' --exclude='node_modules' --exclude='vendor' --exclude='public/dist' ${BUILD_DIR}/ ${LIVE_DIR}/

                        # RUN POST-DEPLOY COMMANDS
                        cd ${LIVE_DIR}

                        # Load Node 20
                        # FIX: Hardcoded path based on your diagnostic result
                        # This ensures the script loads successfully every time
                        export NVM_DIR='/home/ubuntu/.nvm'
                        [ -s \"/home/ubuntu/.nvm/nvm.sh\" ] && . \"/home/ubuntu/.nvm/nvm.sh\"
                        nvm use 20

                        # Run project-specific post-deploy tasks
                        case \\"${PROJECT_TYPE}\\" in
                            laravel)
                                echo '⚙️ Running Compulsory Laravel Tasks...'
                                
                                # 1. Force delete poisoned config cache (Critical Fix)
                                rm -f bootstrap/cache/*.php
                                
                                # 2. Update Database 
                                php artisan migrate --force
                                
                                # 3. Refresh Config Cache
                                php artisan config:cache
                                
                                # 4. Reload Server 
                                sudo systemctl reload nginx
                                ;;
                            
                            vue)
                                echo 'Reloading Vue...'
                                sudo systemctl reload nginx
                                ;;
                            
                            nextjs)
                                echo 'Rebuilding Next.js...'
                                cd web
                                npm run build
                                pm2 restart all
                                sudo systemctl reload nginx
                                ;;
                        esac
                        
                        echo '✅ DEPLOYMENT SUCCESSFUL'
                    "
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded. Sending Slack notification..."
            sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"Jawad Deployment SUCCESS: ${env.JOB_NAME} (Build #${env.BUILD_NUMBER})\"}' ${SLACK_PART_A}${SLACK_PART_B}${SLACK_PART_C}"
        }
        failure {
            echo "Pipeline failed. Sending Slack notification..."
            sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"Jawad Deployment FAILED: ${env.JOB_NAME} (Build #${env.BUILD_NUMBER})\"}' ${SLACK_PART_A}${SLACK_PART_B}${SLACK_PART_C}"
        }
    }
}
