output "topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.notifications.arn
}

output "subscription_arn" {
  description = "ARN of the email subscription"
  value       = aws_sns_topic_subscription.email.arn
}