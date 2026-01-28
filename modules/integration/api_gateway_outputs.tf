output "api_gateway_id" {
  description = "API Gateway ID"
  value       = local.create_api_gateway ? aws_apigatewayv2_api.main[0].id : null
}

output "api_gateway_arn" {
  description = "API Gateway ARN"
  value       = local.create_api_gateway ? aws_apigatewayv2_api.main[0].arn : null
}

output "api_gateway_execution_arn" {
  description = "API Gateway execution ARN"
  value       = local.create_api_gateway ? aws_apigatewayv2_api.main[0].execution_arn : null
}

output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  value       = local.create_api_gateway ? aws_apigatewayv2_stage.main[0].invoke_url : null
}

output "api_gateway_stage_name" {
  description = "API Gateway stage name"
  value       = local.create_api_gateway ? aws_apigatewayv2_stage.main[0].name : null
}

output "authorizer_id" {
  description = "API Gateway authorizer ID"
  value       = local.create_api_gateway ? aws_apigatewayv2_authorizer.cognito[0].id : null
}
