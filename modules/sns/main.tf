# SNSトピック
resource "aws_sns_topic" "this" {
  name = var.topic_name

  tags = merge(
    { Name = var.topic_name },
    var.tags
  )
}

# SNS Subscription（メール通知）
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = var.email
}