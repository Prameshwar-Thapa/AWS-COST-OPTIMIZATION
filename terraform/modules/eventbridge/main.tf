# EventBridge Rule for Starting Instances
resource "aws_cloudwatch_event_rule" "start_schedule" {
  name                = "${var.project_name}-start-schedule"
  description         = "Start EC2 instances on weekdays at 8 AM UTC"
  schedule_expression = var.start_schedule

  tags = {
    Name = "${var.project_name}-start-schedule"
  }
}

# EventBridge Rule for Stopping Instances
resource "aws_cloudwatch_event_rule" "stop_schedule" {
  name                = "${var.project_name}-stop-schedule"
  description         = "Stop EC2 instances on weekdays at 6 PM UTC"
  schedule_expression = var.stop_schedule

  tags = {
    Name = "${var.project_name}-stop-schedule"
  }
}

# EventBridge Target for Start Rule
resource "aws_cloudwatch_event_target" "start_target" {
  rule      = aws_cloudwatch_event_rule.start_schedule.name
  target_id = "StartInstancesTarget"
  arn       = var.start_function_arn
}

# EventBridge Target for Stop Rule
resource "aws_cloudwatch_event_target" "stop_target" {
  rule      = aws_cloudwatch_event_rule.stop_schedule.name
  target_id = "StopInstancesTarget"
  arn       = var.stop_function_arn
}

# Lambda Permissions for EventBridge
resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.start_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_schedule.arn
}

resource "aws_lambda_permission" "allow_eventbridge_stop" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.stop_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_schedule.arn
}