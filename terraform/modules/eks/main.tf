# ─── EKS Control Plane ────────────────────────────────────────────────────────
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-cluster"
  version  = var.cluster_version
  role_arn = var.eks_role_arn

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true

    public_access_cidrs = ["0.0.0.0/0"]  # Restrict in production
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [var.eks_role_arn]

  tags = { Name = "${var.project_name}-eks-cluster" }
}

# ─── EKS Node Group ───────────────────────────────────────────────────────────
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  instance_types = [var.node_instance_type]
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1  # Rolling update: 1 node at a time
  }

  labels = {
    role        = "worker"
    environment = var.environment
  }

  tags = { Name = "${var.project_name}-node-group" }
}

# ─── Outputs ──────────────────────────────────────────────────────────────────
output "cluster_name"                  { value = aws_eks_cluster.main.name }
output "cluster_endpoint"              { value = aws_eks_cluster.main.endpoint }
output "cluster_certificate_authority" { value = aws_eks_cluster.main.certificate_authority[0].data }
output "cluster_version"               { value = aws_eks_cluster.main.version }
