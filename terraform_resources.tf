# The resources in this file initialise the account so it is
# ready to manage Terraform Remote state

locals {
  terraform_state_bucket_name = "${aws_organizations_account.account.id}-terraform"
}

#----------------------
# Remote state bucket
#----------------------
resource "aws_s3_bucket" "terraform" {
  provider = aws.member
  count    = var.create ? 1 : 0

  #checkov:skip=CKV_AWS_18:Access logs not needed yet
  #checkov:skip=CKV_AWS_52:MFA delete not needed yet
  bucket = local.terraform_state_bucket_name
  policy = data.aws_iam_policy_document.s3.json
  
  
  force_destroy = !var.create && var.force_destroy ? true : false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true

    noncurrent_version_expiration {
      days = 90
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.terraform.arn
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform" {
  provider = aws.member
  count    = var.create ? 1 : 0

  bucket = aws_s3_bucket.terraform.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#-----------------------------
# Remote state bucket policy
#-----------------------------
data "aws_iam_policy_document" "s3" {
  statement {
    sid = "ManageTerraformState"

    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = ["arn:aws:s3:::${local.terraform_state_bucket_name}/*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${aws_organizations_account.account.id}:root"]
    }
  }

  statement {
    sid = "ReadStateObjects"

    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${local.terraform_state_bucket_name}",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${aws_organizations_account.account.id}:root"]
    }
  }

  statement {
    sid = "PrevenHttpRequests"

    effect = "Deny"

    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::${local.terraform_state_bucket_name}",
      "arn:aws:s3:::${local.terraform_state_bucket_name}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }

  statement {
    sid = "DenyIncorrectEncryptionHeader"

    effect = "Deny"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${local.terraform_state_bucket_name}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values = [
        "aws:kms"
      ]
    }
  }

  statement {
    sid = "DenyEncryptionWithIncorrectKey"

    effect = "Deny"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${local.terraform_state_bucket_name}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotLikeIfExists"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"

      values = [
        aws_kms_key.terraform[0].arn
      ]
    }
  }
}

#----------------------------
# DynamoDB state lock table
#----------------------------
resource "aws_dynamodb_table" "terraform" {
  provider = aws.member
  count    = var.create ? 1 : 0

  #checkov:skip=CKV_AWS_28:State table doesn't need backup enable
  name           = "terraform_state_lock"
  hash_key       = "LockID"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "LockID"
    type = "S"
  }
}

#----------
# KMS CMK
#----------
resource "aws_kms_key" "terraform" {
  provider = aws.member
  count    = var.create ? 1 : 0

  description         = "Terraform State Key"
  policy              = data.aws_iam_policy_document.kms.json
  enable_key_rotation = true
}

resource "aws_kms_alias" "terraform" {
  provider = aws.member
  count    = var.create ? 1 : 0

  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.terraform[0].key_id
}

data "aws_iam_policy_document" "kms" {
  statement {
    sid = "Allow access for Key Administrators"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${aws_organizations_account.account.id}:root"]
    }

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    resources = ["*"]
  }

  statement {
    sid = "Allow use of the key"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${aws_organizations_account.account.id}:root"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}
