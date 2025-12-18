pipeline {
    agent any
    triggers { githubPush() }
    
    environment {
        PROJECT_TYPE  = 'laravel'
        DEPLOY_HOST   = '172.31.77.148'
        DEPLOY_USER   = 'ubuntu'
        CURRENT_STAGE = 'Initialization' 
        
        // SLACK_WEBHOOK = credentials('slack-webhook-url')
    }
    
    stages {
        stage('SonarQube Analysis') {
            steps {
                script {
                    env.CURRENT_STAGE = 'SonarQube Analysis'
                    
                    withSonarQubeEnv('sonar-server') {
                        sh '''
                            export SONAR_NODE_ARGS='--max-old-space-size=2048'      
                            /home/ubuntu/sonar-scanner/bin/sonar-scanner \
                                -Dsonar.projectKey=${PROJECT_TYPE}-project \
                                -Dsonar.sources=app,routes,database \
                                -Dsonar.inclusions=**/*.php \
                                -Dsonar.exclusions=vendor/**,storage/**,resources/views/**,tests/**,bootstrap/cache/**,public/**
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    env.CURRENT_STAGE = 'Quality Gate'
                    timeout(time: 2, unit: 'MINUTES') {
                        env.QUALITY_GATE_STATUS = waitForQualityGate(abortPipeline: true).status
                    }
                }
            }
        }

        stage('Build and Deploy') {
            steps {
                script {
                    env.CURRENT_STAGE = 'Build and Deploy'
                    if (env.QUALITY_GATE_STATUS != 'OK') {
                        error "❌ Deployment Prevented: Quality Gate status is ${env.QUALITY_GATE_STATUS}"
                    }
                }
                
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            set -e
                            echo '--- 🚀 Connected to Deployment Server ---'
                            
                            # DIRECTLY NAVIGATE using the variables
                            cd /var/www/html/${BRANCH_NAME}/${PROJECT_TYPE}-project
                            
                            git pull origin ${BRANCH_NAME}
                            
                            case \"${PROJECT_TYPE}\" in
                                vue)
                                    npm run build ;;
                                nextjs)
                                    npm run build
                                    pm2 restart ${PROJECT_TYPE}-${BRANCH_NAME} ;;
                                laravel)
                                    sudo php artisan optimize ;;
                            esac
                        "
                    '''
                }
            }
        } 
    } 
    
    post {
        success {
            script {
                echo "✅ Pipeline Successful"
                // Success Notification (Commented Out)
                /*
                sh """
                    curl -X POST -H 'Content-type: application/json' \
                    --data '{"text":"✅ *Deployment Successful*\\n📂 Project: ${PROJECT_TYPE}\\n🌿 Branch: ${env.BRANCH_NAME}\\n🚀 Status: Live"}' \
                   // ${SLACK_WEBHOOK}
                """
                */
            }
        }
        failure {
            script {
                echo "❌ Pipeline Failed"
                // Failure Notification (Commented Out)
                /*
                sh """
                    curl -X POST -H 'Content-type: application/json' \
                    --data '{"text":"❌ *Pipeline Failed*\\n📂 Project: ${PROJECT_TYPE}\\n🌿 Branch: ${env.BRANCH_NAME}\\n💥 Failed Stage: *${env.CURRENT_STAGE}*\\n🔍 Action: Check Jenkins Console Logs."}' \
                   // ${SLACK_WEBHOOK}
                """
                */
            }
        }
    }
}
