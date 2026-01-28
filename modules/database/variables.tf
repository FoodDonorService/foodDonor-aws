variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

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
}

# Glue variables (shared with glue_variables.tf)
variable "glue_job_names" {
  description = "Glue job names"
  type = object({
    etl_job = string
  })
  default = null
}

variable "glue_role_arn" {
  description = "Glue IAM role ARN"
  type        = string
  default     = null
}

variable "glue_assets_bucket_name" {
  description = "Glue assets S3 bucket name"
  type        = string
  default     = null
}

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

# Note: glue_max_capacity removed - conflicts with number_of_workers/worker_type
# AWS Glue Job can use either max_capacity (Standard) OR number_of_workers+worker_type (Flex)
# We're using number_of_workers+worker_type for Flex workflow
