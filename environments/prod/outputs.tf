output "cloudfront_domain_name" {
  description = "CloudFrontのドメイン名"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID（キャッシュ無効化で使用）"
  value       = aws_cloudfront_distribution.main.id
}

output "s3_content_bucket" {
  description = "コンテンツ用S3バケット名"
  value       = aws_s3_bucket.content.bucket
}

output "github_actions_role_arn" {
  description = "GitHub Actions用IAMロールのARN"
  value       = aws_iam_role.github_actions.arn
}