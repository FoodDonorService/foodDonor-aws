output "match_queue_url" {
  description = "Match queue URL"
  value       = local.create_sqs ? aws_sqs_queue.match_queue[0].url : null
}

output "match_queue_arn" {
  description = "Match queue ARN"
  value       = local.create_sqs ? aws_sqs_queue.match_queue[0].arn : null
}

output "match_queue_name" {
  description = "Match queue name"
  value       = local.create_sqs ? aws_sqs_queue.match_queue[0].name : null
}
