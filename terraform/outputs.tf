# SNS Outputs
output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  value       = module.sns.topic_arn
}

output "sns_subscription_arn" {
  description = "ARN of the SNS email subscription"
  value       = module.sns.subscription_arn
}

# Lambda Outputs
output "start_function_name" {
  description = "Name of the start instances Lambda function"
  value       = module.lambda.start_function_name
}

output "stop_function_name" {
  description = "Name of the stop instances Lambda function"
  value       = module.lambda.stop_function_name
}

output "start_function_arn" {
  description = "ARN of the start instances Lambda function"
  value       = module.lambda.start_function_arn
}

output "stop_function_arn" {
  description = "ARN of the stop instances Lambda function"
  value       = module.lambda.stop_function_arn
}

# EventBridge Outputs
output "start_rule_name" {
  description = "Name of the EventBridge rule for starting instances"
  value       = module.eventbridge.start_rule_name
}

output "stop_rule_name" {
  description = "Name of the EventBridge rule for stopping instances"
  value       = module.eventbridge.stop_rule_name
}

# IAM Outputs
output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = module.iam.lambda_role_arn
}

# Summary Output
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    region             = var.aws_region
    project_name       = var.project_name
    environment        = var.environment
    notification_email = var.notification_email
    start_schedule     = var.start_schedule
    stop_schedule      = var.stop_schedule
    sns_topic          = module.sns.topic_arn
    start_function     = module.lambda.start_function_name
    stop_function      = module.lambda.stop_function_name
  }
}