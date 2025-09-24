# EKS Self-Managed Node Group Module

This module creates a self-managed node group for Amazon EKS with configurable scaling, instance types, and storage options.

## Features

- **Self-Managed Node Group**: Creates an autoscaling group for EKS nodes
- **Launch Template**: Configurable EC2 launch template
- **Mixed Instances Policy**: Support for spot and on-demand instances
- **Node Labels and Taints**: Configurable node scheduling constraints
- **Storage Configuration**: Flexible EBS volume configuration
- **IAM Integration**: Proper IAM roles and policies for EKS nodes

## Usage

```hcl
module "self_managed_node_group" {
  source = "./modules/AWS/eks-self-managed-node-group"

  cluster_name                        = "my-eks-cluster"
  cluster_endpoint                    = module.eks.cluster_endpoint
  cluster_certificate_authority_data  = module.eks.cluster_certificate_authority_data
  cluster_service_cidr               = module.eks.cluster_service_cidr
  cluster_primary_security_group_id  = module.eks.cluster_primary_security_group_id
  subnet_ids                         = module.vpc.private_subnets
  vpc_security_group_ids             = [module.eks.cluster_primary_security_group_id, module.eks.node_security_group_id]
  iam_role_arn                       = aws_iam_role.node_group.arn

  # Node group configuration
  node_group_name = "observability"
  min_size        = 1
  max_size        = 10
  desired_size    = 2
  instance_type   = "t3.large"

  # Node labels and taints
  node_labels = {
    "Purpose" = "observability-workloads"
    "Type"    = "self-managed"
  }

  node_taints = ["type=self-managed:NoSchedule"]

  # Storage configuration
  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size = 100
        volume_type = "gp3"
        encrypted   = true
      }
    }
  ]

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
| cluster_endpoint | Endpoint for EKS control plane | `string` | n/a | yes |
| cluster_certificate_authority_data | Base64 encoded certificate data required to communicate with the cluster | `string` | n/a | yes |
| cluster_service_cidr | The CIDR block that Kubernetes service IP addresses are assigned from | `string` | n/a | yes |
| cluster_primary_security_group_id | The cluster primary security group ID created by EKS | `string` | n/a | yes |
| subnet_ids | List of subnet IDs where the node group will be deployed | `list(string)` | n/a | yes |
| vpc_security_group_ids | List of security group IDs to attach to the node group | `list(string)` | n/a | yes |
| iam_role_arn | ARN of the IAM role for the node group | `string` | n/a | yes |
| node_group_name | Name of the node group | `string` | `"self-managed"` | no |
| cluster_version | Kubernetes version for the node group | `string` | `"1.28"` | no |
| launch_template_name | Name of the launch template for the node group | `string` | `"self-managed-nodes"` | no |
| min_size | Minimum number of nodes in the node group | `number` | `1` | no |
| max_size | Maximum number of nodes in the node group | `number` | `3` | no |
| desired_size | Desired number of nodes in the node group | `number` | `1` | no |
| instance_type | Instance type for the node group | `string` | `"t3.medium"` | no |
| instance_types | List of instance types for the node group | `list(string)` | `["t3.medium"]` | no |
| block_device_mappings | List of block device mappings for the node group | `list(object)` | See variables | no |
| node_labels | Map of node labels to apply to the node group | `map(string)` | `{}` | no |
| node_taints | List of node taints to apply to the node group | `list(string)` | `[]` | no |
| bootstrap_extra_args | Extra arguments to pass to the bootstrap script | `string` | `""` | no |
| use_mixed_instances_policy | Whether to use mixed instances policy | `bool` | `false` | no |
| mixed_instances_policy | Mixed instances policy configuration | `object` | `null` | no |
| user_data | User data script for the node group | `string` | `""` | no |
| user_data_base64 | Base64 encoded user data script for the node group | `string` | `""` | no |
| common_tags | A map of common tags to apply to all resources | `map(string)` | `{}` | no |
| node_group_tags | A map of additional tags to apply to the node group | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| node_group_id | ID of the self-managed node group |
| node_group_arn | ARN of the self-managed node group |
| node_group_name | Name of the self-managed node group |
| launch_template_id | ID of the launch template used by the node group |
| launch_template_arn | ARN of the launch template used by the node group |
| autoscaling_group_arn | ARN of the autoscaling group |
| autoscaling_group_name | Name of the autoscaling group |
| iam_role_arn | ARN of the IAM role used by the node group |
| iam_role_name | Name of the IAM role used by the node group |

## Examples

### Basic Self-Managed Node Group

```hcl
module "self_managed_node_group" {
  source = "./modules/AWS/eks-self-managed-node-group"

  cluster_name                        = module.eks.cluster_name
  cluster_endpoint                    = module.eks.cluster_endpoint
  cluster_certificate_authority_data  = module.eks.cluster_certificate_authority_data
  cluster_service_cidr               = module.eks.cluster_service_cidr
  cluster_primary_security_group_id  = module.eks.cluster_primary_security_group_id
  subnet_ids                         = module.vpc.private_subnets
  vpc_security_group_ids             = [module.eks.cluster_primary_security_group_id, module.eks.node_security_group_id]
  iam_role_arn                       = aws_iam_role.node_group.arn
}
```

### Observability Node Group

```hcl
module "observability_node_group" {
  source = "./modules/AWS/eks-self-managed-node-group"

  cluster_name                        = module.eks.cluster_name
  cluster_endpoint                    = module.eks.cluster_endpoint
  cluster_certificate_authority_data  = module.eks.cluster_certificate_authority_data
  cluster_service_cidr               = module.eks.cluster_service_cidr
  cluster_primary_security_group_id  = module.eks.cluster_primary_security_group_id
  subnet_ids                         = module.vpc.private_subnets
  vpc_security_group_ids             = [module.eks.cluster_primary_security_group_id, module.eks.node_security_group_id]
  iam_role_arn                       = aws_iam_role.node_group.arn

  node_group_name = "observability"
  min_size        = 2
  max_size        = 10
  desired_size    = 3
  instance_type   = "m5.large"

  node_labels = {
    "Purpose" = "observability-workloads"
    "Type"    = "self-managed"
  }

  node_taints = ["type=self-managed:NoSchedule"]

  block_device_mappings = [
    {
      device_name = "/dev/xvda"
      ebs = {
        volume_size = 100
        volume_type = "gp3"
        encrypted   = true
      }
    }
  ]

  common_tags = {
    Environment = "production"
    Project     = "observability"
  }
}
```

### Mixed Instances Policy with Spot Instances

```hcl
module "spot_node_group" {
  source = "./modules/AWS/eks-self-managed-node-group"

  cluster_name                        = module.eks.cluster_name
  cluster_endpoint                    = module.eks.cluster_endpoint
  cluster_certificate_authority_data  = module.eks.cluster_certificate_authority_data
  cluster_service_cidr               = module.eks.cluster_service_cidr
  cluster_primary_security_group_id  = module.eks.cluster_primary_security_group_id
  subnet_ids                         = module.vpc.private_subnets
  vpc_security_group_ids             = [module.eks.cluster_primary_security_group_id, module.eks.node_security_group_id]
  iam_role_arn                       = aws_iam_role.node_group.arn

  node_group_name = "spot"
  min_size        = 0
  max_size        = 20
  desired_size    = 2

  use_mixed_instances_policy = true
  mixed_instances_policy = {
    instances_distribution = {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
    launch_template = {
      override = [
        {
          instance_type     = "t3.medium"
          weighted_capacity = "1"
        },
        {
          instance_type     = "t3.large"
          weighted_capacity = "2"
        },
        {
          instance_type     = "m5.large"
          weighted_capacity = "2"
        }
      ]
    }
  }

  node_labels = {
    "Purpose" = "general-workloads"
    "Type"    = "spot"
  }

  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Notes

- The module requires an existing EKS cluster and VPC
- IAM role must be created separately with appropriate policies
- Node groups support both on-demand and spot instances
- Storage volumes are encrypted by default
- Node labels and taints help with workload scheduling
