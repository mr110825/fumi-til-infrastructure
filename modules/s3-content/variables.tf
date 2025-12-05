variable "bucket_name" {
  description = "S3バケット名"
  type        = string
}

variable "tags" {
  description = "追加タグ"
  type        = map(string)
  default     = {}
}