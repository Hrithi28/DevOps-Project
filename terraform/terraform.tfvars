# terraform.tfvars  –  DO NOT commit real values to Git
# Copy this file to terraform.tfvars and fill in your values

aws_region   = "us-east-1"
project_name = "devops-demo"
environment  = "dev"

# Networking
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets    = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# EKS
eks_cluster_version = "1.28"
node_instance_type  = "t3.micro"
node_desired_size   = 1
node_min_size       = 1
node_max_size       = 1

# EC2 / Jenkins
jenkins_ami_id        = "ami-0bdc7d025135d7b49" # Amazon Linux 2023 us-east-1
jenkins_instance_type = "t3.micro"
key_name              = "devops-key" # Replace with your key pair
