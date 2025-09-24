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
# KMS Module
################################################################################

# Local values for consistent tagging
locals {
  common_tags = merge(var.common_tags, {
    Component   = "kms"
    ServiceType = "encryption"
  })

  alias_name = var.alias_name != null ? var.alias_name : "alias/${var.key_name}"
}

# KMS Key
resource "aws_kms_key" "main" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  key_usage               = var.key_usage
  # key_spec                = var.key_spec  # Not supported in all versions
  multi_region            = var.multi_region
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check

  policy = var.policy
  # key_policy = var.key_policy  # Not supported in all versions

  tags = merge(local.common_tags, var.key_tags, {
    Name = var.key_name
  })
}

# KMS Key Alias
resource "aws_kms_alias" "main" {
  count = var.create_alias ? 1 : 0

  name          = local.alias_name
  target_key_id = aws_kms_key.main.key_id
}