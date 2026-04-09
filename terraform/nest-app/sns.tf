# SNS topic for notifications
resource "aws_sns_topic" "user_updates" {
  name = "${var.environment}-${var.project_name}-sns"
}

# Email subscription to SNS topic
resource "aws_sns_topic_subscription" "notification_topic" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "email"
  endpoint  = var.operator_email
}