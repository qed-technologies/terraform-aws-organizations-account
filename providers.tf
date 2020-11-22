provider "aws" {
  alias  = "master"
  region = var.region
}

provider "aws" {
  alias  = "member"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.account.id}:role/${var.role_name}"
  }
}
