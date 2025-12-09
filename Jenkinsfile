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
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            set -e
                            
                            # Define Branch (Default to 'main' if empty)
                            TARGET_BRANCH='${BRANCH_NAME:-main}'

                            echo '--------------------------------------'
                            echo '🚀 DEPLOYING PROJECT: ${PROJECT_TYPE}'
                            echo '--------------------------------------'

                            # DIRECT EXECUTION - NO EVAL, NO COMPLEX VARIABLES
                            case '${PROJECT_TYPE}' in
                                laravel)
                                    cd /home/ubuntu/projects/laravel
                                    
                                    # Git Update
                                    git remote set-url origin https://github.com/Jawadaziz78/django-project.git
                                    git fetch origin
                                    git reset --hard origin/\\\$TARGET_BRANCH
                                    
                                    # Build Commands
                                    echo '⚙️ Running Laravel Build...'
                                    php artisan optimize:clear
                                    php artisan config:cache
                                    php artisan route:cache
                                    php artisan view:cache
                                    ;;

                                vue)
                                    cd /home/ubuntu/projects/vue/app
                                    
                                    # Git Update
                                    git remote set-url origin https://github.com/Jawadaziz78/vue-project.git
                                    git fetch origin
                                    git reset --hard origin/\\\$TARGET_BRANCH
                                    
                                    # Build Commands
                                    echo '⚙️ Running Vue Build...'
                                    npm run build
                                    ;;

                                nextjs)
                                    cd /home/ubuntu/projects/nextjs/blog
                                    
                                    # Git Update
                                    git remote set-url origin https://github.com/Jawadaziz78/nextjs-project.git
                                    git fetch origin
                                    git reset --hard origin/\\\$TARGET_BRANCH
                                    
                                    # Build Commands
                                    echo '⚙️ Running Next.js Build...'
                                    cd web
                                    npm run build
                                    ;;

                                *)
                                    echo '❌ Error: Unknown Project Type'
                                    exit 1
                                    ;;
                            esac

                            echo '✅ SUCCESS'
                        "
                    """
                }
            }
        }
    }
}
