// 1. Define global variable at the top to track the failing stage
def currentStage = 'Initialization'

pipeline {
    agent any
    triggers { githubPush() }
    
    environment {
        PROJECT_TYPE  = 'laravel'
        DEPLOY_HOST   = '172.31.77.148'
        DEPLOY_USER   = 'ubuntu'
        SLACK_WEBHOOK = credentials('slack-webhook-url')
        // No manual CURRENT_STAGE in environment block
    }
    
    stages {
        stage('SonarQube Analysis') {
            steps {
                script {
                    // Update global tracker using built-in STAGE_NAME
                    currentStage = STAGE_NAME 
                    
                    withSonarQubeEnv('sonar-server') {
                        sh '''
                            export SONAR_NODE_ARGS='--max-old-space-size=2048'      
                            /home/ubuntu/sonar-scanner/bin/sonar-scanner \
                               -Dsonar.projectKey=${PROJECT_TYPE}-project \
                                -Dsonar.sources=app \
                                -Dsonar.inclusions=**/*.php
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                script {
                    currentStage = STAGE_NAME
                    timeout(time: 3, unit: 'MINUTES') {
                        // EXACT LOGIC RESTORED
                        env.QUALITY_GATE_STATUS = waitForQualityGate(abortPipeline: true).status
                    }
                }
            }
        }

        stage('Build and Deploy') {
            steps {
                script {
                    currentStage = STAGE_NAME
                    // EXACT LOGIC RESTORED
                    if (env.QUALITY_GATE_STATUS != 'OK') {
                        error "❌ Deployment Prevented: Quality Gate status is ${env.QUALITY_GATE_STATUS}"
                    }
                }
                
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            set -e
                            echo '--- 🚀 Connected to Deployment Server ---'
                            cd /var/www/html/${BRANCH_NAME}/${PROJECT_TYPE}-project
                            git pull origin ${BRANCH_NAME}
                            
                            case \"${PROJECT_TYPE}\" in
                                vue) npm run build ;;
                                nextjs) 
                                    npm run build
                                    pm2 restart ${PROJECT_TYPE}-${BRANCH_NAME} ;;
                                laravel) sudo php artisan optimize ;;
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
                sh """
                    curl -X POST -H 'Content-type: application/json' \
                    --data '{"text":"✅ *Deployment Successful*\\n📂 Project: ${PROJECT_TYPE}\\n🌿 Branch: ${env.BRANCH_NAME}\\n🚀 Status: Live"}' \
                   ${SLACK_WEBHOOK}
                """
            }
        }
        failure {
            script {
                echo "❌ Pipeline Failed at: ${currentStage}"
                // Use built-in env.BUILD_URL to provide the "link to find error"
                sh """
                    curl -X POST -H 'Content-type: application/json' \
                    --data '{"text":"❌ *Pipeline Failed*\\n📂 Project: ${PROJECT_TYPE}\\n🌿 Branch: ${env.BRANCH_NAME}\\n💥 Failed Stage: *${currentStage}*\\n🔍 Action: <${env.BUILD_URL}console|Click here to find the error in logs>"}' \
                   ${SLACK_WEBHOOK}
                """
            }
        }
    }
}
