# KMS Module

This module creates AWS Key Management Service (KMS) keys with configurable options for encryption, rotation, and access policies.

## Features

- **KMS Key**: Creates a customer-managed KMS key
- **Key Alias**: Optional alias for easier key management
- **Key Rotation**: Configurable automatic key rotation
- **Access Policies**: Custom key policies for fine-grained access control
- **Multi-Region Support**: Optional multi-region key support

## Usage

```hcl
module "kms" {
  source = "./modules/AWS/kms"

  key_name = "my-encryption-key"
  description = "KMS key for application encryption"

  # Optional configurations
  deletion_window_in_days = 7
  enable_key_rotation = true
  multi_region = false

  # Alias
  create_alias = true
  alias_name = "my-key-alias"

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
| key_name | Name for the KMS key | `string` | n/a | yes |
| description | Description of the KMS key | `string` | `"KMS key for encryption"` | no |
| deletion_window_in_days | Number of days to wait before deleting the KMS key | `number` | `7` | no |
| enable_key_rotation | Whether to enable automatic key rotation | `bool` | `true` | no |
| key_usage | Intended use of the KMS key | `string` | `"ENCRYPT_DECRYPT"` | no |
| key_spec | Key specification for the KMS key | `string` | `"SYMMETRIC_DEFAULT"` | no |
| multi_region | Whether to create a multi-region key | `bool` | `false` | no |
| bypass_policy_lockout_safety_check | Whether to bypass the policy lockout safety check | `bool` | `false` | no |
| policy | Custom policy document for the KMS key | `string` | `null` | no |
| key_policy | Key policy document for the KMS key | `string` | `null` | no |
| create_alias | Whether to create an alias for the KMS key | `bool` | `true` | no |
| alias_name | Name for the KMS key alias | `string` | `null` | no |
| alias_description | Description for the KMS key alias | `string` | `null` | no |
| common_tags | A map of common tags to apply to all resources | `map(string)` | `{}` | no |
| key_tags | A map of additional tags to apply to the KMS key | `map(string)` | `{}` | no |
| alias_tags | A map of additional tags to apply to the KMS key alias | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| key_id | ID of the KMS key |
| key_arn | ARN of the KMS key |
| key_description | Description of the KMS key |
| key_usage | Usage of the KMS key |
| key_spec | Specification of the KMS key |
| multi_region | Whether the KMS key is multi-region |
| key_policy | Policy of the KMS key |
| alias_name | Name of the KMS key alias |
| alias_arn | ARN of the KMS key alias |
| alias_target_key_id | Target key ID of the KMS key alias |

## Examples

### Basic KMS Key

```hcl
module "kms" {
  source = "./modules/AWS/kms"

  key_name = "basic-encryption-key"
}
```

### EKS Cluster Encryption Key

```hcl
module "eks_kms" {
  source = "./modules/AWS/kms"

  key_name = "eks-cluster-encryption"
  description = "KMS key for EKS cluster encryption"

  enable_key_rotation = true
  deletion_window_in_days = 7

  create_alias = true
  alias_name = "eks-cluster-key"

  common_tags = {
    Environment = "production"
    Project     = "eks-cluster"
    Purpose     = "cluster-encryption"
  }
}
```

### S3 Bucket Encryption Key

```hcl
module "s3_kms" {
  source = "./modules/AWS/kms"

  key_name = "s3-bucket-encryption"
  description = "KMS key for S3 bucket encryption"

  enable_key_rotation = true
  deletion_window_in_days = 30

  create_alias = true
  alias_name = "s3-bucket-key"

  common_tags = {
    Environment = "production"
    Project     = "data-storage"
    Purpose     = "s3-encryption"
  }
}
```

### Multi-Region KMS Key

```hcl
module "multi_region_kms" {
  source = "./modules/AWS/kms"

  key_name = "multi-region-encryption"
  description = "Multi-region KMS key for global encryption"

  multi_region = true
  enable_key_rotation = true
  deletion_window_in_days = 7

  create_alias = true
  alias_name = "global-encryption-key"

  common_tags = {
    Environment = "production"
    Project     = "global-encryption"
    Purpose     = "multi-region-encryption"
  }
}
```

### KMS Key with Custom Policy

```hcl
module "custom_policy_kms" {
  source = "./modules/AWS/kms"

  key_name = "custom-policy-key"
  description = "KMS key with custom access policy"

  key_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow specific service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  common_tags = {
    Environment = "production"
    Project     = "custom-encryption"
  }
}
```

## Notes

- KMS keys are region-specific unless multi_region is enabled
- Key rotation is recommended for production environments
- Deletion window should be set appropriately for your security requirements
- Custom policies allow fine-grained access control
- Aliases make key management easier and more user-friendly
