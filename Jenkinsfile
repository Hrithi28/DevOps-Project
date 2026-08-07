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

        // ── 1. Checkout ────────────────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo "Checking out branch: ${GIT_BRANCH}"
                checkout scm
            }
        }

        // ── 2. Build Docker Image ─────────────────────────────────────────
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

        // ── 3. Run Tests ──────────────────────────────────────────────────
        stage('Run Tests') {
            steps {
                script {
                    echo "Running tests inside container..."
                    sh """
                        docker run --rm \
                            --name test-runner \
                            ${IMAGE_NAME}:${IMAGE_TAG} \
                            sh -c "npm test"
                    """
                }
            }
            post {
                always {
                    // Publish test results if you use JUnit reporter
                    // junit 'app/coverage/junit.xml'
                    echo "Test stage complete"
                }
            }
        }
/*
        // ── 4. Security Scan (optional, recommended) ──────────────────────
        stage('Security Scan') {
            when { branch 'main' }
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
        */
        

        // ── 5. Push to Registry ───────────────────────────────────────────
        stage('Push to Registry') {
    steps {
        echo "Pushing to Docker Hub..."
        sh """
            echo "${DOCKER_CREDENTIALS_PSW}" | docker login -u "${DOCKER_CREDENTIALS_USR}" --password-stdin
            docker push ${IMAGE_NAME}:${IMAGE_TAG}
            docker push ${IMAGE_NAME}:latest
        """
    }
}

    post {
        success {
            echo "Pipeline SUCCESS — ${APP_NAME}:${IMAGE_TAG} deployed"
            // slackSend(color: 'good', message: "Deployed ${APP_NAME}:${IMAGE_TAG}")
        }
        failure {
            echo "Pipeline FAILED — check logs above"
            // slackSend(color: 'danger', message: "FAILED: ${APP_NAME} build ${BUILD_NUMBER}")
        }
        always {
    script {
        sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
    }
    cleanWs()
}
    }
}
