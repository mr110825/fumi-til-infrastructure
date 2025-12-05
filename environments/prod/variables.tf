# ACM証明書のARN
variable "acm_certificate_arn" {
  description = "ACM証明書のARN（us-east-1）"
  type        = string
  default     = "arn:aws:acm:us-east-1:610718856890:certificate/6dfe6ad8-dde1-4c99-961d-120304d9a7e5"
}

variable "alert_email" {
  description = "アラート通知先メールアドレス"
  type        = string
  sensitive   = true
}
