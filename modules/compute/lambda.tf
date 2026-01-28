# Lambda Functions for Food Donor Platform
# Refactored: Changed from S3 source to local source code using archive_file

# Lambda source code mappings
# Paths are relative to the workspace root (foodDonor-aws/)
locals {
  lambda_sources = {
    donor_service = {
      source_path = "services/aws-micro-service/donor.js"
      handler     = "donor.handler"
      runtime     = "nodejs22.x"
      timeout     = 60
      memory      = 128
      architecture = "arm64"
    }
    recipient_service = {
      source_path = "services/aws-micro-service/recipient.js"
      handler     = "recipient.handler"
      runtime     = "nodejs22.x"
      timeout     = 30
      memory      = 128
      architecture = "arm64"
    }
    user_service = {
      source_path = "services/aws-micro-service/user.js"
      handler     = "user.handler"
      runtime     = "nodejs22.x"  # Changed from nodejs24.x (not supported yet)
      timeout     = 3
      memory      = 128
      architecture = "x86_64"
    }
    volunteer_service = {
      source_path = "services/aws-micro-service/volunteer.js"
      handler     = "volunteer.handler"
      runtime     = "nodejs22.x"
      timeout     = 3
      memory      = 128
      architecture = "x86_64"
    }
    location_service = {
      source_path = "services/aws-micro-service/location.mjs"
      handler     = "location.handler"
      runtime     = "nodejs22.x"
      timeout     = 3
      memory      = 128
      architecture = "arm64"
    }
    ingest_trigger = {
      source_path = "services/aws-batch-process-pipeline/ingest-trigger.js"
      handler     = "ingest-trigger.handler"  # .js 파일명에 맞게 handler 수정
      runtime     = "nodejs22.x"
      timeout     = 180
      memory      = 512
      architecture = "arm64"
    }
  }
}

# Archive each Lambda source code
# Note: Lambda functions use single file deployment
# Handler must match the filename (e.g., donor.mjs -> donor.handler)
# Path is relative to the workspace root (foodDonor-aws/)
# path.root now points to foodDonor-aws/, so services/ is directly accessible
data "archive_file" "lambda_zips" {
  for_each = local.lambda_sources
  
  type        = "zip"
  source_file = abspath("${path.root}/${each.value.source_path}")
  output_path = "${path.module}/.terraform/lambda-${each.key}.zip"
  
  # Note: When using single file deployment, the handler must match the filename
  # For .mjs files: filename.mjs -> filename.handler
  # For .js files: filename.js -> filename.handler
}

# Donor Service Lambda
resource "aws_lambda_function" "donor_service" {
  function_name = "${var.project_name}-donor-service-${var.env}"
  handler       = local.lambda_sources.donor_service.handler
  runtime       = local.lambda_sources.donor_service.runtime
  timeout       = local.lambda_sources.donor_service.timeout
  memory_size   = local.lambda_sources.donor_service.memory
  architectures = [local.lambda_sources.donor_service.architecture]
  role          = var.lambda_roles.donor_service_role_arn

  filename         = data.archive_file.lambda_zips["donor_service"].output_path
  source_code_hash = data.archive_file.lambda_zips["donor_service"].output_base64sha256

  tracing_config {
    mode = "PassThrough"
  }

  environment {
    variables = {
      DONOR_TABLE_NAME      = var.dynamodb_table_names.donor
      DONATION_TABLE_NAME   = var.dynamodb_table_names.donation
      SQS_QUEUE_URL         = var.sqs_queue_url
    }
  }

  tags = {
    Name        = "${var.project_name}-donor-service"
    Environment = var.env
    Project     = var.project_name
  }
}

# Recipient Service Lambda
resource "aws_lambda_function" "recipient_service" {
  function_name = "${var.project_name}-recipient-service-${var.env}"
  handler       = local.lambda_sources.recipient_service.handler
  runtime       = local.lambda_sources.recipient_service.runtime
  timeout       = local.lambda_sources.recipient_service.timeout
  memory_size   = local.lambda_sources.recipient_service.memory
  architectures = [local.lambda_sources.recipient_service.architecture]
  role          = var.lambda_roles.recipient_service_role_arn

  filename         = data.archive_file.lambda_zips["recipient_service"].output_path
  source_code_hash = data.archive_file.lambda_zips["recipient_service"].output_base64sha256

  tracing_config {
    mode = "Active"
  }

  layers = [
    "arn:aws:lambda:${var.aws_region}:580247275435:layer:LambdaInsightsExtension-Arm64:26",
    "arn:aws:lambda:${var.aws_region}:615299751070:layer:AWSOpenTelemetryDistroJs:10"
  ]

  environment {
    variables = {
      RECIPIENT_TABLE_NAME = var.dynamodb_table_names.recipient
      TASK_TABLE_NAME      = var.dynamodb_table_names.task
      VOLUNTEER_MATCH_TABLE_NAME = var.dynamodb_table_names.volunteer_match
      SQS_QUEUE_URL       = var.sqs_queue_url
    }
  }

  tags = {
    Name        = "${var.project_name}-recipient-service"
    Environment = var.env
    Project     = var.project_name
  }
}

# User Service Lambda
resource "aws_lambda_function" "user_service" {
  function_name = "${var.project_name}-user-service-${var.env}"
  handler       = local.lambda_sources.user_service.handler
  runtime       = local.lambda_sources.user_service.runtime
  timeout       = local.lambda_sources.user_service.timeout
  memory_size   = local.lambda_sources.user_service.memory
  architectures = [local.lambda_sources.user_service.architecture]
  role          = var.lambda_roles.user_service_role_arn

  filename         = data.archive_file.lambda_zips["user_service"].output_path
  source_code_hash = data.archive_file.lambda_zips["user_service"].output_base64sha256

  tracing_config {
    mode = "PassThrough"
  }

  environment {
    variables = {
      DONOR_TABLE_NAME     = var.dynamodb_table_names.donor
      RECIPIENT_TABLE_NAME = var.dynamodb_table_names.recipient
      VOLUNTEER_TABLE_NAME = var.dynamodb_table_names.volunteer
    }
  }

  tags = {
    Name        = "${var.project_name}-user-service"
    Environment = var.env
    Project     = var.project_name
  }
}

# Volunteer Service Lambda
resource "aws_lambda_function" "volunteer_service" {
  function_name = "${var.project_name}-volunteer-service-${var.env}"
  handler       = local.lambda_sources.volunteer_service.handler
  runtime       = local.lambda_sources.volunteer_service.runtime
  timeout       = local.lambda_sources.volunteer_service.timeout
  memory_size   = local.lambda_sources.volunteer_service.memory
  architectures = [local.lambda_sources.volunteer_service.architecture]
  role          = var.lambda_roles.volunteer_service_role_arn

  filename         = data.archive_file.lambda_zips["volunteer_service"].output_path
  source_code_hash = data.archive_file.lambda_zips["volunteer_service"].output_base64sha256

  tracing_config {
    mode = "PassThrough"
  }

  environment {
    variables = {
      VOLUNTEER_TABLE_NAME = var.dynamodb_table_names.volunteer
      DONATION_TABLE_NAME  = var.dynamodb_table_names.donation
      TASK_TABLE_NAME      = var.dynamodb_table_names.task
      VOLUNTEER_MATCH_TABLE_NAME = var.dynamodb_table_names.volunteer_match
      # API Gateway variables will be set after API Gateway is created
      # These can be updated via separate terraform apply or using null_resource with local-exec
      API_GATEWAY_ID       = var.api_gateway_id != "" ? var.api_gateway_id : ""
      API_GATEWAY_STAGE    = var.api_gateway_stage != "" ? var.api_gateway_stage : ""
      AUTHORIZER_ID        = var.authorizer_id != "" ? var.authorizer_id : ""
    }
  }

  tags = {
    Name        = "${var.project_name}-volunteer-service"
    Environment = var.env
    Project     = var.project_name
  }
}

# Location Service Lambda (Naver API)
resource "aws_lambda_function" "location_service" {
  function_name = "${var.project_name}-naver-api-service-${var.env}"
  handler       = local.lambda_sources.location_service.handler
  runtime       = local.lambda_sources.location_service.runtime
  timeout       = local.lambda_sources.location_service.timeout
  memory_size   = local.lambda_sources.location_service.memory
  architectures = [local.lambda_sources.location_service.architecture]
  role          = var.lambda_roles.location_service_role_arn

  filename         = data.archive_file.lambda_zips["location_service"].output_path
  source_code_hash = data.archive_file.lambda_zips["location_service"].output_base64sha256

  tracing_config {
    mode = "PassThrough"
  }

  tags = {
    Name        = "${var.project_name}-location-service"
    Environment = var.env
    Project     = var.project_name
  }
}

# Ingest Trigger Lambda
resource "aws_lambda_function" "ingest_trigger" {
  function_name = "${var.project_name}-ingest-trigger-${var.env}"
  description    = "ingest data from open API"
  handler        = local.lambda_sources.ingest_trigger.handler
  runtime        = local.lambda_sources.ingest_trigger.runtime
  timeout        = local.lambda_sources.ingest_trigger.timeout
  memory_size    = local.lambda_sources.ingest_trigger.memory
  architectures  = [local.lambda_sources.ingest_trigger.architecture]
  role           = var.lambda_roles.ingest_trigger_role_arn

  filename         = data.archive_file.lambda_zips["ingest_trigger"].output_path
  source_code_hash = data.archive_file.lambda_zips["ingest_trigger"].output_base64sha256

  tracing_config {
    mode = "PassThrough"
  }

  environment {
    variables = {
      RAW_DATA_BUCKET = var.raw_data_bucket_name
      GLUE_JOB_NAME   = var.glue_job_name
    }
  }

  tags = {
    Name        = "${var.project_name}-ingest-trigger"
    Environment = var.env
    Project     = var.project_name
  }
}

# SQS Event Source Mapping for Recipient Service
# Only create if SQS queue ARN is provided
resource "aws_lambda_event_source_mapping" "recipient_sqs" {
  count          = var.sqs_queue_arn != null && var.sqs_queue_arn != "" ? 1 : 0
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.recipient_service.arn
  batch_size       = 10
  enabled          = true
}
