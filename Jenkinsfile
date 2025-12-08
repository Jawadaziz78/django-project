pipeline {
    agent any

    environment {
        // The Private IP of your Deployment Instance
        DEPLOY_HOST = '172.31.78.78' 
        DEPLOY_USER = 'ubuntu'
        // The specific folder where we will build the project (NOT the live folder yet)
        BUILD_DIR = '/home/ubuntu/build-staging' 
    }

    stages {
        stage('Remote Build') {
            steps {
                sshagent(['dev-jawad']) {
                    sh '''
                        # Everything inside here runs on the JENKINS instance
                        # We use SSH to send commands to the DEPLOYMENT instance
                        
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            echo '--- Connected to Deployment Instance ---'
                            
                            # 1. Create a clean build directory
                            rm -rf ${BUILD_DIR}
                            mkdir -p ${BUILD_DIR}
                            
                            # 2. Clone the code (Using HTTPS for simplicity)
                            git clone https://github.com/Jawadaziz78/django-project.git ${BUILD_DIR}
                            
                            # 3. Enter directory
                            cd ${BUILD_DIR}
                            
                            # 4. Install Backend Dependencies (using tools on Deployment Instance)
                            echo '--- Running Composer ---'
                            composer install --no-interaction --prefer-dist --optimize-autoloader
                            
                            # 5. Setup Environment
                            cp .env.example .env
                            php artisan key:generate
                            
                            # 6. Install Frontend Dependencies & Build
                            echo '--- Running NPM Build ---'
                            npm install
                            npm run build
                        "
                    '''
                }
            }
        }
    }
}
