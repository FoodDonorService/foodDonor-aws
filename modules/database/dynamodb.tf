# DynamoDB Tables for Food Donor Platform
# Refactored: Using variables for table names

# Donor table
resource "aws_dynamodb_table" "donor" {
  name         = var.dynamodb_table_names.donor
  hash_key     = "donor_id"
  billing_mode = "PAY_PER_REQUEST" # Changed from provisioned to on-demand

  attribute {
    name = "donor_id"
    type = "S"
  }

  tags = {
    Name        = var.dynamodb_table_names.donor
    Environment = var.env
    Project     = var.project_name
  }
}

# Recipient table
resource "aws_dynamodb_table" "recipient" {
  name         = var.dynamodb_table_names.recipient
  hash_key     = "recipient_id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "recipient_id"
    type = "S"
  }

  tags = {
    Name        = var.dynamodb_table_names.recipient
    Environment = var.env
    Project     = var.project_name
  }
}

# Volunteer table
resource "aws_dynamodb_table" "volunteer" {
  name         = var.dynamodb_table_names.volunteer
  hash_key     = "volunteer_id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "volunteer_id"
    type = "S"
  }

  attribute {
    name = "cognito_id"
    type = "S"
  }

  attribute {
    name = "volunteer_cognito_id"
    type = "S"
  }

  attribute {
    name = "item_type"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "cognito_id-index"
    hash_key        = "cognito_id"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "volunteer-item_type-index"
    hash_key        = "volunteer_cognito_id"
    range_key       = "item_type"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "item_type-status-index"
    hash_key        = "item_type"
    range_key       = "status"
    projection_type = "ALL"
  }

  tags = {
    Name        = var.dynamodb_table_names.volunteer
    Environment = var.env
    Project     = var.project_name
  }
}

# Donation table
resource "aws_dynamodb_table" "donation" {
  name         = var.dynamodb_table_names.donation
  hash_key     = "donation_id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "donation_id"
    type = "S"
  }

  attribute {
    name = "donor_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "donor_id-index"
    hash_key        = "donor_id"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    projection_type = "ALL"
  }

  tags = {
    Name        = var.dynamodb_table_names.donation
    Environment = var.env
    Project     = var.project_name
  }
}

# Volunteer Match table
resource "aws_dynamodb_table" "volunteer_match" {
  name         = var.dynamodb_table_names.volunteer_match
  hash_key     = "match_id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "match_id"
    type = "S"
  }

  attribute {
    name = "volunteer_id"
    type = "S"
  }

  global_secondary_index {
    name            = "volunteer_id-index"
    hash_key        = "volunteer_id"
    projection_type = "ALL"
  }

  tags = {
    Name        = var.dynamodb_table_names.volunteer_match
    Environment = var.env
    Project     = var.project_name
  }
}

# Task table
resource "aws_dynamodb_table" "task" {
  name         = var.dynamodb_table_names.task
  hash_key     = "task_id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "task_id"
    type = "S"
  }

  attribute {
    name = "volunteer_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "volunteer_id-index"
    type = "S"
  }

  attribute {
    name = "status-index"
    type = "S"
  }

  global_secondary_index {
    name            = "volunteer_id-volunteer_id-index-index"
    hash_key        = "volunteer_id"
    range_key       = "volunteer_id-index"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "status-status-index-index"
    hash_key        = "status"
    range_key       = "status-index"
    projection_type = "ALL"
  }

  tags = {
    Name        = var.dynamodb_table_names.task
    Environment = var.env
    Project     = var.project_name
  }
}
