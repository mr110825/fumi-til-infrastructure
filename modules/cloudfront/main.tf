locals {
  name_prefix = var.name_prefix != null ? var.name_prefix : replace(var.domain_name, ".", "-")
}

# CloudFront OAC（Origin Access Control）
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${local.name_prefix}-oac"
  description                       = "OAC for ${local.name_prefix} S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Function（URLリライト）
resource "aws_cloudfront_function" "rewrite" {
  name    = "${local.name_prefix}-url-rewrite"
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

# CloudFront ディストリビューション
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  price_class         = var.price_class
  comment             = "${local.name_prefix} blog distribution"

  tags = merge(
    { Name = "${local.name_prefix}-distribution" }, 
    var.tags
  )

  # オリジン設定（S3）
  origin {
    domain_name              = var.s3_content_bucket_regional_domain_name
    origin_id                = "S3-${var.s3_content_bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  # デフォルトキャッシュ動作
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${var.s3_content_bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # CachingOptimized（AWS管理ポリシー）
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
    bucket          = var.s3_logs_bucket_domain_name
    prefix          = "cloudfront/"
    include_cookies = false
  }

  # カスタムエラーレスポンス
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
}

# S3バケットポリシー（CloudFrontからのアクセス許可）
resource "aws_s3_bucket_policy" "content" {
  bucket = var.s3_content_bucket_id
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
        Resource = "${var.s3_content_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
          }
        }
      }
    ]
  })
}