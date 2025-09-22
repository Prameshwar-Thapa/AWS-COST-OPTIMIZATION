variable "project_name" {
  description = "The name of the project, used for naming resources"
  type        = string
  
}

variable "environment" {
  description = "The environment (e.g., dev, prod)"
  type        = string
  
}

variable "start_function_arn" {
  description = "The ARN of the Lambda function to start instances"
  type        = string
  
}

variable "stop_function_arn" {
  description = "The ARN of the Lambda function to stop instances"
  type        = string
  
}

variable "start_schedule" {
  description = "The cron expression for starting instances (e.g., 'cron(0 8 ? * MON-FRI *)' for 8 AM UTC on weekdays)"
  type        = string
  }

variable "stop_schedule" {
  description = "The cron expression for stopping instances (e.g., 'cron(0 18 ? * MON-FRI *)' for 6 PM UTC on weekdays)"
  type        = string
  }