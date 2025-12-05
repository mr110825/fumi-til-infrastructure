variable "domain_name" {
  description = "CloudFrontで使用するドメイン名"
  type        = string
}

variable "s3_content_bucket_regional_domain_name" {
  description = "コンテンツ用S3バケットのリージョナルドメイン名"
  type        = string
}

variable "s3_content_bucket_id" {
  description = "コンテンツ用S3バケットID"
  type        = string
}

variable "s3_content_bucket_arn" {
  description = "コンテンツ用S3バケットARN"
  type        = string
}

variable "s3_logs_bucket_domain_name" {
  description = "ログ用S3バケットのドメイン名"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM証明書のARN（us-east-1）"
  type        = string
}

variable "price_class" {
  description = "CloudFrontのプライスクラス"
  type        = string
  default     = "PriceClass_200"
}

variable "tags" {
  description = "追加タグ"
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "リソース名のプレフィックス"
  type        = string
  default     = null
}