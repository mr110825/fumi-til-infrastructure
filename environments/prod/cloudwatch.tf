# CloudWatch Dashboard
# CloudFrontの主要メトリクスを可視化
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "fumi-til-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # リクエスト数（時系列グラフ）
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CloudFront リクエスト数"
          region = "us-east-1" # CloudFrontメトリクスはus-east-1
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.main.id, "Region", "Global"]
          ]
          period = 300 # 5分間隔
          stat   = "Sum"
        }
      },
      # エラー率（時系列グラフ）
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "CloudFront エラー率 (%)"
          region = "us-east-1"
          metrics = [
            ["AWS/CloudFront", "4xxErrorRate", "DistributionId", aws_cloudfront_distribution.main.id, "Region", "Global"],
            [".", "5xxErrorRate", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
        }
      },
      # バイト転送量（時系列グラフ）
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "CloudFront データ転送量 (Bytes)"
          region = "us-east-1"
          metrics = [
            ["AWS/CloudFront", "BytesDownloaded", "DistributionId", aws_cloudfront_distribution.main.id, "Region", "Global"],
            [".", "BytesUploaded", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      # キャッシュヒット率（時系列グラフ）
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "CloudFront キャッシュヒット率 (%)"
          region = "us-east-1"
          metrics = [
            ["AWS/CloudFront", "CacheHitRate", "DistributionId", aws_cloudfront_distribution.main.id, "Region", "Global"]
          ]
          period = 300
          stat   = "Average"
        }
      }
    ]
  })
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://ap-northeast-1.console.aws.amazon.com/cloudwatch/home?region=ap-northeast-1#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

# CloudWatch Alarms
# エラー率が閾値を超えたらSNS通知

# 5xxエラー率アラーム（サーバーエラー）
resource "aws_cloudwatch_metric_alarm" "error_5xx" {
  alarm_name          = "fumi-til-5xx-error-rate"
  alarm_description   = "CloudFront 5xxエラー率が1%を超えた場合にアラート"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2 # 2回連続で閾値超過したらアラート
  metric_name         = "5xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300 # 5分間隔
  statistic           = "Average"
  threshold           = 1              # 1%超過でアラート
  treat_missing_data  = "notBreaching" # データなしは正常扱い

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
    Region         = "Global"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "fumi-til-5xx-error-rate"
  }
}

# 4xxエラー率アラーム（クライアントエラー）
resource "aws_cloudwatch_metric_alarm" "error_4xx" {
  alarm_name          = "fumi-til-4xx-error-rate"
  alarm_description   = "CloudFront 4xxエラー率が5%を超えた場合にアラート"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = 300
  statistic           = "Average"
  threshold           = 5 # 5%超過でアラート（4xxは多めに許容）
  treat_missing_data  = "notBreaching"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
    Region         = "Global"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "fumi-til-4xx-error-rate"
  }
}