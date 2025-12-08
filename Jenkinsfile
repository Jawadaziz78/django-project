pipeline {
    agent any

    environment {
        // TARGET: The IP of the 'docker-practise' instance (Laravel Server)
        DEPLOY_HOST = '172.31.77.148' 
        DEPLOY_USER = 'ubuntu'
        // The specific staging folder
        BUILD_DIR = '/home/ubuntu/build-staging' 
    }

    stages {
        // --- STAGE 1: BUILD ---
        stage('Remote Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            echo '--- 1. Preparing Build Directory ---'
                            rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            
                            echo '--- 2. Cloning Repository ---'
                            git clone https://github.com/Jawadaziz78/django-project.git ${BUILD_DIR}
                            cd ${BUILD_DIR}
                            
                            echo '--- 3. Installing Backend Dependencies ---'
                            composer install --no-interaction --prefer-dist --optimize-autoloader
                            
                            echo '--- 4. Setting up Environment ---'
                            cp .env.example .env
                            php artisan key:generate
                            
                            echo '--- 5. Installing Frontend Dependencies ---'
                            npm install
                            npm run build
                        "
                    '''
                }
            }
        }

        // --- STAGE 2: TEST ---
        stage('Remote Test') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            cd ${BUILD_DIR}
                            
                            echo '--- 6. Running PHP Tests (In-Memory SQLite) ---'
                            # We override DB settings here to use RAM, avoiding your real database
                            export DB_CONNECTION=sqlite
                            export DB_DATABASE=:memory:
                            php artisan test
                            
                            echo '--- 7. Running JavaScript Tests ---'
                            # CI=true ensures Jest runs once and exits (fixes the loop issue)
                            export CI=true
                            npm run test -- --ci --reporters=default
                        "
                    '''
                }
            }
        }
    }
}
