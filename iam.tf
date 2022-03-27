locals {
  # Multi-step process to ensure path is prefixed and 
  # suffixed with a "/"
  iam_namespace_first_check = substr(var.org_name, 0, 1) != "/" ? "/${var.org_name}" : var.org_name
  iam_namespace_final       = substr(local.iam_namespace_first_check, length(local.iam_namespace_first_check) - 1, 1) != "/" ? "${local.iam_namespace_first_check}/" : local.iam_namespace_first_check
  # These service permissions are added to the 
  # permissions boundary policy
  permitted_service_actions = [for service in var.permitted_services : "${service}:*"]
  # Required to allow specific Service Linked Roles
  # to be created
  permitted_service_names = [for service in var.permitted_services : "${service}.amazonaws.com"]
}

#------------------
# Password policy
#------------------
resource "aws_iam_account_password_policy" "this" {
  count    = !var.clean ? 1 : 0
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

#-------------------
# IAM manager role
#-------------------
module "iam_role_iam_manager" {
  source = "github.com/qed-technologies/terraform-aws-iam-role?ref=v3.0.0"

  providers = {
    aws = aws.member
  }

  create = var.create_iam_manager_role

  name        = "IamManager"
  description = "Deployed by the Organization to manage IAM resource in this account"
  path        = local.iam_namespace_final

  trusted_identities = var.iam_manager_trusted_identities

  managed_policy_arns = [
    concat(aws_iam_policy.iam_manager.*.arn, [""])[0],
    concat(aws_iam_policy.terraform_state_write.*.arn, [""])[0]
  ]

  tags = var.tags
}

# --------------------
# IAM Manager policy
# --------------------
resource "aws_iam_policy" "iam_manager" {
  count    = var.create_iam_manager_role ? 1 : 0
  provider = aws.member

  name        = "IamManager"
  description = "Allows management of IAM entities in this account"
  path        = local.iam_namespace_final
  policy      = data.aws_iam_policy_document.iam_manager.json
}

data "aws_iam_policy_document" "iam_manager" {
  statement {
    sid = "ManageIamPolicies"

    effect = "Allow"

    actions = [
      "iam:CreatePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:Get*",
      "iam:List*",
    ]

    resources = [
      "arn:aws:iam::${aws_organizations_account.account.id}:policy/*"
    ]
  }

  statement {
    sid = "ManageIamRoles"

    effect = "Allow"

    actions = [
      "iam:AttachRolePolicy",
      "iam:DeleteRole",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:UpdateAssumeRolePolicy",
      "iam:UpdateRole",
      "iam:UpdateRoleDescription",
      "iam:Get*",
      "iam:List*",
      "iam:TagRole",
      "iam:UntagRole"
    ]

    resources = [
      "arn:aws:iam::${aws_organizations_account.account.id}:role/*"
    ]
  }
}

# -----------------------------------------------
# Terraform state policy
# Can be attached to roles in the account to 
# allow IAM entities to write Terraform State
# -----------------------------------------------
resource "aws_iam_policy" "terraform_state_write" {
  count    = var.create_iam_manager_role ? 1 : 0
  provider = aws.member

  name        = "TerraformStateWrite"
  path        = local.iam_namespace_final
  description = "Permissions required to write Terraform STate"
  policy      = data.aws_iam_policy_document.terraform_state_write.json
}

data "aws_iam_policy_document" "terraform_state_write" {
  statement {
    sid = "ManageTerraformStateLock"

    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]

    resources = [
      aws_dynamodb_table.terraform[0].arn
    ]
  }

  statement {
    sid = "ReadTerraformStateBucket"

    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.terraform[0].arn
    ]
  }

  statement {
    sid = "ReadTerraformState"

    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.terraform[0].arn}/*"
    ]
  }

  statement {
    sid = "AllowStateCmkUse"

    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = [
      data.aws_kms_key.s3.arn
    ]
  }
}
