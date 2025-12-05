# AWS Budgets
# 月額コストが閾値を超えたらメール通知
resource "aws_budgets_budget" "monthly" {
  name         = "fumi-til-monthly-budget"
  budget_type  = "COST"
  limit_amount = "5"        # $5/月
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # 80%到達で通知
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # 100%到達で通知
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # 予測で100%超過しそうな場合に通知
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}