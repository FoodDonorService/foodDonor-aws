variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "s3_bucket_names" {
  description = "S3 bucket names (without prefix)"
  type = object({
    frontend       = string
    raw_data       = string
    processed_data = string
    athena_results = string
    glue_assets    = string
    public_data    = string
  })
}

variable "terraform_state_bucket_name" {
  description = "S3 bucket name for Terraform state (without prefix)"
  type        = string
  default     = "terraform-state"
}

variable "terraform_lock_table_name" {
  description = "DynamoDB table name for Terraform state locking (without prefix)"
  type        = string
  default     = "terraform-locks"
}

data "aws_caller_identity" "current" {}
