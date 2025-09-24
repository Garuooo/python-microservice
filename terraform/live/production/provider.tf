# Production EKS Cluster for Microservice Application using Streamlined Modules
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket          = "tf-state-task-123"
    key             = "production/state/resource.tfstate"
    region          = "us-east-1"
    encrypt         = true
    # kms_key_id      = "arn:aws:kms:eu-central-1::key/d384da77-ab"
    use_lockfile    = true
  }
}

provider "aws" {
  region = var.aws_region
}
