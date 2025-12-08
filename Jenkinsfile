pipeline {
    agent any

    environment {
        // TARGET: The IP of the 'docker-practise' instance (Laravel Server)
        DEPLOY_HOST = '172.31.77.148' 
        DEPLOY_USER = 'ubuntu'
        BUILD_DIR = '/home/ubuntu/build-staging' 
    }

    stages {
        stage('Remote Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        # Test connection from Jenkins(78.78) -> Laravel(77.148)
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "echo 'Connection Successful!'"

                        # Run Build on the Laravel Server
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            git clone https://github.com/Jawadaziz78/django-project.git ${BUILD_DIR}
                            cd ${BUILD_DIR}
                            composer install --no-interaction --prefer-dist --optimize-autoloader
                            cp .env.example .env
                            php artisan key:generate
                            npm install
                            npm run build
                        "
                    '''
                }
            }
        }
    }
}
