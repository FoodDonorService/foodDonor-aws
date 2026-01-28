# IAM Roles and Policies for Food Donor Platform
# Refactored: Removed hardcoded account IDs, using data source and variables

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Lambda Basic Execution Role (for CloudWatch Logs)
resource "aws_iam_role" "lambda_basic_execution" {
  name = "${var.project_name}-lambda-basic-execution-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-lambda-basic-execution"
    Environment = var.env
    Project     = var.project_name
  }
}

# Attach AWS managed policy for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_basic_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Donor Service Role
resource "aws_iam_role" "donor_service" {
  name = "${var.project_name}-donor-service-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-donor-service-role"
    Environment = var.env
    Project     = var.project_name
  }
}

# Local for donor service policy statements
locals {
  donor_service_statements = concat(
    [
      {
        Sid    = "DynamoDBDonorAccess"
        Effect = "Allow"
        Action = "dynamodb:*"
        Resource = [
          var.dynamodb_table_arns.donor,
          var.dynamodb_table_arns.donation
        ]
      },
      {
        Sid    = "AthenaAccess"
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults"
        ]
        Resource = "arn:aws:athena:${var.aws_region}:${data.aws_caller_identity.current.account_id}:workgroup/primary"
      },
      {
        Sid    = "GlueAccess"
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable"
        ]
        Resource = [
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:database/*",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/*/*"
        ]
      },
      {
        Sid    = "S3AccessAthenaResults"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arns.athena_results,
          "${var.s3_bucket_arns.athena_results}/*"
        ]
      },
      {
        Sid    = "S3AccessProcessedData"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arns.processed_data,
          "${var.s3_bucket_arns.processed_data}/*"
        ]
      },
      {
        Sid    = "GlueJobStartAccess"
        Effect = "Allow"
        Action = "glue:StartJobRun"
        Resource = var.glue_job_arn != null && var.glue_job_arn != "" ? var.glue_job_arn : "*"
      }
    ],
    var.sqs_queue_arn != null && var.sqs_queue_arn != "" ? [
      {
        Sid    = "SQSSendMessage"
        Effect = "Allow"
        Action = "sqs:SendMessage"
        Resource = var.sqs_queue_arn
      }
    ] : []
  )
}

resource "aws_iam_role_policy" "donor_service" {
  name = "${var.project_name}-donor-service-policy-${var.env}"
  role = aws_iam_role.donor_service.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.donor_service_statements
  })
}

# Recipient Service Role
resource "aws_iam_role" "recipient_service" {
  name = "${var.project_name}-recipient-service-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-recipient-service-role"
    Environment = var.env
    Project     = var.project_name
  }
}

# Local for recipient service policy statements
locals {
  recipient_service_statements = concat(
    [
      {
        Sid    = "DynamoDBMatchAccess"
        Effect = "Allow"
        Action = "dynamodb:*"
        Resource = [
          var.dynamodb_table_arns.recipient,
          var.dynamodb_table_arns.task,
          var.dynamodb_table_arns.volunteer_match
        ]
      },
      {
        Sid    = "BedrockInvokeAccess"
        Effect = "Allow"
        Action = "bedrock:InvokeModel"
        Resource = "*"
      },
      {
        Sid    = "MarketplaceAccess"
        Effect = "Allow"
        Action = [
          "aws-marketplace:ViewSubscriptions",
          "aws-marketplace:Subscribe"
        ]
        Resource = "*"
      }
    ],
    var.sqs_queue_arn != null && var.sqs_queue_arn != "" ? [
      {
        Sid    = "SQSReceiveMessage"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = var.sqs_queue_arn
      }
    ] : []
  )
}

resource "aws_iam_role_policy" "recipient_service" {
  name = "${var.project_name}-recipient-service-policy-${var.env}"
  role = aws_iam_role.recipient_service.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.recipient_service_statements
  })
}

# User Service Role
resource "aws_iam_role" "user_service" {
  name = "${var.project_name}-user-service-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-user-service-role"
    Environment = var.env
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "user_service" {
  name = "${var.project_name}-user-service-policy-${var.env}"
  role = aws_iam_role.user_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBUserAccess"
        Effect = "Allow"
        Action = "dynamodb:*"
        Resource = [
          var.dynamodb_table_arns.donor,
          var.dynamodb_table_arns.recipient,
          var.dynamodb_table_arns.volunteer
        ]
      }
    ]
  })
}

# Volunteer Service Role
resource "aws_iam_role" "volunteer_service" {
  name = "${var.project_name}-volunteer-service-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-volunteer-service-role"
    Environment = var.env
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "volunteer_service" {
  name = "${var.project_name}-volunteer-service-policy-${var.env}"
  role = aws_iam_role.volunteer_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBVolunteerAccess"
        Effect = "Allow"
        Action = "dynamodb:*"
        Resource = [
          var.dynamodb_table_arns.volunteer,
          "${var.dynamodb_table_arns.volunteer}/index/*",
          var.dynamodb_table_arns.volunteer_match,
          "${var.dynamodb_table_arns.volunteer_match}/index/*",
          var.dynamodb_table_arns.donation,
          "${var.dynamodb_table_arns.donation}/index/*",
          var.dynamodb_table_arns.task
        ]
      }
    ]
  })
}

# Location Service Role
resource "aws_iam_role" "location_service" {
  name = "${var.project_name}-location-service-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-location-service-role"
    Environment = var.env
    Project     = var.project_name
  }
}

# Attach basic execution role to location service
resource "aws_iam_role_policy_attachment" "location_service_basic" {
  role       = aws_iam_role.location_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Ingest Trigger Role
resource "aws_iam_role" "ingest_trigger" {
  name = "${var.project_name}-ingest-trigger-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ingest-trigger-role"
    Environment = var.env
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "ingest_trigger" {
  name = "${var.project_name}-ingest-trigger-policy-${var.env}"
  role = aws_iam_role.ingest_trigger.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3WriteAccessRaw"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${var.s3_bucket_arns.raw_data}/*"
      },
      {
        Sid    = "GlueJobStartAccess"
        Effect = "Allow"
        Action = [
          "glue:StartJobRun"
        ]
        Resource = var.glue_job_arn
      }
    ]
  })
}

# Glue Role
resource "aws_iam_role" "glue" {
  name = "${var.project_name}-glue-role-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-glue-role"
    Environment = var.env
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "glue" {
  name = "${var.project_name}-glue-policy-${var.env}"
  role = aws_iam_role.glue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ListAccess"
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = [
          var.s3_bucket_arns.raw_data,
          var.s3_bucket_arns.processed_data
        ]
      },
      {
        Sid    = "S3ReadAccessRaw"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${var.s3_bucket_arns.raw_data}/*"
      },
      {
        Sid    = "S3WriteAccessProcessed"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.s3_bucket_arns.processed_data}/*"
      }
    ]
  })
}

# Attach AWS managed Glue service role policy
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}
