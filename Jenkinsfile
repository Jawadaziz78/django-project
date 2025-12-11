pipeline {
    agent any

    environment {
        DEPLOY_HOST = '172.31.77.148'
        DEPLOY_USER = 'ubuntu'
    }

    stages {
        stage('Debug System') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                    ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                        echo '--------------------------------------'
                        echo '🔍 DIAGNOSTIC START'
                        echo '--------------------------------------'
                        
                        echo '1. Checking user:'
                        whoami
                        
                        echo '2. Checking standard NVM path (/home/ubuntu/.nvm):'
                        if [ -d /home/ubuntu/.nvm ]; then
                            echo '✅ Directory /home/ubuntu/.nvm exists.'
                        else
                            echo '❌ Directory /home/ubuntu/.nvm NOT found.'
                        fi

                        echo '3. Checking for nvm.sh script:'
                        if [ -f /home/ubuntu/.nvm/nvm.sh ]; then
                            echo '✅ Found at: /home/ubuntu/.nvm/nvm.sh'
                        else
                            echo '❌ nvm.sh not found in standard location.'
                            echo '   Attempting to find it elsewhere...'
                            find /home -name nvm.sh 2>/dev/null
                        fi

                        echo '--------------------------------------'
                        echo '🏁 DIAGNOSTIC END'
                        echo '--------------------------------------'
                    "
                    '''
                }
            }
        }
    }
}
