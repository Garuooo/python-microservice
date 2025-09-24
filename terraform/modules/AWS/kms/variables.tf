# KMS Module Variables

# Required Variables
variable "key_name" {
  description = "Name for the KMS key"
  type        = string
}

# Optional Variables
variable "description" {
  description = "Description of the KMS key"
  type        = string
  default     = "KMS key for encryption"
}

variable "deletion_window_in_days" {
  description = "Number of days to wait before deleting the KMS key"
  type        = number
  default     = 7
}

variable "enable_key_rotation" {
  description = "Whether to enable automatic key rotation"
  type        = bool
  default     = true
}

variable "key_usage" {
  description = "Intended use of the KMS key"
  type        = string
  default     = "ENCRYPT_DECRYPT"
}

variable "multi_region" {
  description = "Whether to create a multi-region key"
  type        = bool
  default     = false
}

variable "bypass_policy_lockout_safety_check" {
  description = "Whether to bypass the policy lockout safety check"
  type        = bool
  default     = false
}

variable "policy" {
  description = "Custom policy document for the KMS key"
  type        = string
  default     = null
}

# Alias Configuration
variable "create_alias" {
  description = "Whether to create an alias for the KMS key"
  type        = bool
  default     = true
}

variable "alias_name" {
  description = "Name for the KMS key alias"
  type        = string
  default     = null
}

# Tags
variable "common_tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "key_tags" {
  description = "A map of additional tags to apply to the KMS key"
  type        = map(string)
  default     = {}
}