output "dashboard_name" {
  description = "CloudWatchダッシュボード名"
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}

output "dashboard_url" {
  description = "CloudWatchダッシュボードURL"
  value       = "https://ap-northeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-northeast-1#dashboards:name=${aws_cloudwatch_dashboard.this.dashboard_name}"
}

output "alarm_5xx_arn" {
  description = "5xxエラーアラームのARN"
  value       = aws_cloudwatch_metric_alarm.error_5xx.arn
}

output "alarm_4xx_arn" {
  description = "4xxエラーアラームのARN"
  value       = aws_cloudwatch_metric_alarm.error_4xx.arn
}