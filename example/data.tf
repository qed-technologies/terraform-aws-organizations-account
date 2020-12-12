data "aws_iam_policy_document" "MyPermissionsBoundary" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}
