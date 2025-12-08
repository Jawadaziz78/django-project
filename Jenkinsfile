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
                                
                                echo "4. Clearing Old Config..."
                                php artisan config:clear
                                
                                echo "5. Installing Dependencies..."
                                composer install --no-interaction --prefer-dist --optimize-autoloader
                                
                                echo "6. Preparing Environment & Running Tests..."
                                # We fix permissions NOW so tests can write to logs
                                sudo chmod -R 777 storage bootstrap/cache
                                
                                # EXPORT variables ensures they apply to the PHPUnit subprocess
                                export APP_ENV=testing
                                export DB_CONNECTION=sqlite
                                export DB_DATABASE=:memory:
                                
                                # Run the tests. If this fails, the pipeline stops.
                                php artisan test
                                
                                echo "7. Running Migrations..."
                                # Unset testing vars to ensure we migrate the REAL database
                                unset DB_CONNECTION
                                unset DB_DATABASE
                                php artisan migrate --force
                                
                                echo "8. Final Permission Fix..."
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
