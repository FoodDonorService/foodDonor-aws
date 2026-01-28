# Outputs for Food Donor Platform

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = module.integration.api_gateway_invoke_url
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = module.integration.api_gateway_id
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.security.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.security.user_pool_client_id
}

output "cognito_issuer_url" {
  description = "Cognito Issuer URL"
  value       = module.security.cognito_issuer_url
}

output "s3_bucket_names" {
  description = "S3 bucket names"
  value = {
    frontend       = module.storage.frontend_bucket_name
    raw_data       = module.storage.raw_data_bucket_name
    processed_data = module.storage.processed_data_bucket_name
    athena_results = module.storage.athena_results_bucket_name
    glue_assets    = module.storage.glue_assets_bucket_name
    public_data    = module.storage.public_data_bucket_name
  }
}

output "dynamodb_table_names" {
  description = "DynamoDB table names"
  value = {
    donor          = module.database.donor_table_name
    recipient      = module.database.recipient_table_name
    volunteer      = module.database.volunteer_table_name
    donation       = module.database.donation_table_name
    volunteer_match = module.database.volunteer_match_table_name
    task           = module.database.task_table_name
  }
}

output "lambda_function_names" {
  description = "Lambda function names"
  value = {
    donor_service     = module.compute.donor_service_function_name
    recipient_service = module.compute.recipient_service_function_name
    user_service      = module.compute.user_service_function_name
    volunteer_service = module.compute.volunteer_service_function_name
    location_service  = module.compute.location_service_function_name
    ingest_trigger     = module.compute.ingest_trigger_function_name
  }
}

output "sqs_queue_url" {
  description = "SQS match queue URL"
  value       = module.integration.match_queue_url
}

output "glue_job_name" {
  description = "Glue ETL job name"
  value       = module.database.glue_job_name
}
