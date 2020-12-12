variable "master_account_id" {
  description = "The ID of the master account"
  type        = string
}

variable "region" {
  type        = string
  description = "(required) AWS region where resources will be deployed"
}

variable "tags" {
  description = "Key-value mapping of resource tags to apply to all resources in this module."
  type        = map(string)
  default     = {}
}

#----------
# Account
#----------
variable "account_alias" {
  description = "(Required) The account alias"
  type        = string
}

variable "budget_emails" {
  description = "E-Mail addresses to notify for billing alerts."
  type        = list(string)
}

variable "budget_limit_amount" {
  description = "The amount of cost or usage being measured for a budget."
  type        = string
}

variable "email_owner" {
  description = "The email address of the owner to assign to the new member account. This email address must not already be associated with another AWS account."
  type        = string
}

variable "iam_user_access_to_billing" {
  description = "If set to ALLOW, the new account enables IAM users to access account billing information if they have the required permissions. If set to DENY, then only the root user of the new account can access account billing information."
  type        = string
  default     = "ALLOW"
}

variable "organizational_unit_id" {
  description = "Parent Organizational Unit ID for the account."
  type        = string
}

variable "role_name" {
  description = "The name of an IAM role that Organizations automatically preconfigures in the new member account. This role trusts the master account, allowing users in the master account to assume the role, as permitted by the master account administrator. The role has administrator permissions in the new member account."
  type        = string
}

variable "tags_account" {
  description = "Key-value mapping of resource tags to apply to the member account."
  type        = map(string)
  default     = {}
}

#---------
# iam.tf
#---------
# Password policy
variable "allow_users_to_change_password" {
  description = "Whether to allow users to change their own password"
  type        = bool
  default     = true
}

variable "hard_expiry" {
  description = "Whether users are prevented from setting a new password after their password has expired (i.e. require administrator reset)"
  type        = bool
  default     = false
}

variable "max_password_age" {
  description = "The number of days that an user password is valid"
  type        = number
  default     = 90
}

variable "minimum_password_length" {
  description = "Minimum length to require for user passwords"
  type        = number
  default     = 16
}

variable "password_reuse_prevention" {
  description = "The number of previous passwords that users are prevented from reusing"
  type        = number
  default     = 12
}

variable "require_lowercase_characters" {
  description = "Whether to require lowercase characters for user passwords"
  type        = bool
  default     = true
}

variable "require_numbers" {
  description = "Whether to require numbers for user passwords"
  type        = bool
  default     = true
}

variable "require_uppercase_characters" {
  description = "Whether to require uppercase characters for user passwords"
  type        = bool
  default     = true
}

variable "require_symbols" {
  description = "Whether to require symbols for user passwords"
  type        = bool
  default     = true
}

# IAM Manager Role
variable "create_iam_manager_role" {
  description = "(optional) controls creation of an IAM role used to administer IAM entities in the account"
  type        = bool
  default     = true
}

variable "iam_namespace" {
  description = "(optional) Namespace to categorise the IAM entities created by this module under"
  type        = string
  default     = "org"
}

variable "iam_manager_trusted_identities" {
  description = "(optional) a list of identities trusted to assume the IAM Manager role"
  type        = list(string)
  default     = []
}

variable "permitted_services" {
  description = "(required) a list of services this account is permitted to access"
  type        = list(string)
}

#-----------
# Security
#-----------
# Public Access Block
variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for buckets in this account"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for buckets in this account"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for buckets in this account"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for buckets in this account"
  type        = bool
  default     = true
}

# EBS Default Encryption
variable "ebs_default_kms_key_arn" {
  description = "ARN of the KMS CMK to be used for ebs encryption by default"
  type        = string
  default     = ""
}
