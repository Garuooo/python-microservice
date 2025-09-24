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
# Karpenter Module
################################################################################

# Local values for consistent tagging
locals {
  common_tags = merge(var.common_tags, {
    Component   = "karpenter"
    ServiceType = "compute"
  })
}

# Ensure EC2 Spot service-linked role exists
resource "aws_iam_service_linked_role" "spot" {
  count = var.enable_karpenter ? 1 : 0
  
  aws_service_name = "spot.amazonaws.com"
  description      = "Service-linked role for EC2 Spot instances used by Karpenter"

  # This will only create if it doesn't exist, won't fail if it already exists
  lifecycle {
    ignore_changes = [
      description,
      aws_service_name
    ]
  }

  tags = merge(local.common_tags, {
    Name        = "${var.cluster_name}-spot-service-linked-role"
    Purpose     = "ec2-spot-instances"
  })
}

module "karpenter" {
  count = var.enable_karpenter ? 1 : 0
  
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.36"

  cluster_name          = var.cluster_name
  enable_v1_permissions = var.enable_v1_permissions  # Not supported in all versions

  # IRSA Configuration - Note: These may not be supported in all versions
  enable_irsa                     = var.enable_irsa
  irsa_oidc_provider_arn         = var.oidc_provider_arn
  irsa_namespace_service_accounts = var.irsa_namespace_service_accounts

  # Pod Identity
  create_pod_identity_association = var.create_pod_identity_association
  
  # Node IAM role configuration
  node_iam_role_use_name_prefix = var.node_iam_role_use_name_prefix

  # Additional IAM policies for Karpenter node IAM role
  node_iam_role_additional_policies = var.node_iam_role_additional_policies

  tags = local.common_tags
}

# resource "helm_release" "karpenter" {
  # namespace           = "kube-system"
  # name                = "karpenter"
  # repository          = "oci://public.ecr.aws/karpenter"
  # chart               = "karpenter"
  # version             = "1.5.0"
  # wait                = false
# 
  # values = [
    # <<-EOT
    # nodeSelector:
      # karpenter.sh/controller: 'true'
    # dnsPolicy: Default
    # serviceAccount:
      # annotations:
        # eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    # settings:
      # clusterName: ${module.eks.cluster_name}
      # clusterEndpoint: ${module.eks.cluster_endpoint}
      # interruptionQueue: ${module.karpenter.queue_name}
    # webhook:
      # enabled: false
    # EOT
  # ]
# 
  # depends_on = [module.karpenter]
# }
