# # SNS トピック（通知の送信先を束ねる「トピック」）
# resource "aws_sns_topic" "alerts" {
#   name = "fumi-til-alerts"

#   tags = {
#     Name = "fumi-til-alerts"
#   }
# }

# # 変数定義（メールアドレス）
# variable "alert_email" {
#   description = "Email address for alerts"
#   type        = string
#   sensitive   = true # sensitive = true により、terraform plan/apply時に値がマスクされる
# }

# # SNS Subscription（トピックの購読設定）
# resource "aws_sns_topic_subscription" "email" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "email" # protocol = "email" でメール通知を設定
#   endpoint  = var.alert_email
# }

# # Output（他のリソースから参照するためのARN出力）
# # CloudWatch Alarmの通知先として使用する
# output "sns_topic_arn" {
#   description = "SNS Topic ARN for CloudWatch Alarms"
#   value       = aws_sns_topic.alerts.arn
# }