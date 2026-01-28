# API Gateway for Food Donor Platform
# Refactored: Removed hardcoded ARNs, using Lambda function references

# Only create API Gateway if api_gateway_stage is provided
# Note: Don't check cognito_client_id or lambda_invoke_arns as they depend on resource attributes
locals {
  create_api_gateway = var.api_gateway_stage != null && var.api_gateway_stage != ""
}

resource "aws_apigatewayv2_api" "main" {
  count          = local.create_api_gateway ? 1 : 0
  name          = "${var.project_name}-api-${var.env}"
  protocol_type = "HTTP"
  description   = "Food Donor Platform API Gateway"

  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "authorization", "x-amz-date"]
    allow_methods     = ["*"]
    allow_origins      = concat(["*"], var.cors_allowed_origins)
    expose_headers    = ["*"]
    max_age           = 86400
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = var.env
    Project     = var.project_name
  }
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "main" {
  count     = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  name      = var.api_gateway_stage
  auto_deploy = true

  default_route_settings {
    detailed_metrics_enabled = false
  }

  tags = {
    Name        = "${var.project_name}-api-stage"
    Environment = var.env
    Project     = var.project_name
  }
}

# Cognito Authorizer
resource "aws_apigatewayv2_authorizer" "cognito" {
  count          = local.create_api_gateway ? 1 : 0
  api_id         = aws_apigatewayv2_api.main[0].id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "CognitoAuth"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = var.cognito_issuer_url
  }
}

# Lambda Integrations
resource "aws_apigatewayv2_integration" "donor" {
  count          = local.create_api_gateway ? 1 : 0
  api_id         = aws_apigatewayv2_api.main[0].id
  integration_type = "AWS_PROXY"
  integration_method = "POST"
  integration_uri  = var.lambda_invoke_arns.donor_service
  payload_format_version = "1.0"
  timeout_milliseconds = 30000
}

resource "aws_apigatewayv2_integration" "recipient" {
  count             = local.create_api_gateway ? 1 : 0
  api_id            = aws_apigatewayv2_api.main[0].id
  integration_type  = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = var.lambda_invoke_arns.recipient_service
  payload_format_version = "1.0"
  timeout_milliseconds = 30000
}

resource "aws_apigatewayv2_integration" "user" {
  count             = local.create_api_gateway ? 1 : 0
  api_id            = aws_apigatewayv2_api.main[0].id
  integration_type  = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = var.lambda_invoke_arns.user_service
  payload_format_version = "1.0"
  timeout_milliseconds = 30000
}

resource "aws_apigatewayv2_integration" "volunteer" {
  count             = local.create_api_gateway ? 1 : 0
  api_id            = aws_apigatewayv2_api.main[0].id
  integration_type  = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = var.lambda_invoke_arns.volunteer_service
  payload_format_version = "1.0"
  timeout_milliseconds = 30000
}

resource "aws_apigatewayv2_integration" "location" {
  count             = local.create_api_gateway ? 1 : 0
  api_id            = aws_apigatewayv2_api.main[0].id
  integration_type  = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = var.lambda_invoke_arns.location_service
  payload_format_version = "1.0"
  timeout_milliseconds = 30000
}

# Routes - Donor
resource "aws_apigatewayv2_route" "donor_any" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "ANY /donor"
  target    = "integrations/${aws_apigatewayv2_integration.donor[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

resource "aws_apigatewayv2_route" "donor_get_proxy" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "GET /donor/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.donor[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

resource "aws_apigatewayv2_route" "donor_post_proxy" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "POST /donor/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.donor[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

# Routes - Recipient
resource "aws_apigatewayv2_route" "recipient_any" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "ANY /recipient"
  target    = "integrations/${aws_apigatewayv2_integration.recipient[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

resource "aws_apigatewayv2_route" "recipient_get_proxy" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "GET /recipient/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.recipient[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

resource "aws_apigatewayv2_route" "recipient_post_proxy" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "POST /recipient/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.recipient[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

# Routes - User
resource "aws_apigatewayv2_route" "user_any" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "ANY /user"
  target    = "integrations/${aws_apigatewayv2_integration.user[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

resource "aws_apigatewayv2_route" "user_me" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "GET /user/me"
  target    = "integrations/${aws_apigatewayv2_integration.user[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

resource "aws_apigatewayv2_route" "user_proxy" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "ANY /user/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.user[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

# Routes - Volunteer
resource "aws_apigatewayv2_route" "volunteer_any" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "ANY /volunteer"
  target    = "integrations/${aws_apigatewayv2_integration.volunteer[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

resource "aws_apigatewayv2_route" "volunteer_get_proxy" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "GET /volunteer/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.volunteer[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

resource "aws_apigatewayv2_route" "volunteer_post_proxy" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "POST /volunteer/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.volunteer[0].id}"
  authorization_type = "JWT"
  authorizer_id     = aws_apigatewayv2_authorizer.cognito[0].id
}

# Routes - Location (no auth)
resource "aws_apigatewayv2_route" "location_any" {
  count = local.create_api_gateway ? 1 : 0
  api_id    = aws_apigatewayv2_api.main[0].id
  route_key = "ANY /location"
  target    = "integrations/${aws_apigatewayv2_integration.location[0].id}"
  authorization_type = "NONE"
}

# Lambda Permissions for API Gateway
resource "aws_lambda_permission" "donor_api" {
  count = local.create_api_gateway ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway-Donor"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names.donor_service
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main[0].execution_arn}/*/*"
}

resource "aws_lambda_permission" "recipient_api" {
  count = local.create_api_gateway ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway-Recipient"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names.recipient_service
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main[0].execution_arn}/*/*"
}

resource "aws_lambda_permission" "user_api" {
  count = local.create_api_gateway ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway-User"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names.user_service
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main[0].execution_arn}/*/*"
}

resource "aws_lambda_permission" "volunteer_api" {
  count = local.create_api_gateway ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway-Volunteer"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names.volunteer_service
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main[0].execution_arn}/*/*"
}

resource "aws_lambda_permission" "location_api" {
  count = local.create_api_gateway ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway-Location"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_names.location_service
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main[0].execution_arn}/*/*"
}
