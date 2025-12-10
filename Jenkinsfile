pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DEPLOY_HOST   = '172.31.77.148'
        DEPLOY_USER   = 'ubuntu'
        BUILD_DIR     = '/home/ubuntu/build-staging'
        
        // Slack Config (Commented out for now)
        // SLACK_PART_A  = 'https://hooks.slack.com/services/'
        // SLACK_PART_B  = 'T01KC5SLA49/B0A284K2S6T/'
        // SLACK_PART_C  = 'JRJsWNSYnh2tujdMo4ph0Tgp'

        // -----------------------------------------------------
        // CHANGE THIS PER REPO: 'laravel', 'vue', or 'nextjs'
        // -----------------------------------------------------
        PROJECT_TYPE = 'laravel'
    }

    stages {
        stage('Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            set -e
                            
                            # 1. IDENTIFY REPO URL
                            case \\"${PROJECT_TYPE}\\" in
                                laravel) REPO_URL='https://github.com/Jawadaziz78/django-project.git' ;;
                                vue)     REPO_URL='https://github.com/Jawadaziz78/vue-project.git' ;;
                                nextjs)  REPO_URL='https://github.com/Jawadaziz78/nextjs-project.git' ;;
                                *)       echo '❌ Error: Unknown Project Type'; exit 1 ;;
                            esac

                            echo '🚀 STAGE 1: BUILD (Cloning Code)'
                            
                            # Clean and Clone
                            sudo rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            git clone \\$REPO_URL ${BUILD_DIR}
                            cd ${BUILD_DIR}
                            git checkout ${BRANCH_NAME:-main}
                            
                            echo '✅ Build/Clone Successful'
                        "
                    '''
                }
            }
        }

        stage('Test') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            set -e
                            echo '🧪 STAGE 2: TEST (Running Unit Tests)'
                            cd ${BUILD_DIR}

                            # Load Node 20
                            export NVM_DIR=\\"\\$HOME/.nvm\\"
                            [ -s \\"\\$NVM_DIR/nvm.sh\\" ] && . \\"\\$NVM_DIR/nvm.sh\\"
                            nvm use 20

                            case \\"${PROJECT_TYPE}\\" in
                                laravel)
                                    echo '⚙️ Testing Laravel/BookStack...'

                                    # 1. Copy the TESTING env file
                                    cp /home/ubuntu/projects/laravel/BookStack/.env.testing .env

                                    # 2. Install dependencies
                                    echo '📦 Installing dependencies...'
                                    composer install --no-interaction --prefer-dist --optimize-autoloader
                                    
                                    # 3. Generate Application Key
                                    php artisan key:generate

                                    # 4. Run database migrations for testing
                                    echo '🗄️ Running migrations for test database...'
                                    php artisan migrate --database=mysql_testing --force -n

                                    # 5. Run PHPUnit tests
                                    echo '🧪 Running PHPUnit tests...'
                                    php -d memory_limit=512M ./vendor/bin/phpunit --no-coverage
                                    ;;

                                vue)
                                    echo 'Skipping Vue tests (not configured)'
                                    ;;

                                nextjs)
                                    echo 'Skipping Next.js tests (not configured)'
                                    ;;
                            esac

                            echo '✅ Tests Passed Successfully'
                        "
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            set -e
                            
                            # 1. IDENTIFY LIVE DIRECTORY
                            case \\"${PROJECT_TYPE}\\" in
                                laravel) LIVE_DIR='/home/ubuntu/projects/laravel/BookStack' ;;
                                vue)     LIVE_DIR='/home/ubuntu/projects/vue/app' ;;
                                nextjs)  LIVE_DIR='/home/ubuntu/projects/nextjs/blog' ;;
                            esac

                            echo '🚀 STAGE 3: DEPLOY (Syncing to Live)'

                            # Ensure Live Directory Exists
                            mkdir -p \\$LIVE_DIR

                            # Rsync to Live (Excluding sensitive files)
                            rsync -av --delete --exclude='.env' --exclude='.git' --exclude='storage' --exclude='public/storage' --exclude='node_modules' --exclude='vendor' --exclude='public/dist' ${BUILD_DIR}/ \\$LIVE_DIR/

                            # Post-Deploy Commands
                            cd \\$LIVE_DIR
                            export NVM_DIR=\\"\\$HOME/.nvm\\"
                            [ -s \\"\\$NVM_DIR/nvm.sh\\" ] && . \\"\\$NVM_DIR/nvm.sh\\"
                            nvm use 20

                            case \\"${PROJECT_TYPE}\\" in
                                laravel)
                                    echo '⚙️ Running Laravel Tasks...'
                                    
                                    # OPTIMIZED: Use global composer to install only PROD dependencies in live folder
                                    composer install --no-dev --no-interaction --prefer-dist
                                    
                                    php artisan config:clear
                                    php artisan cache:clear
                                    php artisan migrate --force
                                    php artisan route:cache
                                    php artisan view:cache
                                    sudo systemctl reload nginx
                                    ;;
                                
                                vue)
                                    echo '⚙️ Building Vue...'
                                    npm run build
                                    sudo systemctl reload nginx
                                    ;;
                                
                                nextjs)
                                    echo '⚙️ Building Next.js...'
                                    cd web
                                    rm -rf .next
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
            echo '✅ Deployment SUCCESS (Slack Notification Skipped)'
        }
        failure {
            echo '❌ Deployment FAILED (Slack Notification Skipped)'
        }
    }
}
