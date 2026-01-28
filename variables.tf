variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "food-donor"
}

variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Cognito User Pool
variable "cognito_user_pool_name" {
  description = "Cognito User Pool name"
  type        = string
  default     = "food-donor-user-pool"
}

variable "cognito_user_pool_client_name" {
  description = "Cognito User Pool Client name"
  type        = string
  default     = "food-donor"
}

variable "cognito_issuer_url" {
  description = "Cognito Issuer URL (will be constructed from user pool ID)"
  type        = string
  default     = ""
}

variable "cognito_client_id" {
  description = "Cognito Client ID (will be output from user pool client)"
  type        = string
  default     = ""
}

# API Gateway
variable "api_gateway_stage" {
  description = "API Gateway stage name"
  type        = string
  default     = "v0"
}

# Lambda Configuration
variable "lambda_runtime" {
  description = "Default Lambda runtime"
  type        = string
  default     = "nodejs22.x"
}

variable "lambda_memory_size" {
  description = "Default Lambda memory size"
  type        = number
  default     = 128
}

# Glue Configuration
variable "glue_version" {
  description = "Glue version"
  type        = string
  default     = "4.0"
}

variable "glue_worker_type" {
  description = "Glue worker type"
  type        = string
  default     = "G.1X"
}

variable "glue_number_of_workers" {
  description = "Number of Glue workers"
  type        = number
  default     = 2
}

# S3 Bucket Names (will be prefixed with project_name and env)
variable "s3_bucket_names" {
  description = "S3 bucket names (without prefix)"
  type = object({
    frontend        = string
    raw_data        = string
    processed_data  = string
    athena_results  = string
    glue_assets     = string
    public_data     = string
  })
  default = {
    frontend       = "frontend"
    raw_data       = "raw-data"
    processed_data = "processed-data"
    athena_results = "athena-results"
    glue_assets    = "glue-assets"
    public_data    = "public-data"
  }
}

# DynamoDB Table Names
variable "dynamodb_table_names" {
  description = "DynamoDB table names"
  type = object({
    donor          = string
    recipient      = string
    volunteer      = string
    donation       = string
    volunteer_match = string
    task           = string
  })
  default = {
    donor          = "donor"
    recipient      = "recipient"
    volunteer      = "volunteer"
    donation       = "donation"
    volunteer_match = "volunteer_match"
    task           = "task"
  }
}

# SQS Queue Names
variable "sqs_queue_names" {
  description = "SQS queue names"
  type = object({
    match_queue = string
  })
  default = {
    match_queue = "match-queue"
  }
}

# Glue Job Names
variable "glue_job_names" {
  description = "Glue job names"
  type = object({
    etl_job = string
  })
  default = {
    etl_job = "ETL-job"
  }
}

# CORS Allowed Origins
variable "cors_allowed_origins" {
  description = "Additional CORS allowed origins for API Gateway"
  type        = list(string)
  default     = ["http://localhost:3000"]
}

# Terraform Backend Configuration
variable "terraform_backend_enabled" {
  description = "Enable S3 backend for Terraform state (requires backend resources to be created first)"
  type        = bool
  default     = false
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
