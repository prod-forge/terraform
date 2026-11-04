output "sns_topic_arn" {
  description = "SNS topic that receives every alarm"
  value       = aws_sns_topic.alerts.arn
}
