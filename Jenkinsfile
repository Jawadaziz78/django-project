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
        stage('Deploy to Remote Server') {
            steps {
                sshagent(credentials: [CREDENTIALS_ID]) {
                    script {
                        echo "Deploying to ${REMOTE_HOST}..."
                        sh """
                            ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                                # Stop the script immediately if any command fails
                                set -e
                                
                                echo "1. Navigating to Git Project..."
                                cd ${PROJECT_DIR}
                                
                                echo "2. Pulling latest code..."
                                git pull origin main
                                
                                echo "3. Entering App Directory..."
                                cd ${APP_DIR}
                                
                                echo "4. Clearing Old Config (Crucial for Tests)..."
                                # Must run this BEFORE tests so Laravel accepts the SQLite change
                                php artisan config:clear
                                
                                echo "5. Installing Dependencies..."
                                composer install --no-interaction --prefer-dist --optimize-autoloader
                                
                                echo "6. Running Unit Tests (Using In-Memory DB)..."
                                # "|| exit 1" ensures Jenkins stops if tests fail
                                DB_CONNECTION=sqlite DB_DATABASE=:memory: php artisan test || exit 1
                                
                                echo "7. Running Migrations..."
                                php artisan migrate --force
                                
                                echo "8. Fixing Permissions (Prevents HTTP 500 Error)..."
                                # This allows the web server to write to logs/cache
                                sudo chmod -R 777 storage bootstrap/cache
                                
                                echo "9. Optimizing Application..."
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
