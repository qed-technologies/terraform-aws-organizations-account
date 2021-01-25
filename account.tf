resource "aws_organizations_account" "account" {
  provider = aws.master

  name                       = var.account_name
  email                      = var.email_owner
  iam_user_access_to_billing = var.iam_user_access_to_billing
  parent_id                  = var.organizational_unit_id
  role_name                  = var.role_name

  lifecycle {
    ignore_changes = [role_name, iam_user_access_to_billing]
  }

  tags = merge(
    {
      "Name" = format("%s", var.account_name)
    },
    var.tags_account,
    var.tags
  )
}

# Delay resource creation for 5 minutes so we can 
# to give AWS enough time to provision the new account
resource "null_resource" "account_delay" {
  provisioner "local-exec" {
    command = "sleep 480"
  }
  triggers = {
    "account_id" = aws_organizations_account.account.id
  }
}

resource "aws_budgets_budget" "budget" {
  provider = aws.master

  name              = "Overall monthly for ${aws_organizations_account.account.name}"
  budget_type       = "COST"
  limit_amount      = var.budget_limit_amount
  limit_unit        = "USD"
  time_period_start = "1970-01-01_00:00"
  time_unit         = "MONTHLY"

  cost_filters = {
    LinkedAccount = aws_organizations_account.account.id
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_emails
  }
}
