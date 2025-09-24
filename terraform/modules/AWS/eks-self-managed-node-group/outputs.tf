# EKS Self-Managed Node Group Module Outputs

# Note: Output attributes depend on the specific version of terraform-aws-modules/eks
# These outputs are commented out until we can verify the correct attribute names
// The upstream module does not expose plain id/arn/name on the root output.
// Expose meaningful outputs that exist on this version instead.

output "launch_template_id" {
  description = "ID of the launch template used by the node group"
  value       = module.self_managed_node_group.launch_template_id
}

output "launch_template_arn" {
  description = "ARN of the launch template used by the node group"
  value       = module.self_managed_node_group.launch_template_arn
}

output "autoscaling_group_arn" {
  description = "ARN of the autoscaling group"
  value       = module.self_managed_node_group.autoscaling_group_arn
}

output "autoscaling_group_name" {
  description = "Name of the autoscaling group"
  value       = module.self_managed_node_group.autoscaling_group_name
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by the node group"
  value       = module.self_managed_node_group.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role used by the node group"
  value       = module.self_managed_node_group.iam_role_name
}
