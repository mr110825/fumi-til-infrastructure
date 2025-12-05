# Terraformとプロバイダーのバージョン制約

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"

  # リソースに共通タグを自動付与する設定
  # タグ付け漏れを防ぐこと目的
  default_tags {
    tags = {
      Project     = "fumi-til"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

# CloudFront用ACM証明書はus-east-1に存在するため
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "fumi-til"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}