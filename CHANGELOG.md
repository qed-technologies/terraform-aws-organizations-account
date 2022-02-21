# Release Notes

## v2.0.0 2022-02-21

### Breaking Changes

- Update Terraform version to `1.1.0`
- Update AWS provider to `4.0.0`
- Refactor S3 resources to be compatible with v4.0.0 of the AWS provider
- Add `count` meta arguments to all member account resources
- Remove CMK for default EBS full disk encruyption.  Using the Amazon Managed Key is sufficient for now
- Add `org_name` variable to namespace S3 bucket and IAM resources

## v1.4.0 2021-01-25

### Enhancements

- Add account ID and name to outputs
- Rename `account_alias` variable to `account_name`

## v1.3.1 2021-01-02

### Enhancements

- Reduce provisioned R/WCU for DynamoDb state lock table to 1 in order to save money

## v1.3.0 2020-12-24

### New Features

- Support Terraform v0.14.0

### Enhancements

- Protect IAM roles managed by the Organization
- Allow `UpdateAssumeRolePolicy` action for IAM Manager role

## v1.2.1 2020-12-20

### Bug Fixes

- Add required permissions for IAM Manager role to manage: policies, roles and role tags as expected

## v1.2.0 2020-12-20

### Bug Fixes

- Fixed permission boundary length issue by optimising (combining) statements
- Implemented IAM Role module `v2.1.0`

## v1.1.0 2020-11-22

### New Features

- IAM Manager role and permissions boundary policy to provide teams with an entry point to the account

## v1.0.0 2020-11-20

### New Features

- Module creation
