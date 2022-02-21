# The resources in this file initialise the account so it is
# ready to manage Terraform Remote state
locals {
  terraform_state_bucket_name = "${var.org_name}.${aws_organizations_account.account.id}.terraform"
}

data "aws_kms_key" "s3" {
  provider = aws.member
  key_id   = "alias/aws/s3"
}

data "aws_kms_alias" "s3" {
  name = "alias/aws/s3"
}

#----------------------
# Remote state bucket
#----------------------
resource "aws_s3_bucket" "terraform" {
  count    = !var.clean ? 1 : 0
  provider = aws.member

  #checkov:skip=CKV_AWS_18:Access logs not needed yet
  #checkov:skip=CKV_AWS_52:MFA delete not needed yet
  bucket = local.terraform_state_bucket_name
}

resource "aws_s3_bucket_policy" "terraform" {
  count    = !var.clean ? 1 : 0
  provider = aws.member

  bucket = aws_s3_bucket.terraform[count.index].id
  policy = data.aws_iam_policy_document.s3.json
}

resource "aws_s3_bucket_versioning" "terraform" {
  count    = !var.clean ? 1 : 0
  provider = aws.member

  bucket = aws_s3_bucket.terraform[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform" {
  count    = !var.clean ? 1 : 0
  provider = aws.member

  bucket = aws_s3_bucket.terraform[count.index].bucket

  rule {
    id = "retention"

    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform" {
  count    = !var.clean ? 1 : 0
  provider = aws.member

  bucket = aws_s3_bucket.terraform[count.index].bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = "aws/s3"
      sse_algorithm     = "aws:kms"
    }
    # Reduces costs
    # https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-key.html
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform" {
  count    = !var.clean ? 1 : 0
  provider = aws.member

  bucket = aws_s3_bucket.terraform[count.index].id

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
        data.aws_kms_key.s3.arn
      ]
    }
  }
}

#----------------------------
# DynamoDB state lock table
#----------------------------
resource "aws_dynamodb_table" "terraform" {
  count    = !var.clean ? 1 : 0
  provider = aws.member

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

