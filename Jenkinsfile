pipeline {
    agent any

    environment {
        DEPLOY_HOST = '172.31.77.148'
        DEPLOY_USER = 'ubuntu'
        
        // CHANGE THIS: 'laravel', 'vue', or 'nextjs'
        PROJECT_TYPE = 'laravel'
    }

    stages {
        stage('Build') {
            steps {
                sshagent(['deploy-server-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${DEPLOY_USER}@${DEPLOY_HOST} "
                            set -e

                            case \"${PROJECT_TYPE}\" in
                                laravel)
                                    PROJECT_DIR=\"/home/ubuntu/projects/laravel\"
                                    REPO_URL=\"https://github.com/Jawadaziz78/django-project.git\"
                                    BUILD_CMD=\"php artisan optimize:clear && php artisan config:cache && php artisan route:cache && php artisan view:cache\"
                                    ;;
                                vue)
                                    PROJECT_DIR=\"/home/ubuntu/projects/vue/app\"
                                    REPO_URL=\"https://github.com/Jawadaziz78/vue-project.git\"
                                    BUILD_CMD=\"npm run build\"
                                    ;;
                                nextjs)
                                    PROJECT_DIR=\"/home/ubuntu/projects/nextjs/blog\"
                                    REPO_URL=\"https://github.com/Jawadaziz78/nextjs-project.git\"
                                    # 'cd web' is required based on your directory structure
                                    BUILD_CMD=\"cd web && npm run build\"
                                    ;;
                                *)
                                    exit 1
                                    ;;
                            esac

                            cd \${PROJECT_DIR}

                            # Force the correct remote URL directly
                            git remote set-url origin \${REPO_URL}

                            # Fetch and reset to the branch (Defaults to 'main' if BRANCH_NAME is not set)
                            git fetch origin
                            git reset --hard origin/${BRANCH_NAME:-main}

                            \${BUILD_CMD}
                        "
                    '''
                }
            }
        }
    }
}
