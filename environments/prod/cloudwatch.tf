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
          region = "us-east-1"  # CloudFrontメトリクスはus-east-1
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.main.id, "Region", "Global"]
          ]
          period = 300  # 5分間隔
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