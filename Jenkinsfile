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
                                # Stop pipeline immediately if any command fails
                                set -e
                                
                                echo "1. Navigating to Git Project..."
                                cd ${PROJECT_DIR}
                                
                                echo "2. Pulling latest code..."
                                git pull origin main
                                
                                echo "3. Entering App Directory..."
                                cd ${APP_DIR}
                                
                                echo "4. Clearing Old Config (CRITICAL STEP)..."
                                # We MUST clear the cache BEFORE installing dependencies or running tests
                                # otherwise Laravel ignores our DB_CONNECTION=sqlite override.
                                php artisan config:clear
                                
                                echo "5. Installing Dependencies..."
                                composer install --no-interaction --prefer-dist --optimize-autoloader
                                
                                echo "6. Running Unit Tests (Using In-Memory DB)..."
                                # The "|| exit 1" ensures Jenkins stops and marks as FAILURE if tests fail
                                DB_CONNECTION=sqlite DB_DATABASE=:memory: php artisan test || exit 1
                                
                                echo "7. Running Migrations & Re-caching..."
                                php artisan migrate --force
                                
                                echo "8. Fixing Permissions (Prevents HTTP 500 Error)..."
                                # Automatically fix permissions for the web server
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
