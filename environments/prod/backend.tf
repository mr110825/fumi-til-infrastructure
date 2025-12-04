# tfstateをS3で管理し、DynamoDBでロックを取得する設定

terraform {
  backend "s3" {
    bucket         = "fumi-til-tfstate"
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "fumi-til-tfstate-lock"
  }
}