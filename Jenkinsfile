pipeline {
    agent any

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Deploy to Remote Server') {
            steps {
                sshagent(credentials: ['ubuntu']) {
                    script {
                        echo "Deploying to 172.31.77.148..."
                        sh '''
                            ssh -o StrictHostKeyChecking=no ubuntu@172.31.77.148 '
                                # Exit immediately if a command exits with a non-zero status
                                set -e
                                
                                echo "1. Navigating to Git Project..."
                                cd /home/ubuntu/projects/laravel
                                
                                echo "2. Pulling latest code..."
                                git pull origin main
                                
                                echo "3. Entering App Directory..."
                                cd BookStack
                                
                                echo "4. Clearing Old Config..."
                                php artisan config:clear
                                php artisan cache:clear
                                
                                echo "5. Installing Dependencies..."
                                composer install --no-interaction --prefer-dist --optimize-autoloader
                                
                                echo "6. Preparing Environment & Running Tests..."
                                # Ensure permissions are correct for logging
                                sudo chmod -R 777 storage bootstrap/cache
                                
                                # --- FIX START ---
                                # Create a specific testing environment file
                                # This overrides the production .env settings shown in your image
                                cp .env.example .env.testing
                                
                                # Force SQLite and Memory Database in the testing config
                                sed -i "s/DB_CONNECTION=mysql/DB_CONNECTION=sqlite/" .env.testing
                                sed -i "s/DB_DATABASE=.*$/DB_DATABASE=:memory:/" .env.testing
                                
                                # Generate a key for the testing environment
                                php artisan key:generate --env=testing
                                
                                # Run tests using the testing environment explicitly
                                php artisan test --env=testing
                                
                                # Remove the testing env file to keep the server clean
                                rm .env.testing
                                # --- FIX END ---
                                
                                echo "7. Running Migrations on Production DB..."
                                # Back to standard environment vars for production migration
                                php artisan migrate --force
                                
                                echo "8. Final Permission Fix..."
                                sudo chmod -R 777 storage bootstrap/cache
                                
                                echo "9. Optimizing Application..."
                                php artisan config:cache
                                php artisan route:cache
                                php artisan view:cache
                                
                                echo "SUCCESS: Deployment Complete!"
                            '
                        '''
                    }
                }
            }
        }
    }
}
