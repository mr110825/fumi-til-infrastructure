# モジュール
module "s3_content" {
  source      = "../../modules/s3-content"
  bucket_name = "fumi-til-content"
}

module "s3_logs" {
  source          = "../../modules/s3-logs"
  bucket_name     = "fumi-til-logs"
  expiration_days = 90
}

module "sns" {
  source     = "../../modules/sns"
  topic_name = "fumi-til-alerts"
  email      = var.alert_email
}

module "acm" {
  source      = "../../modules/acm"
  domain_name = "fumi-til.com"

  providers = {
    aws = aws.us_east_1
  }
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  domain_name                            = "fumi-til.com"
  name_prefix                            = "fumi-til" # 元の名前を維持
  s3_content_bucket_regional_domain_name = module.s3_content.bucket_regional_domain_name
  s3_content_bucket_id                   = module.s3_content.bucket_id
  s3_content_bucket_arn                  = module.s3_content.bucket_arn
  s3_logs_bucket_domain_name             = module.s3_logs.bucket_domain_name
  acm_certificate_arn                    = module.acm.certificate_arn
}

module "route53" {
  source = "../../modules/route53"

  domain_name               = "fumi-til.com"
  cloudfront_domain_name    = module.cloudfront.domain_name
  cloudfront_hosted_zone_id = module.cloudfront.hosted_zone_id
}

module "iam_github_actions" {
  source = "../../modules/iam-github-actions"

  name_prefix                 = "fumi-til"
  github_repo                 = "mr110825/blowfish_my_blog"
  github_branch               = "main"
  s3_bucket_arn               = module.s3_content.bucket_arn
  cloudfront_distribution_arn = module.cloudfront.distribution_arn
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  name_prefix                = "fumi-til"
  cloudfront_distribution_id = module.cloudfront.distribution_id
  sns_topic_arn              = module.sns.topic_arn
}
