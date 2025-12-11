# zipping python files
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambda/chatbot-function.py"
  output_path = "../lambda/chatbot-function.zip"
}

# Create an IAM role for Lambda execution
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

}

# Create an IAM policy for S3 read access
resource "aws_iam_policy" "s3_read_policy" {
  name        = "s3-read-policy"
  description = "Policy to allow Lambda to read from S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::adi-cloud-resume-challenge-bucket",
          "arn:aws:s3:::adi-cloud-resume-challenge-bucket/*"
        ]
      }
    ]
  })
}

# Create an IAM policy for Bedrock access
resource "aws_iam_policy" "bedrock_access_policy" {
  name        = "bedrock-access-policy"
  description = "Policy to allow Lambda to access Bedrock service"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:ListMarketplaceModels",
          "bedrock:SubscribeToModel",
          "bedrock:DescribeModel"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Create an IAM policy for Marketplace access
resource "aws_iam_policy" "marketplace_access_policy" {
  name        = "marketplace-access-policy"
  description = "Policy to allow Lambda to access Marketplace"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "aws-marketplace:ViewSubscriptions",
          "aws-marketplace:Subscribe",
          "aws-marketplace:Unsubscribe",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach the AWSLambdaBasicExecutionRole policy to the IAM role
data "aws_iam_policy" "lambda_basic_execution" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = data.aws_iam_policy.lambda_basic_execution.arn
}

# Attach the S3 read policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "s3_read_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

# Attach the Bedrock access policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "bedrock_access_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.bedrock_access_policy.arn
}

# Attach the Marketplace access policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "marketplace_access_policy_attach" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.marketplace_access_policy.arn
}

# Create a Lambda function for the chat bot
resource "aws_lambda_function" "chat_bot_lambda" {
  function_name = "chat-bot-lambda-function"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "chatbot-function.lambda_handler"
  runtime       = "python3.8"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = 30  # Set to 30 seconds (default is 3 seconds)
  memory_size = 512 # Set to 512 MB (default is 128 MB)

  tags = {
    Name = "chat_bot_lambda_function"
  }
}
