# Cognito User Pool for Food Donor Platform
# Refactored: Using variables for configuration

locals {
  create_cognito = var.aws_region != ""
}

resource "aws_cognito_user_pool" "main" {
  count = local.create_cognito ? 1 : 0
  name = "${var.project_name}-user-pool-${var.env}"

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  schema {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    attribute_data_type = "Boolean"
    name                = "email_verified"
    required            = false
    mutable             = true
  }

  schema {
    attribute_data_type = "String"
    name                = "name"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    attribute_data_type = "String"
    name                = "phone_number"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  schema {
    attribute_data_type = "Boolean"
    name                = "phone_verified"  # Changed from phone_number_verified (21 chars > 20 char limit)
    required            = false
    mutable             = true
  }

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
  mfa_configuration       = "OFF"

  admin_create_user_config {
    allow_admin_create_user_only = false
    # unused_account_validity_days is deprecated and removed in newer AWS provider versions
  }

  tags = {
    Name        = "${var.project_name}-user-pool"
    Environment = var.env
    Project     = var.project_name
  }
}

resource "aws_cognito_user_pool_client" "main" {
  count         = local.create_cognito ? 1 : 0
  name          = "${var.project_name}-client-${var.env}"
  user_pool_id  = aws_cognito_user_pool.main[0].id
  refresh_token_validity = 5

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}
