variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_eks_cluster" "main" {
  name     = "healthai2030-eks"
  role_arn = "arn:aws:iam::123456789012:role/eks-service-role" # Replace with your IAM role

  vpc_config {
    subnet_ids = ["subnet-abc123", "subnet-def456"] # Replace with your subnet IDs
  }
}

resource "aws_rds_cluster" "main" {
  cluster_identifier = "healthai2030-db"
  engine            = "aurora-postgresql"
  master_username   = "admin"
  master_password   = "changeMe123!" # Use secrets manager in production
}

# Add outputs and more resources as needed
