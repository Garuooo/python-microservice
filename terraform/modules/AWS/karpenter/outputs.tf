# Karpenter Module Outputs

output "karpenter_iam_role_arn" {
  description = "ARN of the Karpenter IAM role"
  value       = var.enable_karpenter ? module.karpenter[0].iam_role_arn : null
}

output "karpenter_iam_role_name" {
  description = "Name of the Karpenter IAM role"
  value       = var.enable_karpenter ? module.karpenter[0].iam_role_name : null
}

output "karpenter_queue_name" {
  description = "Name of the Karpenter queue"
  value       = var.enable_karpenter ? module.karpenter[0].queue_name : null
}

output "karpenter_queue_arn" {
  description = "ARN of the Karpenter queue"
  value       = var.enable_karpenter ? module.karpenter[0].queue_arn : null
}

