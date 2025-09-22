output "start_rule_name" {
  description = "The name of the EventBridge rule for starting instances"
  value       = aws_cloudwatch_event_rule.start_schedule.name
}

output "stop_rule_name" {
  description = "The name of the EventBridge rule for stopping instances"
  value       = aws_cloudwatch_event_rule.stop_schedule.name
}
