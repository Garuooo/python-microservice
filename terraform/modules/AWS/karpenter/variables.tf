# Karpenter Module Variables

# Required Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC Provider"
  type        = string
}

# Optional Variables
variable "enable_karpenter" {
  description = "Whether to enable Karpenter"
  type        = bool
  default     = true
}

variable "enable_v1_permissions" {
  description = "Whether to enable v1 permissions for Karpenter"
  type        = bool
  default     = true
}

variable "enable_irsa" {
  description = "Whether to enable IRSA for Karpenter"
  type        = bool
  default     = true
}

variable "irsa_namespace_service_accounts" {
  description = "List of namespace/service account combinations for IRSA"
  type        = list(string)
  default     = ["kube-system:karpenter"]
}

variable "create_pod_identity_association" {
  description = "Whether to create pod identity association"
  type        = bool
  default     = false
}

variable "node_iam_role_use_name_prefix" {
  description = "Whether to use name prefix for node IAM role"
  type        = bool
  default     = false
}

variable "node_iam_role_additional_policies" {
  description = "Additional IAM policies to attach to the Karpenter node IAM role"
  type        = map(string)
  default = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

variable "common_tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)
  default     = {}
}