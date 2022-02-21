resource "aws_s3_account_public_access_block" "this" {
  count    = var.block_s3_public_access ? 1 : 0
  provider = aws.member

  account_id              = aws_organizations_account.account.id
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets

  depends_on = [null_resource.account_delay]
}

# Full Disk Encryption (FDE) on EBS volumes must be enabled by default.
# Ideally, the encryption will be performed by a KMS CMK.  However,
# there will be ocassions when the Amazon Managed Keys need to be used
# i.e. third party software doesn't support encryption with CMKs

# Enable FDE by default
data "aws_kms_key" "ebs" {
  provider = aws.member
  key_id   = "alias/aws/ebs"
}

resource "aws_ebs_encryption_by_default" "this" {
  count    = var.enable_default_ebs_encryption ? 1 : 0
  provider = aws.member

  enabled = true

  depends_on = [null_resource.account_delay]
}

# Then if we have a KMS CMK defined then use that
resource "aws_ebs_default_kms_key" "this" {
  count    = var.enable_default_ebs_encryption ? 0 : 1
  provider = aws.member

  key_arn = data.aws_kms_key.ebs.arn

  depends_on = [null_resource.account_delay]
}
