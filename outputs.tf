output "arn" {
  value = module.iam_role_iam_manager.arn
}

output "name" {
  value = module.iam_role_iam_manager.name
}

output "instance_profile_arn" {
  value = module.iam_role_iam_manager.instance_profile_arn
}

output "instance_profile_name" {
  value = module.iam_role_iam_manager.instance_profile_name
}
