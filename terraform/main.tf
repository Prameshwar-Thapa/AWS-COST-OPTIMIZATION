# Terraform Configuration with S3 Backend
terraform {
  required_version = ">= 1.0"

  # S3 Backend for State Management
  backend "s3" {
    bucket  = "aws-s3-backend-bucket-1234" # Replace with your bucket name
    key     = "ec2-cost-optimization/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    # Optional: for state locking
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "EC2CostOptimization"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# Data Sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# SNS Module
module "sns" {
  source = "./modules/sns"

  project_name = var.project_name
  environment  = var.environment
  email        = var.notification_email
}

# IAM Module
module "iam" {
  source = "./modules/iam"

  project_name  = var.project_name
  environment   = var.environment
  sns_topic_arn = module.sns.topic_arn
}

# Lambda Module
module "lambda" {
  source = "./modules/lambda"

  project_name  = var.project_name
  environment   = var.environment
  iam_role_arn  = module.iam.lambda_role_arn
  sns_topic_arn = module.sns.topic_arn
}

# EventBridge Module
module "eventbridge" {
  source = "./modules/eventbridge"

  project_name       = var.project_name
  environment        = var.environment
  start_function_arn = module.lambda.start_function_arn
  stop_function_arn  = module.lambda.stop_function_arn
  start_schedule     = var.start_schedule
  stop_schedule      = var.stop_schedule
}