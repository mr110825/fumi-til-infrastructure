variable "topic_name" {
  description = "SNSトピック名"
  type        = string
}

variable "email" {
  description = "通知先メールアドレス"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "追加タグ"
  type        = map(string)
  default     = {}
}