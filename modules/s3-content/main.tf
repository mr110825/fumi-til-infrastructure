# コンテンツ用S3バケット
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(
    { Name = var.bucket_name },
    var.tags
  )
}

# パブリックアクセスを完全にブロック
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# サーバーサイド暗号化（SSE-S3）
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}