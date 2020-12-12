# Constructing providers at runtime using data is not supported
# in Terraform yet.  There is an open issue for this
# https://github.com/hashicorp/terraform/issues/24476
# Until this is resolved for_each can't be used with this module 
module "account_example-account_dev" {
  source    = "../"

  region                  = "us-east-1"
  master_account_id       = "01234567891"
  account_alias           = "account-1"
  email_owner             = "example-account_dev@example.com"
  organizational_unit_id  = "ou-1234-12345678"
  role_name               = "OrgDeploy"
  ebs_default_kms_key_arn = "arn:aws:kms:eu-west-2:123456789012:key/123"

  budget_limit_amount = "1000.0"
  budget_emails = [
    "user1@example.com",
    "user2@example.com",
  ]

  iam_namespace = "my-org"

  permitted_services = [
    "dynamodb",
    "s3"
  ]

  iam_manager_trusted_identities = [
    "arn:aws:iam::123456789012:/role/sso"
  ]

  tags = {
    key = "value"
  }

  tags_account = {
    account_owner = "another.owner@example.com"
  }
}
