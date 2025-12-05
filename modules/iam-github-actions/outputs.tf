output "role_arn" {
  description = "GitHub Actions用IAMロールのARN"
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "GitHub Actions用IAMロール名"
  value       = aws_iam_role.github_actions.name
}

output "oidc_provider_arn" {
  description = "OIDC ProviderのARN"
  value       = aws_iam_openid_connect_provider.github.arn
}