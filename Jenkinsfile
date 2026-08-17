pipeline {
    agent any

    environment {
        APP_NAME = "devops-demo-app"
        DOCKER_REGISTRY = "hrith"
        IMAGE_NAME = "${DOCKER_REGISTRY}/${APP_NAME}"

        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')

        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                echo "Checking out source code..."
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"

                    sh """
                        docker build \
                            --build-arg APP_VERSION=${IMAGE_TAG} \
                            --tag ${IMAGE_NAME}:${IMAGE_TAG} \
                            --tag ${IMAGE_NAME}:latest \
                            --file Dockerfile \
                            .
                    """
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    echo "Building tester image..."

                    sh """
                        docker build \
                            --target tester \
                            --tag devops-demo-app-tester \
                            .
                    """

                    echo "Running tests..."

                    sh """
                        docker run --rm \
                            --name test-runner \
                            devops-demo-app-tester \
                            sh -c "npm test -- --forceExit"
                    """
                }
            }

            post {
                always {
                    echo "Test stage complete"
                }
            }
        }

        stage('Security Scan') {
            steps {
                script {
                    echo "Running Trivy vulnerability scan..."

                    sh """
                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            aquasec/trivy:latest image \
                            --exit-code 0 \
                            --severity HIGH,CRITICAL \
                            ${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    echo "Logging into Docker Hub..."

                    sh """
                        echo "${DOCKER_CREDENTIALS_PSW}" | docker login \
                            -u "${DOCKER_CREDENTIALS_USR}" \
                            --password-stdin
                    """

                    echo "Pushing ${IMAGE_NAME}:${IMAGE_TAG}..."

                    sh """
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline SUCCESS — ${APP_NAME}:${IMAGE_TAG} deployed"
        }

        failure {
            echo "Pipeline FAILED — check the console logs above"
        }

        always {
            script {
                sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
                sh "docker rmi ${IMAGE_NAME}:latest || true"
                sh "docker rmi devops-demo-app-tester || true"
            }

            cleanWs()
        }
    }
}
