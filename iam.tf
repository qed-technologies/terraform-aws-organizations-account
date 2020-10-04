resource "aws_iam_account_password_policy" "this" {
  provider = aws.member

  max_password_age               = var.max_password_age
  minimum_password_length        = var.minimum_password_length
  require_lowercase_characters   = var.require_lowercase_characters
  require_numbers                = var.require_numbers
  require_uppercase_characters   = var.require_uppercase_characters
  require_symbols                = var.require_symbols
  allow_users_to_change_password = var.allow_users_to_change_password
  hard_expiry                    = var.hard_expiry
  #checkov:skip=CKV_AWS_13:In a module this should be a variable, however the default is set to 12
  password_reuse_prevention = var.password_reuse_prevention
}
