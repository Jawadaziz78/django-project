pipeline {
    agent any

    environment {
        DEPLOY_HOST = '172.31.77.148' 
        DEPLOY_USER = 'ubuntu'
        BUILD_DIR = '/home/ubuntu/build-staging' 
    }

    stages {
        stage('Remote Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            # Build steps remain the same...
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

        stage('Remote Smoke Test') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            cd ${BUILD_DIR}
                            
                            echo '--- Running LIMITED PHP Tests (Unit Only) ---'
                            export DB_CONNECTION=sqlite
                            export DB_DATABASE=:memory:
                            
                            # LIMIT 1: Run only the 'tests/Unit' folder (Very fast)
                            # If this folder is empty in your repo, change it to --filter ExampleTest
                            php artisan test tests/Unit
                            
                            echo '--- Skipping JS Tests for Speed ---'
                            # To run JS tests later, uncomment the line below:
                            # export CI=true && npm run test -- --ci --bail
                        "
                    '''
                }
            }
        }
    }
}
