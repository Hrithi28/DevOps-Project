#!/bin/bash
# scripts/deploy.sh — Full stack deploy / teardown helper
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

usage() {
  echo "Usage: $0 {infra-up|infra-down|k8s-deploy|k8s-destroy|all|status}"
  exit 1
}

check_prereqs() {
  log "Checking prerequisites..."
  for cmd in terraform kubectl docker aws; do
    command -v $cmd &>/dev/null || err "$cmd not found. Install it first."
  done
  log "All prerequisites found."
}

infra_up() {
  log "Provisioning AWS infrastructure with Terraform..."
  cd terraform
  terraform init
  terraform validate
  terraform plan -out=tfplan
  read -rp "Apply? (yes/no): " confirm
  [[ "$confirm" == "yes" ]] || err "Aborted."
  terraform apply tfplan
  log "Infrastructure ready!"
  terraform output
  cd ..
}

infra_down() {
  warn "This will DESTROY all AWS infrastructure!"
  read -rp "Type 'destroy' to confirm: " confirm
  [[ "$confirm" == "destroy" ]] || err "Aborted."
  cd terraform
  terraform destroy -auto-approve
  cd ..
  log "Infrastructure destroyed."
}

k8s_deploy() {
  log "Deploying application to Kubernetes..."
  CLUSTER=$(cd terraform && terraform output -raw eks_cluster_name)
  REGION=$(cd terraform && terraform output -raw aws_region 2>/dev/null || echo "us-east-1")

  aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER"

  kubectl apply -f k8s/base/namespace.yaml
  kubectl apply -f k8s/base/deployment.yaml
  kubectl apply -f k8s/base/service.yaml
  kubectl apply -f k8s/base/hpa.yaml

  kubectl rollout status deployment/devops-demo-app --timeout=300s
  log "Application deployed!"
  kubectl get pods,svc -l app=devops-demo-app
}

k8s_destroy() {
  warn "Removing Kubernetes resources..."
  kubectl delete -f k8s/base/ --ignore-not-found=true
  log "K8s resources removed."
}

monitoring_install() {
  log "Installing Prometheus + Grafana via Helm..."
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update
  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring --create-namespace \
    --values k8s/monitoring/prometheus-values.yaml \
    --wait
  kubectl apply -f k8s/monitoring/servicemonitor.yaml
  log "Monitoring stack installed!"
  log "Grafana: kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring"
}

status() {
  log "Cluster status:"
  kubectl get nodes
  echo ""
  log "Application pods:"
  kubectl get pods -l app=devops-demo-app
  echo ""
  log "Services:"
  kubectl get svc -l app=devops-demo-app
}

[[ $# -eq 0 ]] && usage

case "$1" in
  infra-up)          check_prereqs; infra_up ;;
  infra-down)        infra_down ;;
  k8s-deploy)        check_prereqs; k8s_deploy ;;
  k8s-destroy)       k8s_destroy ;;
  monitoring)        monitoring_install ;;
  status)            status ;;
  all)               check_prereqs; infra_up; k8s_deploy; monitoring_install; status ;;
  *)                 usage ;;
esac
