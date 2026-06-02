# DevOps CI/CD Pipeline Project

Full DevOps lifecycle: Terraform → Docker → Jenkins → Kubernetes → Prometheus/Grafana

---

## Project Structure

```
devops-project/
├── app/                        # Node.js application
│   ├── server.js               # Express app with /metrics endpoint
│   ├── server.test.js          # Jest tests
│   └── package.json
├── Dockerfile                  # Multi-stage Docker build
├── Jenkinsfile                 # Declarative CI/CD pipeline
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # Root module
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/                # VPC, subnets, NAT gateway
│       ├── eks/                # EKS cluster + node group
│       ├── ec2/                # Jenkins server
│       └── iam/                # IAM roles for EKS + Jenkins
├── k8s/
│   ├── base/
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml     # Rolling update deployment
│   │   ├── service.yaml        # LoadBalancer + ClusterIP
│   │   └── hpa.yaml            # Horizontal Pod Autoscaler
│   └── monitoring/
│       ├── prometheus-values.yaml
│       └── servicemonitor.yaml
├── ansible/
│   ├── jenkins-setup.yml       # Jenkins plugin + config automation
│   └── inventory.ini
└── scripts/
    └── deploy.sh               # Full stack deploy helper
```

---

## Prerequisites

| Tool      | Version   | Install |
|-----------|-----------|---------|
| Terraform | >= 1.5    | https://developer.hashicorp.com/terraform/install |
| AWS CLI   | >= 2.0    | https://aws.amazon.com/cli/ |
| Docker    | >= 24     | https://docs.docker.com/get-docker/ |
| kubectl   | >= 1.28   | https://kubernetes.io/docs/tasks/tools/ |
| Helm      | >= 3.12   | https://helm.sh/docs/intro/install/ |

---

## Step-by-Step Setup

### 1. Clone & configure
```bash
git clone https://github.com/YOUR_USERNAME/devops-project.git
cd devops-project

# Configure Terraform variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your AWS settings and key pair name
```

### 2. Provision infrastructure
```bash
./scripts/deploy.sh infra-up
# OR manually:
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Configure Jenkins
```bash
# SSH to Jenkins server
ssh -i ~/.ssh/your-key.pem ec2-user@$(cd terraform && terraform output -raw jenkins_public_ip)

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
Open `http://JENKINS_IP:8080` and complete the setup wizard. Then add credentials:
- `dockerhub-credentials` — Docker Hub username/password
- `kubeconfig` — contents of `~/.kube/config` after running the kubeconfig command

### 4. Set up GitHub webhook
In your GitHub repo → Settings → Webhooks:
- Payload URL: `http://JENKINS_IP:8080/github-webhook/`
- Content type: `application/json`
- Trigger: Push events

### 5. Deploy to Kubernetes
```bash
./scripts/deploy.sh k8s-deploy
```

### 6. Install monitoring
```bash
./scripts/deploy.sh monitoring

# Access Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
# Open http://localhost:3000 — user: admin / pass: admin
```

---

## Application Endpoints

| Endpoint   | Description                    |
|------------|--------------------------------|
| `/`        | Welcome + version info         |
| `/health`  | Liveness check                 |
| `/ready`   | Readiness check                |
| `/metrics` | Prometheus metrics             |
| `/api/info`| App metadata                   |

---

## CI/CD Pipeline Stages

1. **Checkout** — pull latest code from GitHub
2. **Build** — `docker build` multi-stage image
3. **Test** — run Jest test suite inside container
4. **Security scan** — Trivy image vulnerability scan (main branch only)
5. **Push** — push tagged image to Docker Hub / ECR
6. **Update manifests** — inject new image tag into `deployment.yaml`
7. **Deploy** — `kubectl apply` with rollout status watch
8. **Smoke test** — hit `/health` on the live LoadBalancer URL

---

## Tear Down

```bash
./scripts/deploy.sh k8s-destroy    # Remove K8s resources
./scripts/deploy.sh infra-down     # Destroy AWS infrastructure
```

---

## Submission Checklist

- [ ] GitHub repository with all code
- [ ] Dockerfile + Jenkinsfile
- [ ] Terraform files (all modules)
- [ ] Kubernetes YAML files
- [ ] Monitoring dashboard screenshots
- [ ] Architecture diagram
- [ ] Final project report
