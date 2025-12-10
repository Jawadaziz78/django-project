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
        
        // SLACK CONFIGURATION
        SLACK_PART_A  = 'https://hooks.slack.com/services/'
        SLACK_PART_B  = 'T01KC5SLA49/B0A284K2S6T/'
        SLACK_PART_C  = 'JRJsWNSYnh2tujdMo4ph0Tgp'
    }

   stage('Build') {
    steps {
        sshagent(['deploy-server-key']) {
            sh '''
                ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                    set -e

                    echo '-----------------------------------'
                    echo '🚀 STAGE 1: BUILD (Checkout Code)'
                    echo '-----------------------------------'

                    # Use Jenkins' built-in checkout mechanism to get the latest code for the branch
                    checkout scm

                    # After checkout, ensure we are on the correct branch (BRANCH_NAME set by Jenkins or defaults to 'main')
                    git checkout ${BRANCH_NAME:-main}

                    echo '✅ Build/Checkout Successful'
                "
            '''
        }
    }
}


        // stage('Test') {
        //     steps {
        //         sshagent(['deploy-server-key']) {
        //             sh '''
        //                 ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
        //                     set -e
        //                     cd ${BUILD_DIR}
        //                     echo '-----------------------------------'
        //                     echo '🧪 STAGE 2: TEST EXECUTION'
        //                     echo '-----------------------------------'
                            
        //                     # Load Node 20
        //                     export NVM_DIR=\\"\\$HOME/.nvm\\" 
        //                     [ -s \\"\\$NVM_DIR/nvm.sh\\" ] && . \\"\\$NVM_DIR/nvm.sh\\" 
        //                     nvm use 20

        //                     case \\"${PROJECT_TYPE}\\" in
        //                         laravel)
        //                            
        //                             # Install dev dependencies (including PHPUnit)
        //                             composer install --no-interaction --prefer-dist --optimize-autoloader

        //                             
        //                             export DB_CONNECTION=sqlite
        //                             export DB_DATABASE=:memory:
                             
        //                             php ./vendor/bin/phpunit --testsuite Unit
        //                             ;;
                            
        //                         vue)
        //                             echo '--- Running Vue Tests (Jest/Vitest) ---'
        //                             if [ ! -d \\"node_modules\\" ]; then npm install; fi
        //                             npm run test:unit
        //                             ;;
                            
        //                         nextjs)
        //                             echo '--- Running Next.js Tests (Jest) ---'
        //                             cd web
        //                             if [ ! -d \\"node_modules\\" ]; then npm install; fi
        //                             npm run test
        //                             ;;
        //                         *)
        //                             echo '⚠️ Skipping tests for project type: ${PROJECT_TYPE}'
        //                             ;;
        //                     esac

        //                     echo '✅ Tests Completed Successfully'
        //                 "
        //             '''
        //         }
        //     }
        // }

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

    post {
        success {
            sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"Jawad Deployment SUCCESS: ${env.JOB_NAME} (Build #${env.BUILD_NUMBER})\"}' ${SLACK_PART_A}${SLACK_PART_B}${SLACK_PART_C}"
        }
        failure {
            sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"Jawad Deployment FAILED: ${env.JOB_NAME} (Build #${env.BUILD_NUMBER})\"}' ${SLACK_PART_A}${SLACK_PART_B}${SLACK_PART_C}"
        }
    }
}
