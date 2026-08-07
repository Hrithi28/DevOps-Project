pipeline {
    agent any

    environment {
        APP_NAME = "devops-demo-app"
        DOCKER_REGISTRY = "hrith"
        IMAGE_NAME = "${DOCKER_REGISTRY}/${APP_NAME}"
        IMAGE_TAG = "${BUILD_NUMBER}"

        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
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
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build \
                    --tag ${IMAGE_NAME}:${IMAGE_TAG} \
                    --tag ${IMAGE_NAME}:latest \
                    -f Dockerfile .
                """
            }
        }

        stage('Security Scan') {
            steps {
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

        stage('Push to Docker Hub') {
            steps {
                sh """
                    echo "${DOCKER_CREDENTIALS_PSW}" | docker login \
                    -u "${DOCKER_CREDENTIALS_USR}" \
                    --password-stdin

                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${IMAGE_NAME}:latest
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
        }

        failure {
            echo "Pipeline failed."
        }

        always {
            sh "docker logout || true"
            sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
            cleanWs()
        }
    }
}
