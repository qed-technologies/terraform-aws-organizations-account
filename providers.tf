provider "aws" {
  alias = "master"
}

provider "aws" {
  alias = "member"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.account.id}:role/${var.role_name}"
  }
}
