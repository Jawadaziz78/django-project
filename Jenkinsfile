pipeline {
    agent any

    environment {
        // --- CONFIGURATION ---
        // 1. The ID of the SSH key you added to Jenkins Credentials
        CREDENTIALS_ID = 'deploy-server-key' 
        
        // 2. The Private IP of your Laravel Instance (from your screenshot)
        REMOTE_HOST = '172.31.77.148' 
        
        // 3. The username on the remote server
        REMOTE_USER = 'ubuntu' 
        
        // 4. The path to your project (Based on your image)
        PROJECT_DIR = '/home/ubuntu/projects/laravel' 
    }

    stages {
        stage('Deploy to Remote Server') {
            steps {
                // This plugin injects the SSH key so we can log in without a password
                sshagent(credentials: [CREDENTIALS_ID]) {
                    script {
                        echo "Deploying to ${REMOTE_HOST}..."
                        // We use SSH to run these commands ON the remote server
                        sh """
                            ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} '
                                # Stop errors if commands fail
                                set -e
                                
                                echo "Navigating to project directory..."
                                cd ${PROJECT_DIR}
                                
                                echo "Pulling latest code..."
                                git pull origin main
                                
                                echo "Installing Dependencies..."
                                # Install PHP dependencies
                                composer install --no-interaction --prefer-dist --optimize-autoloader
                                
                                echo "Running Migrations & Clearing Cache..."
                                php artisan migrate --force
                                php artisan config:cache
                                php artisan route:cache
                                php artisan view:cache
                                
                                echo "Deployment Complete!"
                            '
                        """
                    }
                }
            }
        }
    }
}
