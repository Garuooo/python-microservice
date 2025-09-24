# EKS Self-Managed Node Group Module Variables

# Required Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
}

variable "cluster_service_cidr" {
  description = "The CIDR block that Kubernetes service IP addresses are assigned from"
  type        = string
}

variable "cluster_primary_security_group_id" {
  description = "The cluster primary security group ID created by EKS"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the node group will be deployed"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs to attach to the node group"
  type        = list(string)
}

variable "iam_role_arn" {
  description = "ARN of the IAM role for the node group"
  type        = string
}

# Node Group Configuration
variable "node_group_name" {
  description = "Name of the node group"
  type        = string
  default     = "self-managed"
}

variable "cluster_version" {
  description = "Kubernetes version for the node group"
  type        = string
  default     = "1.28"
}

variable "launch_template_name" {
  description = "Name of the launch template for the node group"
  type        = string
  default     = "self-managed-nodes"
}

# Scaling Configuration
variable "min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 3
}

variable "desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 1
}

# Instance Configuration
variable "instance_type" {
  description = "Instance type for the node group"
  type        = string
  default     = "t3.medium"
}

# Storage Configuration
variable "block_device_mappings" {
  description = "List of block device mappings for the node group"
  type = list(object({
    device_name = string
    ebs = object({
      volume_size = number
      volume_type = string
      encrypted   = optional(bool)
      kms_key_id  = optional(string)
    })
  }))
  default = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size = 20
        volume_type = "gp3"
        encrypted   = true
      }
    }
  ]
}

variable "bootstrap_extra_args" {
  description = "Extra arguments to pass to the bootstrap script"
  type        = string
  default     = ""
}

# Mixed Instances Policy
variable "use_mixed_instances_policy" {
  description = "Whether to use mixed instances policy"
  type        = bool
  default     = false
}

variable "mixed_instances_policy" {
  description = "Mixed instances policy configuration"
  type = object({
    instances_distribution = object({
      on_demand_base_capacity                  = number
      on_demand_percentage_above_base_capacity = number
      spot_allocation_strategy                 = string
    })
    launch_template = object({
      override = list(object({
        instance_type     = string
        weighted_capacity = string
      }))
    })
  })
  default = null
}

# Tags
variable "common_tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "node_group_tags" {
  description = "A map of additional tags to apply to the node group"
  type        = map(string)
  default     = {}
}