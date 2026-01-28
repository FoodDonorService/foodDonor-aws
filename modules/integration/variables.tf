variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "sqs_queue_names" {
  description = "SQS queue names"
  type = object({
    match_queue = string
  })
  default = null
}

# API Gateway variables (shared with api_gateway_variables.tf)
variable "api_gateway_stage" {
  description = "API Gateway stage name"
  type        = string
  default     = null
}

variable "cognito_client_id" {
  description = "Cognito User Pool Client ID"
  type        = string
  default     = null
}

variable "cognito_issuer_url" {
  description = "Cognito Issuer URL"
  type        = string
  default     = null
}

variable "lambda_invoke_arns" {
  description = "Lambda function invoke ARNs"
  type = object({
    donor_service     = string
    recipient_service = string
    user_service      = string
    volunteer_service = string
    location_service  = string
  })
  default = null
}

variable "lambda_function_names" {
  description = "Lambda function names"
  type = object({
    donor_service     = string
    recipient_service = string
    user_service      = string
    volunteer_service = string
    location_service  = string
  })
  default = null
}

variable "cors_allowed_origins" {
  description = "Additional CORS allowed origins"
  type        = list(string)
  default     = []
}
