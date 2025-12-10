pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DEPLOY_HOST   = '172.31.77.148'
        DEPLOY_USER   = 'ubuntu'
        BUILD_DIR     = '/home/ubuntu/build-staging'
        
        // -----------------------------------------------------
        // CHANGE THIS PER REPO: 'laravel', 'vue', or 'nextjs'
        // -----------------------------------------------------
        PROJECT_TYPE = 'laravel' 
        
        // ❌ SLACK TEMPORARILY COMMENTED OUT
        // SLACK_PART_A  = 'https://hooks.slack.com/services/'
        // SLACK_PART_B  = 'T01KC5SLA49/B0A284K2S6T/'
        // SLACK_PART_C  = 'JRJsWNSYnh2tujdMo4ph0Tgp'
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

                            echo '-----------------------------------'
                            echo '🚀 STAGE 1: BUILD (Cloning Code)'
                            echo '-----------------------------------'

                            # 2. PREPARE STAGING DIRECTORY
                            sudo rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            
                            # 3. CLONE CODE
                            git clone \\$REPO_URL ${BUILD_DIR}
                            cd ${BUILD_DIR}
                            # Use BRANCH_NAME provided by Jenkins, default to 'main' if not set
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
                            cd ${BUILD_DIR}
                            echo '-----------------------------------'
                            echo '🧪 STAGE 2: TEST EXECUTION'
                            echo '-----------------------------------'
                            
                            # Load Node 20
                            export NVM_DIR=\\"\\$HOME/.nvm\\"
                            [ -s \\"\\$NVM_DIR/nvm.sh\\" ] && . \\"\\$NVM_DIR/nvm.sh\\"
                            nvm use 20

                            case \\"${PROJECT_TYPE}\\" in
                                laravel)
                                    echo '--- Running Laravel Smoke Tests (Unit Only) ---'
                                    # Install dev dependencies (including PHPUnit)
                                    composer install --no-interaction --prefer-dist --optimize-autoloader

                                    # Use in-memory SQLite database for fast unit testing
                                    export DB_CONNECTION=sqlite
                                    export DB_DATABASE=:memory:
                                    
                                    # Use phpunit binary directly to run tests
                                    php ./vendor/bin/phpunit --testsuite Unit
                                    ;;
                                
                                vue)
                                    echo '--- Running Vue Tests (Jest/Vitest) ---'
                                    if [ ! -d \\"node_modules\\" ]; then npm install; fi
                                    npm run test:unit
                                    ;;
                                
                                nextjs)
                                    echo '--- Running Next.js Tests (Jest) ---'
                                    cd web
                                    if [ ! -d \\"node_modules\\" ]; then npm install; fi
                                    npm run test
                                    ;;
                                *)
                                    echo '⚠️ Skipping tests for project type: ${PROJECT_TYPE}'
                                    ;;
                            esac

                            echo '✅ Tests Completed Successfully'
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

                            echo '-----------------------------------'
                            echo '🚀 STAGE 3: DEPLOY (Rsync & Config)'
                            echo '📂 Target: '$LIVE_DIR
                            echo '-----------------------------------'

                            # 2. RSYNC TO LIVE (Preserve configs, vendors, etc.)
                            mkdir -p \\$LIVE_DIR
                            rsync -av --delete --exclude='.env' --exclude='.git' --exclude='storage' --exclude='public/storage' --exclude='node_modules' --exclude='vendor' --exclude='public/dist' ${BUILD_DIR}/ \\$LIVE_DIR/

                            # 3. RUN POST-DEPLOY COMMANDS
                            cd \\$LIVE_DIR

                            # Load Node 20 (Required for Vue/Next.js)
                            export NVM_DIR=\\"\\$HOME/.nvm\\"
                            [ -s \\"\\$NVM_DIR/nvm.sh\\" ] && . \\"\\$NVM_DIR/nvm.sh\\"
                            nvm use 20

                            case \\"${PROJECT_TYPE}\\" in
                                laravel)
                                    echo '⚙️ Running Laravel Tasks...'
                                    php artisan config:clear
                                    php artisan cache:clear
                                    
                                    php artisan migrate --force
                                    php artisan config:cache
                                    php artisan route:cache
                                    php artisan view:cache
                                    sudo systemctl reload nginx
                                    ;;
                                
                                vue)
                                    echo '⚙️ Building Vue (using copied code)...'
                                    npm run build
                                    sudo systemctl reload nginx
                                    ;;
                                
                                nextjs)
                                    echo '⚙️ Building Next.js (using copied code)...'
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

    // post { ... } // Post actions are commented out
}
