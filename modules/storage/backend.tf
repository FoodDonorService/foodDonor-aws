# Terraform Backend Resources (S3 + DynamoDB)
# These resources should be created BEFORE enabling backend configuration
# Create them with: terraform apply -target=module.storage.aws_s3_bucket.terraform_state

locals {
  backend_bucket_name = "${var.project_name}-${var.terraform_state_bucket_name}-${var.env}"
  backend_table_name  = "${var.project_name}-${var.terraform_lock_table_name}-${var.env}"
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.backend_bucket_name

  tags = {
    Name        = local.backend_bucket_name
    Environment = var.env
    Project     = var.project_name
    Purpose     = "Terraform State Storage"
  }
}

# Enable versioning for state file
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.backend_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = local.backend_table_name
    Environment = var.env
    Project     = var.project_name
    Purpose     = "Terraform State Locking"
  }
}
