terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# ACM証明書を検索（CloudFront用はus-east-1で作成済み）
data "aws_acm_certificate" "this" {
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}