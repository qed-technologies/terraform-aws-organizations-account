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

  trusted_identities       = var.iam_manager_trusted_identities
  permissions_boundary_arn = concat(aws_iam_policy.permissions_boundary.*.arn, [""])[0]

  managed_policy_arns = concat([
    aws_iam_policy.iam_manager[0].arn,
    aws_iam_policy.terraform_state_write[0].arn,
    concat(aws_iam_policy.force_boundary_usage.*.arn, [""])[0]
  ])

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
      "iam:DeleteRole",
      "iam:Get*",
      "iam:List*",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy"
    ]

    resources = [
      "arn:aws:iam::${aws_organizations_account.account.id}:role/*"
    ]
  }
}

resource "aws_iam_policy" "force_boundary_usage" {
  count    = var.create_iam_manager_role && var.use_permissions_boundary ? 1 : 0
  provider = aws.member

  name        = "ForceBoundaryUsage"
  path        = local.iam_namespace_final
  description = "Ensures all IAM roles use the Permissions Boundary"
  policy      = concat(data.aws_iam_policy_document.force_boundary_usage.*.json, [""])[0]
}

data "aws_iam_policy_document" "force_boundary_usage" {
  count = var.create_iam_manager_role && var.use_permissions_boundary ? 1 : 0

  statement {
    sid = "EnforceIamBoundary"

    effect = "Allow"

    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:PutRolePolicy"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = ["arn:aws:iam::${aws_organizations_account.account.id}:policy/${var.org_name}/OrgBoundary"]
    }
  }
}

# -----------------------------
# Permissions boundary policy
# 
# -----------------------------
resource "aws_iam_policy" "permissions_boundary" {
  count    = var.create_iam_manager_role ? 1 : 0
  provider = aws.member

  name        = "OrgBoundary"
  path        = local.iam_namespace_final
  description = "Organization permissions boundary"
  policy      = data.aws_iam_policy_document.permissions_boundary.json
}

data "aws_iam_policy_document" "permissions_boundary" {
  statement {
    sid = "PreventBoundaryRemoval"

    effect = "Deny"

    actions = [
      "iam:DeleteRolePermissionsBoundary"
    ]

    resources = [
      "arn:aws:iam::${aws_organizations_account.account.id}:role/*"
    ]
  }

  statement {
    sid = "PreventOrgManagedResourceUpdates"

    effect = "Deny"

    actions = [
      # Policies
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      # Roles
      "iam:UpdateAssumeRolePolicy",
      # Terraform State
      "dynamodb:DeleteTable",
      "s3:DeleteBucket",
      "s3:DeleteObject",
      "s3:PutBucketVersioning",
      # Terraform State Encryption
      "kms:CancelKeyDeletion",
      "kms:DeleteAlias",
      "kms:DisableKey",
      "kms:DisableKeyRotation",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:PutKeyPolicy",
      "kms:ScheduleKeyDeletion",
      "kms:UntagResource",
      "kms:UpdateAlias"
    ]

    resources = [
      # Policies
      "arn:aws:iam::${aws_organizations_account.account.id}:policy/${var.org_name}/OrgBoundary",
      # Roles
      "arn:aws:iam::${aws_organizations_account.account.id}:role/${var.org_name}/IamManager",
      # Terraform State
      aws_dynamodb_table.terraform[0].arn,
      aws_s3_bucket.terraform[0].arn,
      "${aws_s3_bucket.terraform[0].arn}/*",
      # Terraform State Encryption
      data.aws_kms_key.s3.arn,
      data.aws_kms_alias.s3.arn
    ]
  }

  statement {
    sid    = "ManageTerraformRemoteState"
    effect = "Allow"

    actions = [
      # State Lock
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      # State File
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      # State Encryption
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = [
      # State Lock
      aws_dynamodb_table.terraform[0].arn,
      # State File
      aws_s3_bucket.terraform[0].arn,
      "${aws_s3_bucket.terraform[0].arn}/*",
      # State Encryption
      data.aws_kms_key.s3.arn
    ]
  }

  statement {
    sid = "EnforceIamBoundary"

    effect = "Allow"

    actions = [
      "iam:AttachRolePolicy",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePermissionsBoundary",
      "iam:PutRolePolicy"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values = [
        "arn:aws:iam::${aws_organizations_account.account.id}:policy/${var.org_name}/*"
      ]
    }
  }

  statement {
    sid = "AllowIamManagement"

    effect = "Allow"

    #checkov:skip=CKV_AWS_49:Wildcards on read-only actions are acceptable
    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:Get*",
      "iam:List*",
      "iam:RemoveRoleFromInstanceProfile"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "ManageServiceLinkedRoles"

    effect = "Allow"

    actions = [
      "iam:ServiceLinkedRole*"
    ]

    resources = [
      "arn:aws:iam::${aws_organizations_account.account.id}:role/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = local.permitted_service_names
    }
  }

  statement {
    sid = "AllowedServices"

    effect = "Allow"

    #checkov:skip=CKV_AWS_1:False positive this doesn't allow full admin
    actions = local.permitted_service_actions

    resources = [
      "*"
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
