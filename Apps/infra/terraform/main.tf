provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "healthai2030-example-bucket"
  acl    = "private"
}

# Add more resources (EKS, RDS, etc.) as needed
