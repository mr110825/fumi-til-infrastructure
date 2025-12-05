output "cloudfront_domain_name" {
  description = "CloudFrontのドメイン名"
  value       = module.cloudfront.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID（キャッシュ無効化で使用）"
  value       = module.cloudfront.distribution_id
}

output "s3_content_bucket" {
  description = "コンテンツ用S3バケット名"
  value       = module.s3_content.bucket_id
}

output "github_actions_role_arn" {
  description = "GitHub Actions用IAMロールのARN"
  value       = module.iam_github_actions.role_arn
}

output "sns_topic_arn" {
  description = "SNSトピックARN"
  value       = module.sns.topic_arn
}

output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = module.cloudwatch.dashboard_url
}