# GitHub OIDC Provider
# GitHub Actionsがアクセスキーなしで AWSにアクセスするための信頼関係
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub OIDCのthumbprintはAWSが自動検証するため、
  # 任意の値でも動作する（AWS側で実際の証明書を検証）
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]

  tags = {
    Name = "github-actions-oidc"
  }
}

# GitHub Actions用IAMロール
resource "aws_iam_role" "github_actions" {
  name = "fumi-til-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # mainブランチからのみ許可
            "token.actions.githubusercontent.com:sub" = "repo:mr110825/blowfish_my_blog:ref:refs/heads/main"
          }
        }
      }
    ]
  })

  tags = {
    Name = "fumi-til-github-actions-role"
  }
}

# GitHub Actions用IAMポリシー
resource "aws_iam_role_policy" "github_actions" {
  name = "fumi-til-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Deploy"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_content.bucket_arn,
          "${module.s3_content.bucket_arn}/*"
        ]
      },
      {
        Sid    = "CloudFrontInvalidation"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation"
        ]
        Resource = module.cloudfront.distribution_arn
      }
    ]
  })
}