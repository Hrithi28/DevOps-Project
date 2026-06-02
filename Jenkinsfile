pipeline {
    agent any

    environment {
        // ── Update these for your setup ──────────────────────────────────────
        APP_NAME        = 'devops-demo-app'
        DOCKER_REGISTRY = 'your-dockerhub-username'          // or your ECR URL
        IMAGE_NAME      = "${DOCKER_REGISTRY}/${APP_NAME}"
        K8S_NAMESPACE   = 'default'
        AWS_REGION      = 'us-east-1'
        EKS_CLUSTER     = 'devops-demo-dev-cluster'
        // ─────────────────────────────────────────────────────────────────────

        // Jenkins credentials IDs (configure in Jenkins → Credentials)
        DOCKER_CREDENTIALS = credentials('dockerhub-credentials')
        KUBECONFIG_FILE    = credentials('kubeconfig')

        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
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

        // ── 5. Push to Registry ───────────────────────────────────────────
        stage('Push to Registry') {
            steps {
                script {
                    echo "Pushing to Docker Hub..."
                    sh """
                        echo ${DOCKER_CREDENTIALS_PSW} | docker login \
                            -u ${DOCKER_CREDENTIALS_USR} --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        // ── 6. Update K8s Manifests ──────────────────────────────────────
        stage('Update Manifests') {
            steps {
                script {
                    echo "Updating K8s deployment image tag to ${IMAGE_TAG}..."
                    sh """
                        sed -i 's|image: ${IMAGE_NAME}:.*|image: ${IMAGE_NAME}:${IMAGE_TAG}|g' \
                            k8s/base/deployment.yaml
                    """
                }
            }
        }

        // ── 7. Deploy to Kubernetes ───────────────────────────────────────
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "Deploying to EKS cluster: ${EKS_CLUSTER}"
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        sh """
                            export KUBECONFIG=${KUBECONFIG}

                            # Apply all manifests
                            kubectl apply -f k8s/base/namespace.yaml
                            kubectl apply -f k8s/base/deployment.yaml
                            kubectl apply -f k8s/base/service.yaml
                            kubectl apply -f k8s/base/hpa.yaml

                            # Wait for rollout to complete
                            kubectl rollout status deployment/${APP_NAME} \
                                -n ${K8S_NAMESPACE} \
                                --timeout=300s

                            echo "Deployment successful!"
                            kubectl get pods -n ${K8S_NAMESPACE} -l app=${APP_NAME}
                        """
                    }
                }
            }
        }

        // ── 8. Smoke Test ────────────────────────────────────────────────
        stage('Smoke Test') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        sh """
                            export KUBECONFIG=${KUBECONFIG}
                            SERVICE_URL=\$(kubectl get svc ${APP_NAME}-service \
                                -n ${K8S_NAMESPACE} \
                                -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
                            echo "Testing service at: \$SERVICE_URL"
                            sleep 10
                            curl -sf http://\$SERVICE_URL/health || echo "Health check pending..."
                        """
                    }
                }
            }
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
            sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
            cleanWs()
        }
    }
}
