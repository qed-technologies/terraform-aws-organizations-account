# Terraform AWS Module: Organizations Member Account

[![Latest release](https://img.shields.io/github/v/release/qed-technologies/terraform-aws-organizations-account)](https://github.com/qed-technologies/terraform-aws-organizations-account/releases)

AWS Terraform module for managing AWS Organization member accounts

## Implementation

See `/test/test.tf` for the suggested module implementation

## Providers

This module requires 2 provider blocks to be passed:

1. To control resource provisioning in the AWS Master Account
2. To control resource provisioning in the AWS Member Account

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0, < 0.15 |
| aws | >= 2.68, < 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.68, < 4.0 |
| aws.master | >= 2.68, < 4.0 |
| aws.member | >= 2.68, < 4.0 |
| null | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| account\_alias | (Required) The account alias | `string` | n/a | yes |
| allow\_users\_to\_change\_password | Whether to allow users to change their own password | `bool` | `true` | no |
| block\_public\_acls | Whether Amazon S3 should block public ACLs for buckets in this account | `bool` | `true` | no |
| block\_public\_policy | Whether Amazon S3 should block public bucket policies for buckets in this account | `bool` | `true` | no |
| budget\_emails | E-Mail addresses to notify for billing alerts. | `list(string)` | n/a | yes |
| budget\_limit\_amount | The amount of cost or usage being measured for a budget. | `string` | n/a | yes |
| create\_iam\_manager\_role | (optional) controls creation of an IAM role used to administer IAM entities in the account | `bool` | `true` | no |
| ebs\_default\_kms\_key\_arn | ARN of the KMS CMK to be used for ebs encryption by default | `string` | `""` | no |
| email\_owner | The email address of the owner to assign to the new member account. This email address must not already be associated with another AWS account. | `string` | n/a | yes |
| hard\_expiry | Whether users are prevented from setting a new password after their password has expired (i.e. require administrator reset) | `bool` | `false` | no |
| iam\_manager\_trusted\_identities | (optional) a list of identities trusted to assume the IAM Manager role | `list(string)` | `[]` | no |
| iam\_namespace | (optional) Namespace to categorise the IAM entities created by this module under | `string` | `"org"` | no |
| iam\_user\_access\_to\_billing | If set to ALLOW, the new account enables IAM users to access account billing information if they have the required permissions. If set to DENY, then only the root user of the new account can access account billing information. | `string` | `"ALLOW"` | no |
| ignore\_public\_acls | Whether Amazon S3 should ignore public ACLs for buckets in this account | `bool` | `true` | no |
| master\_account\_id | The ID of the master account | `string` | n/a | yes |
| max\_password\_age | The number of days that an user password is valid | `number` | `90` | no |
| minimum\_password\_length | Minimum length to require for user passwords | `number` | `16` | no |
| organizational\_unit\_id | Parent Organizational Unit ID for the account. | `string` | n/a | yes |
| password\_reuse\_prevention | The number of previous passwords that users are prevented from reusing | `number` | `12` | no |
| permitted\_services | (required) a list of services this account is permitted to access | `list(string)` | n/a | yes |
| region | (required) AWS region where resources will be deployed | `string` | n/a | yes |
| require\_lowercase\_characters | Whether to require lowercase characters for user passwords | `bool` | `true` | no |
| require\_numbers | Whether to require numbers for user passwords | `bool` | `true` | no |
| require\_symbols | Whether to require symbols for user passwords | `bool` | `true` | no |
| require\_uppercase\_characters | Whether to require uppercase characters for user passwords | `bool` | `true` | no |
| restrict\_public\_buckets | Whether Amazon S3 should restrict public bucket policies for buckets in this account | `bool` | `true` | no |
| role\_name | The name of an IAM role that Organizations automatically preconfigures in the new member account. This role trusts the master account, allowing users in the master account to assume the role, as permitted by the master account administrator. The role has administrator permissions in the new member account. | `string` | n/a | yes |
| tags | Key-value mapping of resource tags to apply to all resources in this module. | `map(string)` | `{}` | no |
| tags\_account | Key-value mapping of resource tags to apply to the member account. | `map(string)` | `{}` | no |

## Outputs

No output.
