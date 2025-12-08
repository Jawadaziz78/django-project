pipeline {
    agent any

    environment {
        // --- CONFIGURATION ---
        REMOTE_HOST = '172.31.77.148'
        REMOTE_USER = 'ubuntu'
        PROJECT_DIR = '/home/ubuntu/projects/laravel'
        APP_DIR = 'BookStack'
        CREDENTIALS_ID = 'deploy-server-key' 
    }

    stages {
        // STAGE 1: TEST (Runs on Jenkins Server first)
        stage('Test') {
            steps {
                script {
                    // This assumes your Jenkins server has PHP installed. 
                    // If not, we can skip this or run it inside a Docker container.
                    echo "Running Tests..."
                    // sh 'php artisan test'  <-- Uncomment this if Jenkins has PHP installed
                    echo "Skipping local tests (PHP not installed on Jenkins agent)" 
                }
            }
        }

        // STAGE 2: DEPLOY (Runs on Remote Server)
        stage('Deploy to Remote Server') {
            steps {
                sshagent(credentials: [CREDENTIALS_ID]) {
                    script {
                        echo "Deploying to ${REMOTE_HOST}..."
                        sh """
                            ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                                set -e
                                
                                echo "1. Navigating to Git Project..."
                                cd ${PROJECT_DIR}
                                
                                echo "2. Pulling latest code..."
                                git pull origin main
                                
                                echo "3. Entering App Directory..."
                                cd ${APP_DIR}
                                
                                echo "4. Installing Dependencies..."
                                composer install --no-interaction --prefer-dist --optimize-autoloader
                                
                                echo "5. Running Unit Tests (On Remote)..."
                                # We run tests here to ensure the server environment is valid
                                php artisan test
                                
                                echo "6. Clearing Old Cache..."
                                php artisan config:clear
                                
                                echo "7. Running Migrations & Re-caching..."
                                php artisan migrate --force
                                php artisan config:cache
                                php artisan route:cache
                                php artisan view:cache
                                
                                echo "SUCCESS: Deployment Complete!"
                            '
                        """
                    }
                }
            }
        }
    }
}
