output "donor_service_function_name" {
  description = "Donor service Lambda function name"
  value       = aws_lambda_function.donor_service.function_name
}

output "donor_service_function_arn" {
  description = "Donor service Lambda function ARN"
  value       = aws_lambda_function.donor_service.arn
}

output "donor_service_invoke_arn" {
  description = "Donor service Lambda invoke ARN"
  value       = aws_lambda_function.donor_service.invoke_arn
}

output "recipient_service_function_name" {
  description = "Recipient service Lambda function name"
  value       = aws_lambda_function.recipient_service.function_name
}

output "recipient_service_function_arn" {
  description = "Recipient service Lambda function ARN"
  value       = aws_lambda_function.recipient_service.arn
}

output "recipient_service_invoke_arn" {
  description = "Recipient service Lambda invoke ARN"
  value       = aws_lambda_function.recipient_service.invoke_arn
}

output "user_service_function_name" {
  description = "User service Lambda function name"
  value       = aws_lambda_function.user_service.function_name
}

output "user_service_function_arn" {
  description = "User service Lambda function ARN"
  value       = aws_lambda_function.user_service.arn
}

output "user_service_invoke_arn" {
  description = "User service Lambda invoke ARN"
  value       = aws_lambda_function.user_service.invoke_arn
}

output "volunteer_service_function_name" {
  description = "Volunteer service Lambda function name"
  value       = aws_lambda_function.volunteer_service.function_name
}

output "volunteer_service_function_arn" {
  description = "Volunteer service Lambda function ARN"
  value       = aws_lambda_function.volunteer_service.arn
}

output "volunteer_service_invoke_arn" {
  description = "Volunteer service Lambda invoke ARN"
  value       = aws_lambda_function.volunteer_service.invoke_arn
}

output "location_service_function_name" {
  description = "Location service Lambda function name"
  value       = aws_lambda_function.location_service.function_name
}

output "location_service_function_arn" {
  description = "Location service Lambda function ARN"
  value       = aws_lambda_function.location_service.arn
}

output "location_service_invoke_arn" {
  description = "Location service Lambda invoke ARN"
  value       = aws_lambda_function.location_service.invoke_arn
}

output "ingest_trigger_function_name" {
  description = "Ingest trigger Lambda function name"
  value       = aws_lambda_function.ingest_trigger.function_name
}

output "ingest_trigger_function_arn" {
  description = "Ingest trigger Lambda function ARN"
  value       = aws_lambda_function.ingest_trigger.arn
}

output "ingest_trigger_invoke_arn" {
  description = "Ingest trigger Lambda invoke ARN"
  value       = aws_lambda_function.ingest_trigger.invoke_arn
}
