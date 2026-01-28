output "glue_job_name" {
  description = "Glue ETL job name"
  value       = local.create_glue ? aws_glue_job.etl_job[0].name : null
}

output "glue_job_arn" {
  description = "Glue ETL job ARN"
  value       = local.create_glue ? aws_glue_job.etl_job[0].arn : null
}
