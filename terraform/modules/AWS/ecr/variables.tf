variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Image tag mutability policy"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Enable image scan on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type: AES256 or KMS"
  type        = string
  default     = "AES256"
}

variable "kms_key_id" {
  description = "KMS key ID/ARN when encryption_type is KMS"
  type        = string
  default     = null
}

variable "force_delete" {
  description = "Force delete repository (also delete images)"
  type        = bool
  default     = false
}

variable "lifecycle_policy_json" {
  description = "Lifecycle policy JSON for ECR"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
