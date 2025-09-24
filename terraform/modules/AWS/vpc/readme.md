# VPC Module

This module creates a comprehensive Amazon Virtual Private Cloud (VPC) with configurable subnets, NAT gateways, and networking components.

## Features

- **VPC**: Creates a VPC with configurable CIDR block
- **Subnets**: Support for private, public, database, intra, ElastiCache, and Redshift subnets
- **NAT Gateways**: Configurable NAT gateways for private subnet internet access
- **Internet Gateway**: Automatic internet gateway creation
- **Route Tables**: Automatic route table creation and management
- **VPC Endpoints**: Optional VPC endpoints for AWS services
- **Flow Logs**: Optional VPC Flow Logs for monitoring
- **DHCP Options**: Configurable DHCP options

## Usage

```hcl
module "vpc" {
  source = "./modules/AWS/vpc"

  vpc_name = "my-vpc"
  vpc_cidr = "10.0.0.0/16"

  # Subnets
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets   = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = false

  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Flow Logs
  enable_flow_log = true
  create_flow_log_cloudwatch_iam_role = true
  create_flow_log_cloudwatch_log_group = true

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
| vpc_name | Name of the VPC | `string` | n/a | yes |
| vpc_cidr | CIDR block for the VPC | `string` | n/a | yes |
| availability_zones | List of availability zones | `list(string)` | `[]` | no |
| private_subnets | List of private subnet CIDR blocks | `list(string)` | `[]` | no |
| public_subnets | List of public subnet CIDR blocks | `list(string)` | `[]` | no |
| database_subnets | List of database subnet CIDR blocks | `list(string)` | `[]` | no |
| intra_subnets | List of intra subnet CIDR blocks | `list(string)` | `[]` | no |
| elasticache_subnets | List of ElastiCache subnet CIDR blocks | `list(string)` | `[]` | no |
| redshift_subnets | List of Redshift subnet CIDR blocks | `list(string)` | `[]` | no |
| enable_nat_gateway | Whether to enable NAT Gateway | `bool` | `true` | no |
| single_nat_gateway | Whether to use a single NAT Gateway for all private subnets | `bool` | `false` | no |
| one_nat_gateway_per_az | Whether to create one NAT Gateway per availability zone | `bool` | `false` | no |
| enable_vpn_gateway | Whether to enable VPN Gateway | `bool` | `false` | no |
| enable_dns_hostnames | Whether to enable DNS hostnames in the VPC | `bool` | `true` | no |
| enable_dns_support | Whether to enable DNS support in the VPC | `bool` | `true` | no |
| enable_flow_log | Whether to enable VPC Flow Logs | `bool` | `false` | no |
| common_tags | A map of common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_arn | ARN of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| private_subnets | List of IDs of private subnets |
| public_subnets | List of IDs of public subnets |
| database_subnets | List of IDs of database subnets |
| intra_subnets | List of IDs of intra subnets |
| elasticache_subnets | List of IDs of ElastiCache subnets |
| redshift_subnets | List of IDs of Redshift subnets |
| igw_id | ID of the Internet Gateway |
| nat_ids | List of IDs of the NAT Gateways |
| nat_public_ips | List of public Elastic IPs of the NAT Gateways |
| private_route_table_ids | List of IDs of private route tables |
| public_route_table_ids | List of IDs of public route tables |
| database_route_table_ids | List of IDs of database route tables |
| vpc_endpoints | Array of VPC endpoints |
| vpc_flow_log_id | ID of the VPC Flow Log |
| azs | List of availability zones used |

## Examples

### Basic VPC

```hcl
module "vpc" {
  source = "./modules/AWS/vpc"

  vpc_name = "basic-vpc"
  vpc_cidr = "10.0.0.0/16"

  availability_zones = ["us-west-2a", "us-west-2b"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
}
```

### EKS-Optimized VPC

```hcl
module "vpc" {
  source = "./modules/AWS/vpc"

  vpc_name = "eks-vpc"
  vpc_cidr = "10.0.0.0/16"

  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # EKS-specific subnet tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "karpenter.sh/discovery" = "my-eks-cluster"
  }

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = false

  common_tags = {
    Environment = "production"
    Project     = "eks-cluster"
  }
}
```

### Production VPC with All Features

```hcl
module "vpc" {
  source = "./modules/AWS/vpc"

  vpc_name = "production-vpc"
  vpc_cidr = "10.0.0.0/16"

  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets   = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  elasticache_subnets = ["10.0.301.0/24", "10.0.302.0/24", "10.0.303.0/24"]

  # NAT Gateway configuration
  enable_nat_gateway = true
  single_nat_gateway = false

  # VPC Endpoints
  enable_vpc_endpoints = true
  vpc_endpoints = {
    s3 = {
      service = "s3"
      vpc_endpoint_type = "Gateway"
    }
    ecr_dkr = {
      service = "ecr.dkr"
      vpc_endpoint_type = "Interface"
      private_dns_enabled = true
    }
  }

  # Flow Logs
  enable_flow_log = true
  create_flow_log_cloudwatch_iam_role = true
  create_flow_log_cloudwatch_log_group = true
  flow_log_cloudwatch_log_group_retention_in_days = 30

  # DNS configuration
  enable_dns_hostnames = true
  enable_dns_support   = true

  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Cost-Optimized VPC

```hcl
module "vpc" {
  source = "./modules/AWS/vpc"

  vpc_name = "cost-optimized-vpc"
  vpc_cidr = "10.0.0.0/16"

  availability_zones = ["us-west-2a", "us-west-2b"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]

  # Cost optimization
  enable_nat_gateway = true
  single_nat_gateway = true  # Single NAT Gateway to save costs

  # Disable expensive features
  enable_flow_log = false
  enable_vpc_endpoints = false

  common_tags = {
    Environment = "development"
    Project     = "cost-optimized"
  }
}
```

## Notes

- The module uses the official AWS VPC module as the underlying implementation
- Subnet tags are important for EKS and other AWS services
- NAT Gateway costs can be significant - consider single NAT Gateway for cost optimization
- VPC Flow Logs provide valuable network monitoring but add costs
- VPC endpoints can reduce data transfer costs for AWS services
- Database subnets are isolated and don't have internet access
