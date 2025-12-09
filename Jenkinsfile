pipeline {
    agent any

    environment {
        DEPLOY_HOST = '172.31.77.148'
        DEPLOY_USER = 'ubuntu'
        
        // CHANGE THIS VALUE: 'laravel', 'vue', or 'nextjs'
        PROJECT_TYPE = 'laravel'
    }

    stages {
        stage('Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh """
                        # Pass variables as arguments ($1, $2) to avoid quote issues
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} 'bash -s' << 'ENDSSH' "${PROJECT_TYPE}" "${BRANCH_NAME}"
                            
                            # 1. READ ARGUMENTS
                            TYPE=\$1
                            BRANCH=\${2:-main} # Default to main if empty

                            # Stop on error
                            set -e

                            echo "--------------------------------------"
                            echo "🚀 DEPLOYING: \$TYPE (Branch: \$BRANCH)"
                            echo "--------------------------------------"

                            # 2. SWITCH LOGIC
                            case "\$TYPE" in
                                laravel)
                                    cd /home/ubuntu/projects/laravel
                                    REPO_URL="https://github.com/Jawadaziz78/django-project.git"
                                    
                                    # Set Remote
                                    git remote set-url origin \$REPO_URL
                                    
                                    # Fetch & Reset
                                    git fetch origin
                                    git reset --hard origin/\$BRANCH
                                    
                                    # Build (Run commands directly)
                                    echo "⚙️ Running Laravel Build..."
                                    php artisan optimize:clear
                                    php artisan config:cache
                                    php artisan route:cache
                                    php artisan view:cache
                                    ;;

                                vue)
                                    cd /home/ubuntu/projects/vue/app
                                    REPO_URL="https://github.com/Jawadaziz78/vue-project.git"
                                    
                                    git remote set-url origin \$REPO_URL
                                    git fetch origin
                                    git reset --hard origin/\$BRANCH
                                    
                                    echo "⚙️ Running Vue Build..."
                                    npm run build
                                    ;;

                                nextjs)
                                    cd /home/ubuntu/projects/nextjs/blog
                                    REPO_URL="https://github.com/Jawadaziz78/nextjs-project.git"
                                    
                                    git remote set-url origin \$REPO_URL
                                    git fetch origin
                                    git reset --hard origin/\$BRANCH
                                    
                                    echo "⚙️ Running Next.js Build..."
                                    cd web
                                    npm run build
                                    ;;

                                *)
                                    echo "❌ Error: Unknown Project Type: \$TYPE"
                                    exit 1
                                    ;;
                            esac

                            echo "✅ SUCCESS"
                        ENDSSH
                    """
                }
            }
        }
    }
}
