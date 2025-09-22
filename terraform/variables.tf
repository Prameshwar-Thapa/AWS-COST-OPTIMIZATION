# Core Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ec2-cost-optimization"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

# Notification Configuration
variable "notification_email" {
  description = "Email address for notifications"
  type        = string
}

# Scheduling Configuration
variable "start_schedule" {
  description = "Cron expression for starting instances (8 AM weekdays UTC)"
  type        = string
  default     = "cron(0 8 ? * MON-FRI *)"
}

variable "stop_schedule" {
  description = "Cron expression for stopping instances (6 PM weekdays UTC)"
  type        = string
  default     = "cron(0 18 ? * MON-FRI *)"
}