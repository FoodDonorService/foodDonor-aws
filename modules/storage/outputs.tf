output "frontend_bucket_name" {
  description = "Frontend S3 bucket name"
  value       = aws_s3_bucket.frontend.id
}

output "raw_data_bucket_name" {
  description = "Raw data S3 bucket name"
  value       = aws_s3_bucket.raw_data.id
}

output "processed_data_bucket_name" {
  description = "Processed data S3 bucket name"
  value       = aws_s3_bucket.processed_data.id
}

output "athena_results_bucket_name" {
  description = "Athena results S3 bucket name"
  value       = aws_s3_bucket.athena_results.id
}

output "glue_assets_bucket_name" {
  description = "Glue assets S3 bucket name"
  value       = aws_s3_bucket.glue_assets.id
}

output "public_data_bucket_name" {
  description = "Public data S3 bucket name"
  value       = aws_s3_bucket.public_data.id
}

output "frontend_bucket_arn" {
  description = "Frontend S3 bucket ARN"
  value       = aws_s3_bucket.frontend.arn
}

output "raw_data_bucket_arn" {
  description = "Raw data S3 bucket ARN"
  value       = aws_s3_bucket.raw_data.arn
}

output "processed_data_bucket_arn" {
  description = "Processed data S3 bucket ARN"
  value       = aws_s3_bucket.processed_data.arn
}

output "athena_results_bucket_arn" {
  description = "Athena results S3 bucket ARN"
  value       = aws_s3_bucket.athena_results.arn
}

output "glue_assets_bucket_arn" {
  description = "Glue assets S3 bucket ARN"
  value       = aws_s3_bucket.glue_assets.arn
}

output "public_data_bucket_arn" {
  description = "Public data S3 bucket ARN"
  value       = aws_s3_bucket.public_data.arn
}

# Terraform Backend Outputs
output "terraform_state_bucket_name" {
  description = "Terraform state S3 bucket name"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_lock_table_name" {
  description = "Terraform state lock DynamoDB table name"
  value       = aws_dynamodb_table.terraform_locks.name
}
