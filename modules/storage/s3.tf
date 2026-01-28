# S3 Buckets for Food Donor Platform
# Refactored: Removed hardcoded bucket names, using variables with project_name and env prefix

locals {
  bucket_names = {
    frontend       = "${var.project_name}-${var.s3_bucket_names.frontend}-${var.env}"
    raw_data       = "${var.project_name}-${var.s3_bucket_names.raw_data}-${var.env}"
    processed_data = "${var.project_name}-${var.s3_bucket_names.processed_data}-${var.env}"
    athena_results = "${var.project_name}-${var.s3_bucket_names.athena_results}-${var.env}"
    glue_assets    = "aws-glue-assets-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
    public_data    = "${var.project_name}-${var.s3_bucket_names.public_data}-${var.env}"
  }
}

# Frontend bucket
resource "aws_s3_bucket" "frontend" {
  bucket = local.bucket_names.frontend
}

# Frontend bucket public access block - Allow public access for static website hosting
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Raw data bucket
resource "aws_s3_bucket" "raw_data" {
  bucket = local.bucket_names.raw_data
}

# Processed data bucket
resource "aws_s3_bucket" "processed_data" {
  bucket = local.bucket_names.processed_data
}

# Athena results bucket
resource "aws_s3_bucket" "athena_results" {
  bucket = local.bucket_names.athena_results
}

# Glue assets bucket (AWS managed, but we need to reference it)
resource "aws_s3_bucket" "glue_assets" {
  bucket = local.bucket_names.glue_assets
}

# Public data bucket
resource "aws_s3_bucket" "public_data" {
  bucket = local.bucket_names.public_data
}

# Frontend bucket policy - public read access
# Depends on public access block to allow public policy
resource "aws_s3_bucket_policy" "frontend" {
  bucket     = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend]
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Statement1"
        Effect = "Allow"
        Principal = "*"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# Athena results bucket policy - Allow Athena service access
resource "aws_s3_bucket_policy" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAthenaServiceAccess"
        Effect = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.athena_results.arn,
          "${aws_s3_bucket.athena_results.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:athena:${var.aws_region}:${data.aws_caller_identity.current.account_id}:workgroup/*"
          }
        }
      }
    ]
  })
}
