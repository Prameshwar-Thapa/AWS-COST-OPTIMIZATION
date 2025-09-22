# SNS Topic for Notifications
resource "aws_sns_topic" "notifications" {
  name = "${var.project_name}-alerts"
  
  tags = {
    Name = "${var.project_name}-alerts"
  }
}

# Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.email
}