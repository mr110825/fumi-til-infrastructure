output "certificate_arn" {
  description = "ACM証明書のARN"
  value       = data.aws_acm_certificate.this.arn
}