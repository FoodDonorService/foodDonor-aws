# Glue ETL Job for Food Donor Platform
# Refactored: Changed from hardcoded S3 script location to local file upload

# Only create Glue resources if glue_job_names is provided
# Note: Only check glue_job_names to avoid count dependency on resource attributes
locals {
  create_glue = var.glue_job_names != null && try(var.glue_job_names.etl_job != null && var.glue_job_names.etl_job != "", false)
}

# Upload Glue script to S3
# Note: Path is relative to the root module (foodDonor-aws/)
# path.root now points to foodDonor-aws/, so services/ is directly accessible
resource "aws_s3_object" "glue_script" {
  count  = local.create_glue ? 1 : 0
  bucket = var.glue_assets_bucket_name
  key    = "scripts/${var.glue_job_names.etl_job}-${var.env}.py"
  source = abspath("${path.root}/services/aws-batch-process-pipeline/glue-processor.py")
  etag   = filemd5(abspath("${path.root}/services/aws-batch-process-pipeline/glue-processor.py"))
}

# Glue ETL Job
resource "aws_glue_job" "etl_job" {
  count       = local.create_glue ? 1 : 0
  name        = "${var.project_name}-${var.glue_job_names.etl_job}-${var.env}"
  description = "food donor glue ETL Job"
  role_arn    = var.glue_role_arn

  execution_property {
    max_concurrent_runs = 1
  }

  command {
    name          = "glueetl"
    python_version = "3"
    script_location = "s3://${var.glue_assets_bucket_name}/${aws_s3_object.glue_script[0].key}"
  }

  default_arguments = {
    "--enable-metrics"            = "true"
    "--enable-spark-ui"           = "true"
    "--spark-event-logs-path"     = "s3://${var.glue_assets_bucket_name}/sparkHistoryLogs/"
    "--enable-job-insights"       = "true"
    "--enable-observability-metrics" = "true"
    "--enable-glue-datacatalog"   = "true"
    "--job-bookmark-option"       = "job-bookmark-disable"
    "--job-language"             = "python"
    "--TempDir"                   = "s3://${var.glue_assets_bucket_name}/temporary/"
  }

  max_retries      = 0
  timeout          = 15
  glue_version     = var.glue_version
  # Note: max_capacity conflicts with number_of_workers/worker_type
  # Using number_of_workers + worker_type for Flex workflow
  number_of_workers = var.glue_number_of_workers
  worker_type       = var.glue_worker_type

  tags = {
    Name        = "${var.project_name}-${var.glue_job_names.etl_job}"
    Environment = var.env
    Project     = var.project_name
  }
}
