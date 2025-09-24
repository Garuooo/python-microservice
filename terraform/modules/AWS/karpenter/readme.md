# Karpenter Module

This module sets up Karpenter for Amazon EKS, providing dynamic node provisioning and scaling capabilities.

## Features

- **Karpenter Controller**: Automated node provisioning and scaling
- **IRSA Support**: IAM Roles for Service Accounts integration
- **Spot Instance Support**: EC2 Spot service linked role
- **Node IAM Role**: Configurable IAM role for Karpenter-managed nodes
- **Queue Management**: SQS queue for node interruption handling

## Usage

```hcl
module "karpenter" {
  source = "./modules/AWS/karpenter"

  cluster_name        = "my-eks-cluster"
  oidc_provider_arn   = module.eks.oidc_provider_arn

  # Optional configurations
  enable_karpenter = true
  enable_v1_permissions = true
  enable_irsa = true

  # Node IAM role additional policies
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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
| oidc_provider_arn | ARN of the OIDC Provider | `string` | n/a | yes |
| enable_karpenter | Whether to enable Karpenter | `bool` | `true` | no |
| enable_v1_permissions | Whether to enable v1 permissions for Karpenter | `bool` | `true` | no |
| enable_irsa | Whether to enable IRSA for Karpenter | `bool` | `true` | no |
| irsa_namespace_service_accounts | List of namespace/service account combinations for IRSA | `list(string)` | `["kube-system:karpenter"]` | no |
| create_pod_identity_association | Whether to create pod identity association | `bool` | `false` | no |
| node_iam_role_use_name_prefix | Whether to use name prefix for node IAM role | `bool` | `false` | no |
| node_iam_role_additional_policies | Additional IAM policies to attach to the Karpenter node IAM role | `map(string)` | See variables | no |
| spot_service_linked_role_name | Name for the EC2 Spot service linked role | `string` | `"spot"` | no |
| spot_service_linked_role_description | Description for the EC2 Spot service linked role | `string` | `"Service-linked role for EC2 Spot instances used by Karpenter"` | no |
| common_tags | A map of common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| karpenter_iam_role_arn | ARN of the Karpenter IAM role |
| karpenter_iam_role_name | Name of the Karpenter IAM role |
| karpenter_queue_name | Name of the Karpenter queue |
| karpenter_queue_arn | ARN of the Karpenter queue |
| karpenter_node_instance_profile_name | Name of the Karpenter node instance profile |
| karpenter_node_instance_profile_arn | ARN of the Karpenter node instance profile |
| spot_service_linked_role_arn | ARN of the EC2 Spot service linked role |

## Examples

### Basic Karpenter Setup

```hcl
module "karpenter" {
  source = "./modules/AWS/karpenter"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
}
```

### Karpenter with Custom Policies

```hcl
module "karpenter" {
  source = "./modules/AWS/karpenter"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn

  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }

  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Disabled Karpenter

```hcl
module "karpenter" {
  source = "./modules/AWS/karpenter"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_karpenter = false
}
```

## Notes

- Karpenter requires an existing EKS cluster with OIDC provider enabled
- The module creates an EC2 Spot service linked role for spot instance support
- IRSA is used for secure access to AWS services from Karpenter pods
- The module supports both v1 and v2 Karpenter configurations
