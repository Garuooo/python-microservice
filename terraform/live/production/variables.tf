# Production Environment Variables

# Basic Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "microservice-production"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "microservice-production"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.32"
}

# variable "domain_name" {
  # description = "Domain name for the application"
  # type        = string
  # default     = "garuooo.com"
# }

# Networking Configuration
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"  # Production CIDR
}

variable "availability_zones" {
  description = "Availability zones for the cluster"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets"
  type        = bool
  default     = true  # Single NAT for production cost optimization
}

# Security Configuration
variable "office_ip_cidrs" {
  description = "Office IP CIDR blocks for API server access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Replace with actual office IPs
}

# Cluster Features
variable "enable_cluster_encryption" {
  description = "Enable cluster encryption"
  type        = bool
  default     = true  # Enabled for production
}

variable "cluster_enabled_log_types" {
  description = "List of cluster log types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true  # Enabled for production
}

variable "flow_log_retention_days" {
  description = "VPC Flow Log retention in days"
  type        = number
  default     = 30  # Longer retention for production
}

# Karpenter Configuration
variable "enable_karpenter" {
  description = "Enable Karpenter for node provisioning"
  type        = bool
  default     = true
}

# Application Node Group Configuration
variable "application_min_size" {
  description = "Minimum number of nodes in application node group"
  type        = number
  default     = 1  # Higher minimum for production
}

variable "application_max_size" {
  description = "Maximum number of nodes in application node group"
  type        = number
  default     = 3  # Higher max for production
}

variable "application_desired_size" {
  description = "Desired number of nodes in application node group"
  type        = number
  default     = 1
}

variable "application_instance_types" {
  description = "Instance types for application node group"
  type        = list(string)
  default     = ["t3.small","t3.medium"]
}

# variable "application_volume_size" {
#   description = "Volume size for application nodes"
#   type        = number
#   default     = 50
# }

# variable "application_volume_type" {
#   description = "Volume type for application nodes"
#   type        = string
#   default     = "gp3"
# }

# General Node Group Configuration
variable "general_min_size" {
  description = "Minimum number of nodes in general node group"
  type        = number
  default     = 2
}

variable "general_max_size" {
  description = "Maximum number of nodes in general node group"
  type        = number
  default     = 3  # Higher max for production
}

variable "general_desired_size" {
  description = "Desired number of nodes in general node group"
  type        = number
  default     = 2
}

variable "general_instance_types" {
  description = "Instance types for general node group"
  type        = list(string)
  default     = ["t3.small","t3.medium"]
}

# variable "general_volume_size" {
#   description = "Volume size for general nodes"
#   type        = number
#   default     = 30
# }

# variable "general_volume_type" {
#   description = "Volume type for general nodes"
#   type        = string
#   default     = "gp3"
# }

# Subnet Tags
variable "public_subnet_tags" {
  description = "Additional tags for public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default     = {}
}


