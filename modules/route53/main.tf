# Route53ホストゾーン（既存を参照）
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

# Aレコード（CloudFrontへのAlias）
resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}