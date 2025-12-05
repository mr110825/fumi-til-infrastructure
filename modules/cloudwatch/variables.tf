variable "name_prefix" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  type        = string
}

variable "sns_topic_arn" {
  description = "アラート通知先のSNSトピックARN"
  type        = string
}

variable "error_5xx_threshold" {
  description = "5xxエラー率の閾値（%）"
  type        = number
  default     = 1
}

variable "error_4xx_threshold" {
  description = "4xxエラー率の閾値（%）"
  type        = number
  default     = 5
}

variable "tags" {
  description = "追加タグ"
  type        = map(string)
  default     = {}
}