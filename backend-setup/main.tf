terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # メジャーバージョン固定でBreaking Change防止
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"  # 主要読者が日本のため東京リージョン
}

# tfstate保存用S3バケット：バージョニング有効：誤操作時のロールバック用
resource "aws_s3_bucket" "tfstate" {
  bucket = "fumi-til-tfstate"  # S3バケット名はグローバルで一意である必要がある

  tags = {
    Name    = "fumi-til-tfstate"
    Project = "fumi-til"
  }
}

# tfstate保存用S3バケット：バージョニング有効化（ロールバック可能にする）
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

# tfstate保存用S3バケット：サーバーサイド暗号化
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# tfstate保存用S3バケット：パブリックアクセスブロック
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDBテーブル（ロック用）
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "fumi-til-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "fumi-til-tfstate-lock"
    Project = "fumi-til"
  }
}

# 出力
output "s3_bucket_name" {
  value       = aws_s3_bucket.tfstate.bucket
  description = "tfstate保存用S3バケット名"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.tfstate_lock.name
  description = "tfstateロック用DynamoDBテーブル名"
}