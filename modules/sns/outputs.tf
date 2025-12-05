output "topic_arn" {
  description = "SNSトピックARN"
  value       = aws_sns_topic.this.arn
}

output "topic_name" {
  description = "SNSトピック名"
  value       = aws_sns_topic.this.name
}