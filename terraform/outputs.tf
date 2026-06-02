output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_cluster_certificate" {
  description = "Base64-encoded certificate authority for the EKS cluster"
  value       = module.eks.cluster_certificate_authority
  sensitive   = true
}

output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins EC2 instance"
  value       = module.ec2.jenkins_public_ip
}

output "jenkins_url" {
  description = "Jenkins web UI URL"
  value       = "http://${module.ec2.jenkins_public_ip}:8080"
}

output "kubeconfig_command" {
  description = "AWS CLI command to update local kubeconfig for EKS"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
