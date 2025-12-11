pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DEPLOY_HOST     = '172.31.77.148'
        DEPLOY_USER     = 'ubuntu'
        BUILD_DIR       = '/home/ubuntu/build-staging'
        
        PROJECT_TYPE = 'laravel' 
        
        // SLACK CONFIGURATION (Commented Out)
        // SLACK_PART_A  = 'https://hooks.slack.com/services/'
        // SLACK_PART_B  = 'T01KC5SLA49/B0A284K2S6T/'
        // SLACK_PART_C  = 'JRJsWNSYnh2tujdMo4ph0Tgp'
    }

    stages {
        // Stage 1: Build (Updates code and runs minimal, project-specific optimization)
        stage('Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                    ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                        set -e

                        cd ${BUILD_DIR}
                        git pull origin ${BRANCH_NAME:-main}
                        git checkout ${BRANCH_NAME:-main} 

                        case \\"${PROJECT_TYPE}\\" in
                            laravel)
                                # FIX: Copy .env file if missing, required for artisan commands
                                if [ ! -f .env ]; then cp .env.example .env; fi
                                echo '⚙️ Running Laravel Optimization Tasks...'
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


        // Stage 2: Test (Execute unit tests based on project type)
    //     stage('Test') {
      //       steps {
         //        sshagent(['deploy-server-key']) {
             //        sh '''
               //      ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                //         set -e
                  //       cd ${BUILD_DIR}
                        
                     //    echo '-----------------------------------'
                     //    echo '🧪 STAGE 2: TEST EXECUTION'
                    //     echo '-----------------------------------'
                        
                    //     # Load Node 20
                    //     export NVM_DIR=\\"\\$HOME/.nvm\\" 
                    //     [ -s \\"\\$NVM_DIR/nvm.sh\\" ] && . \\"\\$NVM_DIR/nvm.sh\\" 
                    //     nvm use 20

                    //     # Execute tests based on PROJECT_TYPE
                     //    case \\"${PROJECT_TYPE}\\" in
                        //     laravel)
                         //        # Setup in-memory SQLite for testing
                           //      export DB_CONNECTION=sqlite
                           //      export DB_DATABASE=:memory:
                                
                             //    php ./vendor/bin/phpunit --testsuite Unit
                            //     ;;
                            
                        //     vue)
                          //       npm run test:unit
                           //      ;;
                            
                          //   nextjs)<br>                           //      cd web
                            //     npm run test
                            //     ;;
                          //   *)
                              //   echo '⚠️ Skipping tests for project type: ${PROJECT_TYPE}'
                              //   ;;
                      //   esac

                     //    echo '✅ Tests Completed Successfully'<br>                 //    "<br>                //     '''
               //  }<br>      //       }<br>    //     }<br>

// --- (Removing this fixed the error, this line is now just a comment)

        // Stage 3: Deploy (Syncs code to live directory and runs post-deploy tasks)
        stage('Deploy') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                    ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                        set -e
                        
                        # IDENTIFY LIVE DIRECTORY
                        case \\"${PROJECT_TYPE}\\" in
                            laravel) LIVE_DIR='/home/ubuntu/projects/laravel/BookStack' ;;
                            vue)     LIVE_DIR='/home/ubuntu/projects/vue/app' ;;
                            nextjs)  LIVE_DIR='/home/ubuntu/projects/nextjs/blog' ;;
                        esac

                        echo '-----------------------------------'
                        echo '🚀 STAGE 3: DEPLOY (Rsync & Config)'
                        echo '📂 Target: '$LIVE_DIR
                        echo '-----------------------------------'

                        # RSYNC TO LIVE 
                        mkdir -p \\$LIVE_DIR
                        rsync -av --delete --exclude='.env' --exclude='.git' --exclude='storage' --exclude='public/storage' --exclude='node_modules' --exclude='vendor' --exclude='public/dist' ${BUILD_DIR}/ \\$LIVE_DIR/

                        # RUN POST-DEPLOY COMMANDS
                        cd \\$LIVE_DIR

                        # Load Node 20
                        export NVM_DIR=\\"\\$HOME/.nvm\\" 
                        [ -s \\"\\$NVM_DIR/nvm.sh\\" ] && . \\"\\$NVM_DIR/nvm.sh\\" 
                        nvm use 20

                        # Run project-specific post-deploy tasks
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
                                echo '⚙️ Applying Vue build...'
                                sudo systemctl reload nginx
                                ;;
                            
                            nextjs)
                                echo '⚙️ Running Next.js build and restart...'
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
            echo "Pipeline succeeded. (Slack notification is commented out)"
            // sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"Jawad Deployment SUCCESS: ${env.JOB_NAME} (Build #${env.BUILD_NUMBER})\"}' ${SLACK_PART_A}${SLACK_PART_B}${SLACK_PART_C}"
        }
        failure {
            echo "Pipeline failed. (Slack notification is commented out)"
            // sh "curl -X POST -H 'Content-type: application/json' --data '{\"text\":\"Jawad Deployment FAILED: ${env.JOB_NAME} (Build #${env.BUILD_NUMBER})\"}' ${SLACK_PART_A}${SLACK_PART_B}${SLACK_PART_C}"
        }
    }
}
