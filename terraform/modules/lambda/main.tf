# Create ZIP files for Lambda functions
data "archive_file" "start_lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/../lambda/start_prod.py"
  output_path = "${path.module}/start_lambda.zip"
}

data "archive_file" "stop_lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/../lambda/stop_prod.py"
  output_path = "${path.module}/stop_lambda.zip"
}

# Start Instances Lambda Function
resource "aws_lambda_function" "start_instances" {
  filename         = data.archive_file.start_lambda_zip.output_path
  function_name    = "${var.project_name}-start-instances"
  role            = var.iam_role_arn
  handler         = "start_prod.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  source_code_hash = data.archive_file.start_lambda_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }

  tags = {
    Name = "${var.project_name}-start-instances"
  }
}

# Stop Instances Lambda Function
resource "aws_lambda_function" "stop_instances" {
  filename         = data.archive_file.stop_lambda_zip.output_path
  function_name    = "${var.project_name}-stop-instances"
  role            = var.iam_role_arn
  handler         = "stop_prod.lambda_handler"
  runtime         = "python3.9"
  timeout         = 300
  source_code_hash = data.archive_file.stop_lambda_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN = var.sns_topic_arn
    }
  }

  tags = {
    Name = "${var.project_name}-stop-instances"
  }
}