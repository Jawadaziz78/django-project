pipeline {
    agent any

    environment {
        DEPLOY_HOST = '172.31.77.148'
        DEPLOY_USER = 'ubuntu'
        
     
        PROJECT_TYPE = 'laravel'
    }

    stages {
        stage('Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    // USE TRIPLE SINGLE QUOTES (''') TO PREVENT GROOVY ERRORS
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            set -e
                            
                            echo '-----------------------------------'
                            echo '🚀 DEPLOYING: ${PROJECT_TYPE}'
                            echo '-----------------------------------'

                            # The local Jenkins shell expands ${PROJECT_TYPE} before sending to server
                            case \\"${PROJECT_TYPE}\\" in
                                laravel)
                                    # LARAVEL CONFIG
                                    cd /home/ubuntu/projects/laravel
                                    
                                    # Update Code
                                    git remote set-url origin https://github.com/Jawadaziz78/django-project.git
                                    git fetch origin
                                    # Shell expands BRANCH_NAME or defaults to 'main'
                                    git reset --hard origin/${BRANCH_NAME:-main}
                                    
                                    # Build
                                    echo '⚙️ Running Laravel Build...'
                                    php artisan optimize:clear
                                    php artisan config:cache
                                    php artisan route:cache
                                    php artisan view:cache
                                    ;;
                                
                                vue)
                                    # VUE CONFIG
                                    cd /home/ubuntu/projects/vue/app
                                    
                                    git remote set-url origin https://github.com/Jawadaziz78/vue-project.git
                                    git fetch origin
                                    git reset --hard origin/${BRANCH_NAME:-main}
                                    
                                    # Build
                                    echo '⚙️ Running Vue Build...'
                                    npm run build
                                    ;;
                                
                                nextjs)
                                    # NEXTJS CONFIG
                                    cd /home/ubuntu/projects/nextjs/blog
                                    
                                    git remote set-url origin https://github.com/Jawadaziz78/nextjs-project.git
                                    git fetch origin
                                    git reset --hard origin/${BRANCH_NAME:-main}
                                    
                                    # Build inside 'web' folder
                                    echo '⚙️ Running Next.js Build...'
                                    cd web
                                    npm run build
                                    ;;
                                
                                *)
                                    echo '❌ Error: PROJECT_TYPE value in Jenkinsfile is incorrect.'
                                    exit 1
                                    ;;
                            esac
                            
                            echo '✅ SUCCESS'
                        "
                    '''
                }
            }
        }
    }
}
