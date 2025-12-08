pipeline {
    agent any

    environment {
        // --- CONFIGURATION ---
        // 1. Your Server details
        REMOTE_HOST = '172.31.77.148'
        REMOTE_USER = 'ubuntu'
        
        // 2. The path to the main GIT folder
        PROJECT_DIR = '/home/ubuntu/projects/laravel'
        
        // 3. The sub-folder where the actual Laravel code lives
        APP_DIR = 'BookStack'
        
        // 4. The ID of the key you added to Jenkins Credentials
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
                                # Stop pipeline if any command fails
                                set -e
                                
                                echo "1. Navigating to Git Project..."
                                cd ${PROJECT_DIR}
                                
                                echo "2. Pulling latest code..."
                                # This works because you saved credentials manually earlier
                                git pull origin main
                                
                                echo "3. Entering App Directory..."
                                cd ${APP_DIR}
                                
                                echo "4. Installing Dependencies..."
                                composer install --no-interaction --prefer-dist --optimize-autoloader
                                
                                echo "5. Clearing Old Cache (Fixes Configuration Issues)..."
                                # This ensures Laravel sees your .env file changes immediately
                                php artisan config:clear
                                
                                echo "6. Running Migrations & Re-caching..."
                                # --force is required to bypass the "Are you sure?" prompt
                                php artisan migrate --force
                                
                                # Re-build the cache for speed
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
