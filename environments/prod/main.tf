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