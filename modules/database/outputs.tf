output "donor_table_name" {
  description = "Donor DynamoDB table name"
  value       = aws_dynamodb_table.donor.name
}

output "recipient_table_name" {
  description = "Recipient DynamoDB table name"
  value       = aws_dynamodb_table.recipient.name
}

output "volunteer_table_name" {
  description = "Volunteer DynamoDB table name"
  value       = aws_dynamodb_table.volunteer.name
}

output "donation_table_name" {
  description = "Donation DynamoDB table name"
  value       = aws_dynamodb_table.donation.name
}

output "volunteer_match_table_name" {
  description = "Volunteer Match DynamoDB table name"
  value       = aws_dynamodb_table.volunteer_match.name
}

output "task_table_name" {
  description = "Task DynamoDB table name"
  value       = aws_dynamodb_table.task.name
}

output "donor_table_arn" {
  description = "Donor DynamoDB table ARN"
  value       = aws_dynamodb_table.donor.arn
}

output "recipient_table_arn" {
  description = "Recipient DynamoDB table ARN"
  value       = aws_dynamodb_table.recipient.arn
}

output "volunteer_table_arn" {
  description = "Volunteer DynamoDB table ARN"
  value       = aws_dynamodb_table.volunteer.arn
}

output "donation_table_arn" {
  description = "Donation DynamoDB table ARN"
  value       = aws_dynamodb_table.donation.arn
}

output "volunteer_match_table_arn" {
  description = "Volunteer Match DynamoDB table ARN"
  value       = aws_dynamodb_table.volunteer_match.arn
}

output "task_table_arn" {
  description = "Task DynamoDB table ARN"
  value       = aws_dynamodb_table.task.arn
}
