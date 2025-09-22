output "start_function_name" {
  description = "Name of the start instances function"
  value       = aws_lambda_function.start_instances.function_name
}

output "stop_function_name" {
  description = "Name of the stop instances function"
  value       = aws_lambda_function.stop_instances.function_name
}

output "start_function_arn" {
  description = "ARN of the start instances function"
  value       = aws_lambda_function.start_instances.arn
}

output "stop_function_arn" {
  description = "ARN of the stop instances function"
  value       = aws_lambda_function.stop_instances.arn
}