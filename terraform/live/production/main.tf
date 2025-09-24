# Local values for consistent tagging
locals {
  common_tags = {
    Project     = "microservice"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "../../modules/AWS/vpc"

  vpc_name = "${var.vpc_name}-vpc"
  vpc_cidr = var.vpc_cidr

  availability_zones = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  single_nat_gateway = var.single_nat_gateway
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Enable VPC Flow Logs
  enable_flow_log                      = var.enable_flow_logs
  create_flow_log_cloudwatch_iam_role  = var.enable_flow_logs
  create_flow_log_cloudwatch_log_group = var.enable_flow_logs
  flow_log_destination_type            = "cloud-watch-logs"
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_retention_days

  # Subnet tagging for EKS
  public_subnet_tags = merge(var.public_subnet_tags, {
    "kubernetes.io/role/elb" = "1"
    Type                     = "Public"
  })

  private_subnet_tags = merge(var.private_subnet_tags, {
    "kubernetes.io/role/internal-elb" = "1"
    Type                              = "Private"
    "karpenter.sh/discovery" = var.cluster_name
  })

  common_tags = local.common_tags
}

################################################################################
# KMS Module for Cluster Encryption
################################################################################

module "kms_cluster" {
  source = "../../modules/AWS/kms"

  key_name = "${var.cluster_name}-eks-encryption"
  description = "EKS Secret Encryption Key for ${var.cluster_name}"

  enable_key_rotation = true
  deletion_window_in_days = 7

  create_alias = true
  alias_name = "alias/${var.cluster_name}-eks"

  common_tags = merge(local.common_tags, {
    Component = "eks-encryption"
  })
}

# ################################################################################
# # EKS Cluster Module
# ################################################################################

module "eks" {
  source = "../../modules/AWS/eks"

  cluster_name = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cluster endpoint configuration
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access_cidrs = var.office_ip_cidrs
  enable_cluster_creator_admin_permissions = true

  # Cluster encryption
  cluster_encryption_config = var.enable_cluster_encryption ? {
    provider_key_arn = module.kms_cluster.key_arn
    resources        = ["secrets"]
  } : null

  # Cluster logging
  cluster_enabled_log_types = var.cluster_enabled_log_types

  # Node security group tags for Karpenter
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  # EKS Addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        daemonset = {
          tolerations = [
            {
              key      = "type"
              operator = "Equal"
              value    = "application-workloads"
              effect   = "NoSchedule"
            },
            {
              key      = "type"
              operator = "Equal"
              value    = "application-workloads"
              effect   = "PreferNoSchedule"
            }
          ]
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.irsa_ebs_csi.iam_role_arn
    }
  }

  # IRSA
  enable_irsa = true

  common_tags = local.common_tags
  cluster_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

################################################################################
# ECR repository for Python microservice
################################################################################

module "ecr_python_service" {
  source = "../../modules/AWS/ecr"

  repository_name       = "python-microservice"
  image_tag_mutability  = "MUTABLE"
  scan_on_push          = true
  encryption_type       = "AES256"
  force_delete          = false
  lifecycle_policy_json = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Keep last 30 images",
      selection    = {
        tagStatus     = "any",
        countType     = "imageCountMoreThan",
        countNumber   = 30
      },
      action = { type = "expire" }
    }]
  })

  tags = merge(local.common_tags, { Component = "ecr" })
}

################################################################################
# EBS CSI Driver IRSA
################################################################################

module "irsa_ebs_csi" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.3"

  role_name             = "${var.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = merge(local.common_tags, {
    Name        = "${var.cluster_name}-ebs-csi-irsa-role"
    Component   = "ebs-csi-driver"
    ServiceType = "storage"
  })
}

# ################################################################################
# # AWS Load Balancer Controller IRSA
# ################################################################################

module "irsa_aws_load_balancer_controller" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.3"

  role_name                              = "${var.cluster_name}-aws-lbc"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-aws-lbc-irsa-role"
  })
}

# ################################################################################
# # Karpenter Module
# ################################################################################

module "karpenter" {
  source = "../../modules/AWS/karpenter"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_karpenter = var.enable_karpenter
  enable_v1_permissions = true
  enable_irsa = true
  irsa_namespace_service_accounts = ["kube-system:karpenter"]

  # Disable Pod Identity
  create_pod_identity_association = false
  
  # Node IAM role configuration
  node_iam_role_use_name_prefix = false

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  common_tags = local.common_tags
}

# ################################################################################
# # Self-Managed Node Groups
# ################################################################################

# IAM Role for Self-Managed Node Groups
resource "aws_iam_role" "self_managed_node_group" {
  name = "${var.cluster_name}-self-managed-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-self-managed-node-group-role"
  })
}

# IAM Role Policy Attachments for Self-Managed Node Groups
resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.self_managed_node_group.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.self_managed_node_group.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.self_managed_node_group.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_ebs_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.self_managed_node_group.name
}

resource "aws_iam_role_policy_attachment" "amazon_cloudwatch_agent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.self_managed_node_group.name
}

################################################################################
# Application Node Group
################################################################################

module "application_node_group" {
  source = "../../modules/AWS/eks-self-managed-node-group"

  cluster_name                        = module.eks.cluster_name
  cluster_endpoint                    = module.eks.cluster_endpoint
  cluster_certificate_authority_data  = module.eks.cluster_certificate_authority_data
  cluster_service_cidr               = module.eks.cluster_service_cidr
  cluster_primary_security_group_id  = module.eks.cluster_primary_security_group_id
  subnet_ids                         = module.vpc.private_subnets
  vpc_security_group_ids             = [module.eks.cluster_primary_security_group_id, module.eks.node_security_group_id]
  iam_role_arn                       = aws_iam_role.self_managed_node_group.arn

  # Node group configuration
  node_group_name = "application"
  cluster_version = var.kubernetes_version
  launch_template_name = "application-nodes"

  # Scaling configuration
  min_size     = var.application_min_size
  max_size     = var.application_max_size
  desired_size = var.application_desired_size

  # Instance configuration
  instance_type = var.application_instance_types[1]

  # Node configuration
  bootstrap_extra_args = "--kubelet-extra-args '--node-labels=type=self-managed,Purpose=application-workloads, --register-with-taints=type=application-workloads:NoSchedule'"

  common_tags = local.common_tags
  node_group_tags = {
    Purpose = "application-workloads"
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_iam_role_policy_attachment.amazon_ec2_ebs_driver_policy,
    aws_iam_role_policy_attachment.amazon_cloudwatch_agent
  ]
}

################################################################################
# General Node Group
################################################################################

module "general_node_group" {
  source = "../../modules/AWS/eks-self-managed-node-group"

  cluster_name                        = module.eks.cluster_name
  cluster_endpoint                    = module.eks.cluster_endpoint
  cluster_certificate_authority_data  = module.eks.cluster_certificate_authority_data
  cluster_service_cidr               = module.eks.cluster_service_cidr
  cluster_primary_security_group_id  = module.eks.cluster_primary_security_group_id
  subnet_ids                         = module.vpc.private_subnets
  vpc_security_group_ids             = [module.eks.cluster_primary_security_group_id, module.eks.node_security_group_id]
  iam_role_arn                       = aws_iam_role.self_managed_node_group.arn

  # Node group configuration
  node_group_name = "general"
  cluster_version = var.kubernetes_version
  launch_template_name = "general-nodes"

  # Scaling configuration
  min_size     = var.general_min_size
  max_size     = var.general_max_size
  desired_size = var.general_desired_size

  # Instance configuration
  instance_type = var.general_instance_types[1]

  # Node configuration
  bootstrap_extra_args = "--kubelet-extra-args '--node-labels=type=self-managed,Purpose=general-workloads,karpenter.sh/controller=true'"

  common_tags = local.common_tags
  node_group_tags = {
    Purpose = "general-workloads"
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    aws_iam_role_policy_attachment.amazon_ec2_ebs_driver_policy,
    aws_iam_role_policy_attachment.amazon_cloudwatch_agent
  ]
}

# ################################################################################
# # ACM Certificates for Production
# ################################################################################

# resource "aws_acm_certificate" "production_certificate" {
#   domain_name       = "*.${var.domain_name}"
#   subject_alternative_names = [
#     "*.${var.domain_name}",
#   ]
#   validation_method = "DNS"
  
#   tags = merge(local.common_tags, {
#     Name = "production-eks-microservice-certificate"
#   })

#   lifecycle {
#     create_before_destroy = true
#   }
# }





