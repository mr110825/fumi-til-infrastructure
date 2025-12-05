output "zone_id" {
  description = "Route53ホストゾーンID"
  value       = data.aws_route53_zone.this.zone_id
}

output "record_fqdn" {
  description = "作成したレコードのFQDN"
  value       = aws_route53_record.root.fqdn
}