#------------------
# Password policy
#------------------
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

#-------------------
# IAM manager role
#-------------------
resource "aws_iam_role" "this" {
  provider = aws.member
  count    = var.create_iam_manager_role ? 1 : 0

  name        = "IamManager"
  description = "Deployed by the Organization to manage IAM resource in this account"

  assume_role_policy   = data.aws_iam_policy_document.iam_mangaer_trust.json
  permissions_boundary = aws_iam_policy.permissions_boundary[count.index].arn

  tags = var.tags
}

# Trust policy
data "aws_iam_policy_document" "iam_mangaer_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.iam_manager_trusted_identities
    }

    actions = ["sts:AssumeRole"]
  }
}

# Managed policy
resource "aws_iam_policy" "customer" {
  provider = aws.member
  count    = var.create_iam_manager_role ? 1 : 0

  name        = "IamManager"
  description = "Allows management of IAM entities in this account"
  policy      = data.aws_iam_policy_document.iam_manager.json
}

resource "aws_iam_role_policy_attachment" "customer" {
  provider = aws.member
  count    = var.create_iam_manager_role ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = aws_iam_policy.customer[count.index].arn
}

data "aws_iam_policy_document" "iam_manager" {
  statement {
    sid    = "PreventBoundaryUpdates"
    effect = "Deny"

    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]

    resources = ["arn:aws:iam::${aws_organizations_account.account.id}:policy/OrgBoundary"]
  }

  statement {
    sid    = "EnforceIamBoundary"
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
      values   = ["arn:aws:iam::${aws_organizations_account.account.id}:policy/OrgBoundary"]
    }
  }

  statement {
    sid    = "ManageTerraformStateLock"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]

    resources = [aws_dynamodb_table.terraform.arn]
  }

  statement {
    sid    = "ProtectTerraformStateLockTable"
    effect = "Deny"

    actions = [
      "dynamodb:DeleteTable"
    ]

    resources = [aws_dynamodb_table.terraform.arn]
  }

  statement {
    sid    = "ReadTerraformStateBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [aws_s3_bucket.terraform.arn]
  }

  statement {
    sid    = "ReadTerraformState"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = ["${aws_s3_bucket.terraform.arn}/*"]
  }

  statement {
    sid    = "ProtectTerraformStateBucket"
    effect = "Deny"

    actions = [
      "s3:DeleteBucket",
      "s3:PutBucketVersioning"
    ]

    resources = [aws_s3_bucket.terraform.arn]
  }

  statement {
    sid    = "ProtectTerraformState"
    effect = "Allow"

    actions = [
      "s3:DeleteObject"
    ]

    resources = ["${aws_s3_bucket.terraform.arn}/*"]
  }
}


# -----------------------------------------------
# Permissions boundary policy
# Prevents the IamManager role from 
# being able to create aditional IAM entities 
# without the permissions boundary attached
# -----------------------------------------------
resource "aws_iam_policy" "permissions_boundary" {
  provider = aws.member
  count    = var.create_iam_manager_role ? 1 : 0

  name        = "OrgBoundary"
  path        = "/"
  description = "Organization permissions boundary"
  policy      = data.aws_iam_policy_document.permissions_boundary.json
}

data "aws_iam_policy_document" "permissions_boundary" {
  source_json = var.permissions_boundary_policy

  statement {
    sid    = "PreventBoundaryUpdates"
    effect = "Deny"

    actions = [
      "iam:CreatePolicyVersion",
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]

    resources = ["arn:aws:iam::${aws_organizations_account.account.id}:policy/OrgBoundary"]
  }

  statement {
    sid    = "EnforceIamBoundary"
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
      values   = ["arn:aws:iam::${aws_organizations_account.account.id}:policy/OrgBoundary"]
    }
  }

  statement {
    sid    = "ManageTerraformStateLock"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]

    resources = [aws_dynamodb_table.terraform.arn]
  }

  statement {
    sid    = "ProtectTerraformStateLockTable"
    effect = "Deny"

    actions = [
      "dynamodb:DeleteTable"
    ]

    resources = [aws_dynamodb_table.terraform.arn]
  }

  statement {
    sid    = "ReadTerraformStateBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [aws_s3_bucket.terraform.arn]
  }

  statement {
    sid    = "ReadTerraformState"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = ["${aws_s3_bucket.terraform.arn}/*"]
  }

  statement {
    sid    = "ProtectTerraformStateBucket"
    effect = "Deny"

    actions = [
      "s3:DeleteBucket",
      "s3:PutBucketVersioning"
    ]

    resources = [aws_s3_bucket.terraform.arn]
  }

  statement {
    sid    = "ProtectTerraformState"
    effect = "Allow"

    actions = [
      "s3:DeleteObject"
    ]

    resources = ["${aws_s3_bucket.terraform.arn}/*"]
  }
}
