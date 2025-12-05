variable "bucket_name" {
  description = "S3バケット名"
  type        = string
}

variable "expiration_days" {
  description = "ログの保持日数"
  type        = number
  default     = 90
}

variable "tags" {
  description = "追加タグ"
  type        = map(string)
  default     = {}
}