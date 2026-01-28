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

variable "lambda_roles" {
  description = "Lambda IAM role ARNs"
  type = object({
    donor_service_role_arn      = string
    recipient_service_role_arn  = string
    user_service_role_arn       = string
    volunteer_service_role_arn  = string
    location_service_role_arn   = string
    ingest_trigger_role_arn     = string
  })
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

variable "sqs_queue_url" {
  description = "SQS queue URL"
  type        = string
}

variable "sqs_queue_arn" {
  description = "SQS queue ARN"
  type        = string
}

variable "api_gateway_id" {
  description = "API Gateway ID"
  type        = string
  default     = ""
}

variable "api_gateway_stage" {
  description = "API Gateway stage name"
  type        = string
  default     = ""
}

variable "authorizer_id" {
  description = "API Gateway authorizer ID"
  type        = string
  default     = ""
}

variable "raw_data_bucket_name" {
  description = "Raw data S3 bucket name"
  type        = string
}

variable "glue_job_name" {
  description = "Glue job name"
  type        = string
}
