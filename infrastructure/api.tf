# Create an API Gateway REST API
resource "aws_api_gateway_rest_api" "chat-bot-api" {
  name        = "chat-bot-api-gateway"
  description = "API Gateway for Chat Bot Service through Lambda"
}

# Create a resource under the API
resource "aws_api_gateway_resource" "chatbot_resource" {
  rest_api_id = aws_api_gateway_rest_api.chat-bot-api.id
  parent_id   = aws_api_gateway_rest_api.chat-bot-api.root_resource_id
  path_part   = "chatbot"
}

# Create a POST method for the resource
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.chat-bot-api.id
  resource_id   = aws_api_gateway_resource.chatbot_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integrate the POST method with the Lambda function
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.chat-bot-api.id
  resource_id             = aws_api_gateway_resource.chatbot_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.chat_bot_lambda.invoke_arn
}

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat_bot_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chat-bot-api.execution_arn}/*/*"
}

# Create a stage for the API
resource "aws_api_gateway_stage" "dev_stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.chat-bot-api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

# Deploy the API Gateway
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.chat-bot-api.id
}
