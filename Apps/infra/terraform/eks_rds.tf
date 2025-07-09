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

# Get database credentials from AWS Secrets Manager
data "aws_secretsmanager_secret" "database" {
  name = "healthai2030/database"
}

data "aws_secretsmanager_secret_version" "database" {
  secret_id = data.aws_secretsmanager_secret.database.id
}

locals {
  database_creds = jsondecode(data.aws_secretsmanager_secret_version.database.secret_string)
}

resource "aws_rds_cluster" "main" {
  cluster_identifier = "healthai2030-db"
  engine            = "aurora-postgresql"
  master_username   = local.database_creds.username
  master_password   = local.database_creds.password
  
  # Security configurations
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn
  
  # Network security
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  # Backup and maintenance
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  
  # Deletion protection in production
  deletion_protection = true
  
  tags = {
    Name        = "healthai2030-database"
    Environment = "production"
    Security    = "high"
  }
}

# KMS key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for HealthAI 2030 RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name        = "healthai2030-rds-kms"
    Environment = "production"
  }
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "healthai2030-rds-"
  vpc_id      = aws_vpc.main.id
  
  # Allow PostgreSQL access from EKS cluster only
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks.id]
    description     = "PostgreSQL access from EKS cluster"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "healthai2030-rds-sg"
    Environment = "production"
  }
}

# DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "healthai2030-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  
  tags = {
    Name        = "healthai2030-db-subnet-group"
    Environment = "production"
  }
}

# Add outputs and more resources as needed
