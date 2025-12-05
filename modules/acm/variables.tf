variable "domain_name" {
  description = "証明書のドメイン名"
  type        = string
}

# CloudFront用ACM証明書はus-east-1に存在するため
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "fumi-til"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}