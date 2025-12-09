pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        DEPLOY_HOST = '172.31.77.148'
        DEPLOY_USER = 'ubuntu'
        
        // --------------------------------------------------------
        // CHANGE THIS VALUE: 'laravel', 'vue', or 'nextjs'
        // --------------------------------------------------------
        PROJECT_TYPE = 'laravel'
    }

    stages {
        stage('Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    // Using triple single quotes (''') prevents the Groovy syntax error
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            set -e
                            
                            echo '-----------------------------------'
                            echo '🚀 DEPLOYING: ${PROJECT_TYPE}'
                            echo '-----------------------------------'

                            # Jenkins injects PROJECT_TYPE and BRANCH_NAME as shell env variables
                            case \\"${PROJECT_TYPE}\\" in
                                laravel)
                                    # LARAVEL CONFIG
                                    cd /home/ubuntu/projects/laravel
                                    
                                    git remote set-url origin https://github.com/Jawadaziz78/django-project.git
                                    git fetch origin
                                    git reset --hard origin/${BRANCH_NAME:-main}
                                    
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
