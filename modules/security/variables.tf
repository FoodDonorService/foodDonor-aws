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

variable "dynamodb_table_arns" {
  description = "DynamoDB table ARNs"
  type = object({
    donor          = string
    recipient      = string
    volunteer      = string
    donation       = string
    volunteer_match = string
    task           = string
  })
}

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs"
  type = object({
    raw_data       = string
    processed_data = string
    athena_results = string
  })
}

variable "sqs_queue_arn" {
  description = "SQS queue ARN"
  type        = string
}

variable "glue_job_arn" {
  description = "Glue job ARN"
  type        = string
}
