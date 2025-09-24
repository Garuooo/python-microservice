# KMS Module Outputs

output "key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.main.key_id
}

output "key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "key_description" {
  description = "Description of the KMS key"
  value       = aws_kms_key.main.description
}

output "key_usage" {
  description = "Usage of the KMS key"
  value       = aws_kms_key.main.key_usage
}

# Note: This output depends on the AWS provider version and KMS key configuration
# output "key_spec" {
#   description = "Specification of the KMS key"
#   value       = aws_kms_key.main.customer_master_key_spec
# }

output "multi_region" {
  description = "Whether the KMS key is multi-region"
  value       = aws_kms_key.main.multi_region
}

output "key_policy" {
  description = "Policy of the KMS key"
  value       = aws_kms_key.main.policy
}

output "alias_name" {
  description = "Name of the KMS key alias"
  value       = var.create_alias ? aws_kms_alias.main[0].name : null
}

output "alias_arn" {
  description = "ARN of the KMS key alias"
  value       = var.create_alias ? aws_kms_alias.main[0].arn : null
}

output "alias_target_key_id" {
  description = "Target key ID of the KMS key alias"
  value       = var.create_alias ? aws_kms_alias.main[0].target_key_id : null
}
