output "donor_service_role_arn" {
  description = "Donor service IAM role ARN"
  value       = aws_iam_role.donor_service.arn
}

output "recipient_service_role_arn" {
  description = "Recipient service IAM role ARN"
  value       = aws_iam_role.recipient_service.arn
}

output "user_service_role_arn" {
  description = "User service IAM role ARN"
  value       = aws_iam_role.user_service.arn
}

output "volunteer_service_role_arn" {
  description = "Volunteer service IAM role ARN"
  value       = aws_iam_role.volunteer_service.arn
}

output "location_service_role_arn" {
  description = "Location service IAM role ARN"
  value       = aws_iam_role.location_service.arn
}

output "ingest_trigger_role_arn" {
  description = "Ingest trigger IAM role ARN"
  value       = aws_iam_role.ingest_trigger.arn
}

output "glue_role_arn" {
  description = "Glue IAM role ARN"
  value       = aws_iam_role.glue.arn
}

output "lambda_basic_execution_role_arn" {
  description = "Lambda basic execution IAM role ARN"
  value       = aws_iam_role.lambda_basic_execution.arn
}

# Cognito outputs (from cognito.tf)
output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = local.create_cognito ? aws_cognito_user_pool.main[0].id : null
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = local.create_cognito ? aws_cognito_user_pool.main[0].arn : null
}

output "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = local.create_cognito ? aws_cognito_user_pool_client.main[0].id : null
}

output "cognito_issuer_url" {
  description = "Cognito Issuer URL"
  value       = local.create_cognito ? "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main[0].id}" : null
}
