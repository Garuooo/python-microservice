# Production Environment Outputs

# Cluster Information
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if one was created"
  value       = module.eks.oidc_provider_arn
}

# VPC Information
output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

# Node Groups
output "node_security_group_id" {
  description = "ID of the node shared security group"
  value       = module.eks.node_security_group_id
}

output "application_node_group_asg_name" {
  description = "Auto Scaling Group name for the application node group"
  value       = module.application_node_group.autoscaling_group_name
}

output "general_node_group_asg_name" {
  description = "Auto Scaling Group name for the general node group"
  value       = module.general_node_group.autoscaling_group_name
}

# IRSA Roles
output "aws_load_balancer_controller_iam_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = module.irsa_aws_load_balancer_controller.iam_role_arn
}

output "ebs_csi_iam_role_arn" {
  description = "ARN of the EBS CSI IAM role"
  value       = module.irsa_ebs_csi.iam_role_arn
}

// output "application_s3_iam_role_arn" {
//   description = "ARN of the Application S3 IAM role"
//   value       = module.irsa_application_s3.iam_role_arn
// }

// output "external_secrets_iam_role_arn" {
//   description = "ARN of the External Secrets IAM role"
//   value       = aws_iam_role.external_secrets_role.arn
// }

# Karpenter
output "karpenter_iam_role_arn" {
  description = "ARN of the Karpenter IAM role"
  value       = module.karpenter.karpenter_iam_role_arn
}

output "karpenter_queue_name" {
  description = "Name of the Karpenter queue"
  value       = module.karpenter.karpenter_queue_name
}

# Storage Information
// output "application_data_bucket_name" {
//   description = "Name of the Application Data S3 bucket"
//   value       = aws_s3_bucket.application_data.bucket
// }

// output "application_data_bucket_arn" {
//   description = "ARN of the Application Data S3 bucket"
//   value       = aws_s3_bucket.application_data.arn
// }

// output "application_logs_bucket_name" {
//   description = "Name of the Application Logs S3 bucket"
//   value       = aws_s3_bucket.application_logs.bucket
// }

// output "application_logs_bucket_arn" {
//   description = "ARN of the Application Logs S3 bucket"
//   value       = aws_s3_bucket.application_logs.arn
// }

# KMS Information
output "kms_key_id" {
  description = "ID of the KMS key"
  value       = module.kms_cluster.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = module.kms_cluster.key_arn
}

output "kms_alias_name" {
  description = "Name of the KMS key alias"
  value       = module.kms_cluster.alias_name
}

# Certificates
// output "production_certificate_arn" {
//   description = "ARN of the production certificate"
//   value       = aws_acm_certificate.production_certificate.arn
// }

// output "production_certificate_domain_name" {
//   description = "Domain name of the production certificate"
//   value       = aws_acm_certificate.production_certificate.domain_name
// }

# Connection Information
output "connection_info" {
  description = "Information for connecting to the cluster"
  value = {
    cluster_name = module.eks.cluster_name
    cluster_endpoint = module.eks.cluster_endpoint
    region = var.aws_region
    kubectl_command = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
  }
}

# # Application Information
# output "application_info" {
#   description = "Information about the application infrastructure"
#   value = {
#     cluster_name = module.eks.cluster_name
#     domain_name = var.domain_name
#     certificate_arn = aws_acm_certificate.production_certificate.arn
#     data_bucket = aws_s3_bucket.application_data.bucket
#     logs_bucket = aws_s3_bucket.application_logs.bucket
#     application_node_group = module.application_node_group.node_group_id
#     general_node_group = module.general_node_group.node_group_id
#   }
# }
