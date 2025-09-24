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
# EKS Module
################################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  create_cluster_primary_security_group_tags = var.create_cluster_primary_security_group_tags

  # Cluster endpoint configuration
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  # Cluster encryption
  cluster_encryption_config = var.cluster_encryption_config

  # Cluster logging
  cluster_enabled_log_types = var.cluster_enabled_log_types

  node_security_group_tags = var.node_security_group_tags

  # EKS Addons
  cluster_addons = var.cluster_addons

  # IRSA (IAM Roles for Service Accounts)
  enable_irsa = var.enable_irsa

  tags = merge(var.common_tags, var.cluster_tags, {
    Name = var.cluster_name
  })
}