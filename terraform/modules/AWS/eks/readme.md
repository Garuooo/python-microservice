# EKS Module

This module creates an Amazon Elastic Kubernetes Service (EKS) cluster with configurable options for networking, security, and add-ons.

## Features

- **EKS Cluster**: Creates a managed Kubernetes cluster
- **IRSA Support**: Enables IAM Roles for Service Accounts
- **Cluster Addons**: Configurable EKS add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI)
- **Security**: Configurable endpoint access and encryption
- **Logging**: Optional cluster logging configuration

## Usage

```hcl
module "eks" {
  source = "./modules/AWS/eks"

  cluster_name = "my-eks-cluster"
  vpc_id       = "vpc-12345678"
  subnet_ids   = ["subnet-12345678", "subnet-87654321"]

  # Optional configurations
  cluster_version = "1.28"
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access_cidrs = ["10.0.0.0/8"]
  
  # Encryption
  cluster_encryption_config = {
    provider_key_arn = "arn:aws:kms:region:account:key/key-id"
    resources        = ["secrets"]
  }

  # Logging
  cluster_enabled_log_types = ["api", "audit", "authenticator"]

  # Add-ons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent                 = true
      service_account_role_arn    = "arn:aws:iam::account:role/ebs-csi-role"
    }
  }

  # Tags
  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| vpc_id | ID of the VPC where the EKS cluster will be deployed | `string` | n/a | yes |
| subnet_ids | List of subnet IDs where the EKS cluster will be deployed | `list(string)` | n/a | yes |
| cluster_version | Kubernetes version for the EKS cluster | `string` | `"1.28"` | no |
| cluster_endpoint_public_access | Whether the Amazon EKS public API server endpoint is enabled | `bool` | `true` | no |
| cluster_endpoint_private_access | Whether the Amazon EKS private API server endpoint is enabled | `bool` | `true` | no |
| cluster_endpoint_public_access_cidrs | List of CIDR blocks which can access the Amazon EKS public API server endpoint | `list(string)` | `["0.0.0.0/0"]` | no |
| enable_cluster_creator_admin_permissions | Whether to enable cluster creator admin permissions | `bool` | `true` | no |
| cluster_encryption_config | Configuration block with encryption configuration for the cluster | `object` | `null` | no |
| cluster_enabled_log_types | List of cluster log types to enable | `list(string)` | `[]` | no |
| enable_irsa | Whether to enable IAM Roles for Service Accounts (IRSA) | `bool` | `true` | no |
| create_cluster_primary_security_group_tags | Whether to create tags for the cluster primary security group | `bool` | `false` | no |
| node_security_group_tags | A map of additional tags to add to the node security group | `map(string)` | `{}` | no |
| cluster_addons | Map of cluster addon configurations to enable for the cluster | `map(object)` | See variables | no |
| ebs_csi_driver_role_arn | ARN of the EBS CSI driver IAM role | `string` | `null` | no |
| common_tags | A map of common tags to apply to all resources | `map(string)` | `{}` | no |
| cluster_tags | A map of additional tags to apply to the cluster | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the EKS cluster |
| cluster_arn | ARN of the EKS cluster |
| cluster_name | Name of the EKS cluster |
| cluster_endpoint | Endpoint for EKS control plane |
| cluster_security_group_id | Security group ID attached to the EKS cluster |
| cluster_primary_security_group_id | The cluster primary security group ID created by EKS |
| cluster_certificate_authority_data | Base64 encoded certificate data required to communicate with the cluster |
| cluster_oidc_issuer_url | The URL on the EKS cluster for the OpenID Connect identity provider |
| oidc_provider_arn | The ARN of the OIDC Provider if one was created |
| node_security_group_id | ID of the node shared security group |
| cluster_service_cidr | The CIDR block that Kubernetes service IP addresses are assigned from |
| kubeconfig | Kubeconfig for the EKS cluster (sensitive) |

## Examples

### Basic EKS Cluster

```hcl
module "eks" {
  source = "./modules/AWS/eks"

  cluster_name = "basic-cluster"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
}
```

### Production EKS Cluster with Encryption

```hcl
module "eks" {
  source = "./modules/AWS/eks"

  cluster_name = "production-cluster"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets

  cluster_version = "1.28"
  cluster_encryption_config = {
    provider_key_arn = module.kms.key_arn
    resources        = ["secrets"]
  }

  cluster_enabled_log_types = [
    "api", "audit", "authenticator", "controllerManager", "scheduler"
  ]

  cluster_endpoint_public_access_cidrs = ["10.0.0.0/8"]

  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```
