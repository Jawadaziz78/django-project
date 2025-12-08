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
        stage('Test') {
            steps {
                script {
                    echo "Skipping local tests (PHP not installed on Jenkins agent)" 
                }
            }
        }

        stage('Deploy to Remote Server') {
            steps {
                sshagent(credentials: [CREDENTIALS_ID]) {
                    script {
                        echo "Deploying to ${REMOTE_HOST}..."
                        sh """
                            ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                                # Stop pipeline immediately if any command fails
                                set -e
                                
                                echo "1. Navigating to Git Project..."
                                cd ${PROJECT_DIR}
                                
                                echo "2. Pulling latest code..."
                                git pull origin main
                                
                                echo "3. Entering App Directory..."
                                cd ${APP_DIR}
                                
                                echo "4. Installing Dependencies..."
                                composer install --no-interaction --prefer-dist --optimize-autoloader
                                
                                echo "5. Running Unit Tests (Using In-Memory DB)..."
                                # The "|| exit 1" ensures Jenkins fails if tests fail
                                DB_CONNECTION=sqlite DB_DATABASE=:memory: php artisan test || exit 1
                                
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
