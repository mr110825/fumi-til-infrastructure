variable "name_prefix" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "github_repo" {
  description = "GitHub リポジトリ（owner/repo形式）"
  type        = string
}

variable "github_branch" {
  description = "許可するブランチ"
  type        = string
  default     = "main"
}

variable "s3_bucket_arn" {
  description = "デプロイ先S3バケットのARN"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront DistributionのARN"
  type        = string
}

variable "tags" {
  description = "追加タグ"
  type        = map(string)
  default     = {}
}