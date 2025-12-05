variable "domain_name" {
  description = "ドメイン名"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFrontのドメイン名"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "CloudFrontのホストゾーンID"
  type        = string
}

variable "tags" {
  description = "追加タグ"
  type        = map(string)
  default     = {}
}