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

# CloudFront OAC（Origin Access Control）
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "fumi-til-oac"
  description                       = "OAC for fumi-til S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront ディストリビューション
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["fumi-til.com"]
  price_class         = "PriceClass_200"
  comment             = "fumi-til blog distribution"

  # オリジン設定（S3）
  origin {
    domain_name              = module.s3_content.bucket_regional_domain_name
    origin_id                = "S3-fumi-til-content"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  # デフォルトキャッシュ動作
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-fumi-til-content"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite.arn
    }
  }

  # SSL/TLS設定
  viewer_certificate {
    acm_certificate_arn      = module.acm.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # 地理的制限（なし）
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # アクセスログ設定
  logging_config {
    bucket          = module.s3_logs.bucket_domain_name
    prefix          = "cloudfront/"
    include_cookies = false
  }

  # カスタムエラーレスポンス（SPAやHugo用）
  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  tags = {
    Name = "fumi-til-distribution"
  }
}

# S3バケットポリシー
resource "aws_s3_bucket_policy" "content" {
  bucket = module.s3_content.bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3_content.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
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
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}

# CloudFront Function（URLリライト）
resource "aws_cloudfront_function" "rewrite" {
  name    = "fumi-til-url-rewrite"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOF
    function handler(event) {
      var request = event.request;
      var uri = request.uri;
      
      if (uri.endsWith('/')) {
        request.uri += 'index.html';
      }
      else if (!uri.includes('.')) {
        request.uri += '/index.html';
      }
      
      return request;
    }
  EOF
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

# State移行：s3-content（参考用）
# moved {
#   from = aws_s3_bucket.content
#   to   = module.s3_content.aws_s3_bucket.this
# }

# moved {
#   from = aws_s3_bucket_public_access_block.content
#   to   = module.s3_content.aws_s3_bucket_public_access_block.this
# }

# moved {
#   from = aws_s3_bucket_server_side_encryption_configuration.content
#   to   = module.s3_content.aws_s3_bucket_server_side_encryption_configuration.this
# }

# State移行：s3-logs
# moved {
#   from = aws_s3_bucket.logs
#   to   = module.s3_logs.aws_s3_bucket.this
# }

# moved {
#   from = aws_s3_bucket_public_access_block.logs
#   to   = module.s3_logs.aws_s3_bucket_public_access_block.this
# }

# moved {
#   from = aws_s3_bucket_server_side_encryption_configuration.logs
#   to   = module.s3_logs.aws_s3_bucket_server_side_encryption_configuration.this
# }

# moved {
#   from = aws_s3_bucket_ownership_controls.logs
#   to   = module.s3_logs.aws_s3_bucket_ownership_controls.this
# }

# moved {
#   from = aws_s3_bucket_lifecycle_configuration.logs
#   to   = module.s3_logs.aws_s3_bucket_lifecycle_configuration.this
# }

# State移行：sns
# moved {
#   from = aws_sns_topic.alerts
#   to   = module.sns.aws_sns_topic.this
# }

# moved {
#   from = aws_sns_topic_subscription.email
#   to   = module.sns.aws_sns_topic_subscription.email
# }