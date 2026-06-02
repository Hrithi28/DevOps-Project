terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  # Store state remotely in S3 (recommended for teams)
  backend "s3" {
    bucket         = "devops-project-tfstate"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ─── VPC / Networking ────────────────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

# ─── IAM Roles ───────────────────────────────────────────────────────────────
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

# ─── EKS Cluster (use this for Kubernetes) ───────────────────────────────────
module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  cluster_version    = var.eks_cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  node_instance_type = var.node_instance_type
  node_desired_size  = var.node_desired_size
  node_min_size      = var.node_min_size
  node_max_size      = var.node_max_size
  eks_role_arn       = module.iam.eks_cluster_role_arn
  node_role_arn      = module.iam.eks_node_role_arn
}

# ─── EC2 Instance (Jenkins server) ───────────────────────────────────────────
module "ec2" {
  source = "./modules/ec2"

  project_name    = var.project_name
  environment     = var.environment
  ami_id          = var.jenkins_ami_id
  instance_type   = var.jenkins_instance_type
  subnet_id       = module.vpc.public_subnet_ids[0]
  vpc_id          = module.vpc.vpc_id
  key_name        = var.key_name
  jenkins_role_arn = module.iam.jenkins_role_arn
}
