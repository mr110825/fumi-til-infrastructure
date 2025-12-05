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

# Route53ホストゾーン
data "aws_route53_zone" "main" {
  name         = "fumi-til.com"
  private_zone = false
}

# Aレコード（CloudFrontへのAlias）
resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "fumi-til.com"
  type    = "A"

  alias {
    name                   = module.cloudfront.domain_name
    zone_id                = module.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }
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