# SQS Queue for Food Donor Platform
# Refactored: Removed hardcoded account ID, using data source

data "aws_caller_identity" "current" {}

locals {
  create_sqs = var.sqs_queue_names != null
  queue_name = local.create_sqs ? "${var.project_name}-${var.sqs_queue_names.match_queue}-${var.env}" : ""
}

resource "aws_sqs_queue" "match_queue" {
  count                     = local.create_sqs ? 1 : 0
  name                      = local.queue_name
  delay_seconds             = 0
  max_message_size          = 262144 # 256KB
  message_retention_seconds = 345600  # 4 days
  receive_wait_time_seconds = 20      # Long polling
  visibility_timeout_seconds = 30
}

resource "aws_sqs_queue_policy" "match_queue" {
  count    = local.create_sqs ? 1 : 0
  queue_url = aws_sqs_queue.match_queue[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "__default_policy_ID"
    Statement = [
      {
        Sid    = "__owner_statement"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "SQS:*"
        Resource = aws_sqs_queue.match_queue[0].arn
      }
    ]
  })
}
