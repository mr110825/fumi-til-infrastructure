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

# State移行：cloudfront
moved {
  from = aws_cloudfront_origin_access_control.main
  to   = module.cloudfront.aws_cloudfront_origin_access_control.this
}

moved {
  from = aws_cloudfront_distribution.main
  to   = module.cloudfront.aws_cloudfront_distribution.this
}

moved {
  from = aws_cloudfront_function.rewrite
  to   = module.cloudfront.aws_cloudfront_function.rewrite
}

moved {
  from = aws_s3_bucket_policy.content
  to   = module.cloudfront.aws_s3_bucket_policy.content
}

# State移行：route53
moved {
  from = aws_route53_record.root
  to   = module.route53.aws_route53_record.root
}

# State移行：iam-github-actions
moved {
  from = aws_iam_openid_connect_provider.github
  to   = module.iam_github_actions.aws_iam_openid_connect_provider.github
}

moved {
  from = aws_iam_role.github_actions
  to   = module.iam_github_actions.aws_iam_role.github_actions
}

moved {
  from = aws_iam_role_policy.github_actions
  to   = module.iam_github_actions.aws_iam_role_policy.github_actions
}

# State移行：cloudwatch
moved {
  from = aws_cloudwatch_dashboard.main
  to   = module.cloudwatch.aws_cloudwatch_dashboard.this
}

moved {
  from = aws_cloudwatch_metric_alarm.error_5xx
  to   = module.cloudwatch.aws_cloudwatch_metric_alarm.error_5xx
}

moved {
  from = aws_cloudwatch_metric_alarm.error_4xx
  to   = module.cloudwatch.aws_cloudwatch_metric_alarm.error_4xx
}