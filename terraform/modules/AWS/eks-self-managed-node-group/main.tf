terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


################################################################################
# EKS Self-Managed Node Group Module
################################################################################

# Local values for consistent tagging
locals {
  common_tags = merge(var.common_tags, {
    Component   = "eks-node-group"
    ServiceType = "compute"
  })
}

# Self-Managed Node Group
module "self_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/self-managed-node-group"
  version = "20.36"  

  name                = var.node_group_name
  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  cluster_endpoint    = var.cluster_endpoint
  cluster_auth_base64 = var.cluster_certificate_authority_data
  cluster_service_cidr = var.cluster_service_cidr
  cluster_primary_security_group_id = var.cluster_primary_security_group_id
  subnet_ids = var.subnet_ids

  vpc_security_group_ids = var.vpc_security_group_ids

  iam_role_arn = var.iam_role_arn

  launch_template_name = var.launch_template_name

  # Scaling configuration
  min_size     = var.min_size
  max_size     = var.max_size
  desired_size = var.desired_size

  # Instance configuration
  instance_type = var.instance_type
  # instance_types = var.instance_types  # Not supported in all versions

  # Storage configuration
  block_device_mappings = var.block_device_mappings

  # Node configuration - Note: These may not be supported in all versions
  # node_labels = var.node_labels
  # node_taints = var.node_taints
  bootstrap_extra_args = var.bootstrap_extra_args

  # Mixed instances policy
  use_mixed_instances_policy = var.use_mixed_instances_policy
  mixed_instances_policy = var.mixed_instances_policy

  # User data - Note: These may not be supported in all versions
  # user_data = var.user_data
  # user_data_base64 = var.user_data_base64

  tags = merge(local.common_tags, var.node_group_tags, {
    Name = "${var.cluster_name}-${var.node_group_name}-ng"
  })
}