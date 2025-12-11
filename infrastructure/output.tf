output "api_url" {
  description = "The URL of the API Gateway endpoint"
  value       = aws_api_gateway_stage.dev_stage.invoke_url
}
