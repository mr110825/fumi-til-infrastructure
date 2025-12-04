# コンテンツ用S3バケット
resource "aws_s3_bucket" "content" {
  bucket = "fumi-til-content"

  tags = {
    Name = "fumi-til-content"
  }
}

# パブリックアクセスを完全にブロック
resource "aws_s3_bucket_public_access_block" "content" {
  bucket = aws_s3_bucket.content.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# サーバーサイド暗号化（SSE-S3）
resource "aws_s3_bucket_server_side_encryption_configuration" "content" {
  bucket = aws_s3_bucket.content.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ログ用S3バケット（CloudFrontアクセスログ保存用）
resource "aws_s3_bucket" "logs" {
  bucket = "fumi-til-logs"

  tags = {
    Name = "fumi-til-logs"
  }
}

# パブリックアクセスを完全にブロック
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# サーバーサイド暗号化（SSE-S3）
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFrontがログを書き込むためのオーナーシップ設定
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# ライフサイクルルール：90日でログを自動削除
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    # 全オブジェクトに適用（空のfilterはバケット内全体を対象とする）
    filter {}

    expiration {
      days = 90
    }
  }
}

# CloudFront OAC（Origin Access Control）
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "fumi-til-oac"
  description                       = "OAC for fumi-til S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = ["fumi-til.com"]
  price_class         = "PriceClass_200"
  comment             = "fumi-til blog distribution"

  # オリジン設定（S3）
  origin {
    domain_name              = aws_s3_bucket.content.bucket_regional_domain_name
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

    # キャッシュポリシー（CachingOptimized）
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.rewrite.arn
    }
  }

  # SSL/TLS設定
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
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
    bucket          = aws_s3_bucket.logs.bucket_domain_name
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
  bucket = aws_s3_bucket.content.id
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
        Resource = "${aws_s3_bucket.content.arn}/*"
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

# CloudFront Function（URL修正）
resource "aws_cloudfront_function" "rewrite" {
  name    = "fumi-til-url-rewrite"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = <<-EOF
    function handler(event) {
      var request = event.request;
      var uri = request.uri;
      
      // URIが/で終わる場合、index.htmlを付加
      if (uri.endsWith('/')) {
        request.uri += 'index.html';
      }
      // URIに拡張子がない場合、/index.htmlを付加
      else if (!uri.includes('.')) {
        request.uri += '/index.html';
      }
      
      return request;
    }
  EOF
}