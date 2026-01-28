# Food Donor Platform - Main Terraform Configuration
# Refactored from Former2 raw code to deployable Terraform modules

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Storage Module - S3 Buckets (including Terraform backend resources)
module "storage" {
  source = "./modules/storage"

  project_name              = var.project_name
  env                       = var.env
  aws_region                = var.aws_region
  s3_bucket_names           = var.s3_bucket_names
  terraform_state_bucket_name = var.terraform_state_bucket_name
  terraform_lock_table_name   = var.terraform_lock_table_name
}

# Database Module - DynamoDB Tables & Glue ETL Job
module "database" {
  source = "./modules/database"

  project_name            = var.project_name
  env                     = var.env
  dynamodb_table_names    = var.dynamodb_table_names
  # Glue configuration
  glue_job_names          = var.glue_job_names
  glue_role_arn           = module.security.glue_role_arn
  glue_assets_bucket_name = module.storage.glue_assets_bucket_name
  glue_version            = var.glue_version
  glue_worker_type        = var.glue_worker_type
  glue_number_of_workers  = var.glue_number_of_workers
  # Note: glue_max_capacity removed - conflicts with number_of_workers/worker_type
}

# Security Module - IAM Roles & Cognito
module "security" {
  source = "./modules/security"

  project_name         = var.project_name
  env                 = var.env
  aws_region          = var.aws_region
  dynamodb_table_arns = {
    donor          = module.database.donor_table_arn
    recipient      = module.database.recipient_table_arn
    volunteer      = module.database.volunteer_table_arn
    donation       = module.database.donation_table_arn
    volunteer_match = module.database.volunteer_match_table_arn
    task           = module.database.task_table_arn
  }
  s3_bucket_arns = {
    raw_data       = module.storage.raw_data_bucket_arn
    processed_data = module.storage.processed_data_bucket_arn
    athena_results = module.storage.athena_results_bucket_arn
  }
  sqs_queue_arn = "" # Will be set after integration module creates SQS
  glue_job_arn  = module.database.glue_job_arn != null ? module.database.glue_job_arn : ""
}

# Compute Module - Lambda Functions
module "compute" {
  source = "./modules/compute"

  project_name         = var.project_name
  env                  = var.env
  aws_region           = var.aws_region
  lambda_roles = {
    donor_service_role_arn     = module.security.donor_service_role_arn
    recipient_service_role_arn  = module.security.recipient_service_role_arn
    user_service_role_arn       = module.security.user_service_role_arn
    volunteer_service_role_arn  = module.security.volunteer_service_role_arn
    location_service_role_arn   = module.security.location_service_role_arn
    ingest_trigger_role_arn     = module.security.ingest_trigger_role_arn
  }
  dynamodb_table_names = var.dynamodb_table_names
  sqs_queue_url       = "" # Will be set after integration module creates SQS
  sqs_queue_arn       = "" # Will be set after integration module creates SQS
  raw_data_bucket_name = module.storage.raw_data_bucket_name
  glue_job_name        = module.database.glue_job_name != null ? module.database.glue_job_name : ""
  api_gateway_id       = "" # Will be set after API Gateway creation
  api_gateway_stage    = var.api_gateway_stage
  authorizer_id        = "" # Will be set after API Gateway creation
}

# Integration Module - SQS & API Gateway
# Depends on compute and security modules
module "integration" {
  source = "./modules/integration"

  project_name      = var.project_name
  env               = var.env
  sqs_queue_names   = var.sqs_queue_names
  
  # API Gateway variables
  api_gateway_stage = var.api_gateway_stage
  cognito_client_id = module.security.user_pool_client_id != null ? module.security.user_pool_client_id : ""
  cognito_issuer_url = module.security.cognito_issuer_url != null ? module.security.cognito_issuer_url : ""
  lambda_invoke_arns = {
    donor_service     = module.compute.donor_service_invoke_arn
    recipient_service = module.compute.recipient_service_invoke_arn
    user_service      = module.compute.user_service_invoke_arn
    volunteer_service = module.compute.volunteer_service_invoke_arn
    location_service  = module.compute.location_service_invoke_arn
  }
  lambda_function_names = {
    donor_service     = module.compute.donor_service_function_name
    recipient_service = module.compute.recipient_service_function_name
    user_service      = module.compute.user_service_function_name
    volunteer_service = module.compute.volunteer_service_function_name
    location_service  = module.compute.location_service_function_name
  }
  cors_allowed_origins = var.cors_allowed_origins

  depends_on = [module.compute, module.security]
}
