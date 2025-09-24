# Production Environment - EKS Microservice Application

This directory contains the Terraform configuration for the production environment of the EKS microservice application.

## Overview

The production environment provides a robust, scalable infrastructure for deploying microservice applications. It includes:

- **EKS Cluster** with encryption and comprehensive logging
- **VPC** with private/public subnets across multiple AZs
- **Node Groups** for application and general workloads
- **Karpenter** for dynamic node provisioning
- **S3 Buckets** for application data and logs storage
- **IRSA Roles** for secure service-to-service communication
- **KMS Keys** for encryption
- **ACM Certificates** for HTTPS

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Production VPC                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │   Public AZ-1   │  │   Public AZ-2   │  │ Public AZ-3 │  │
│  │  ┌───────────┐  │  │  ┌───────────┐  │  │┌─────────┐  │  │
│  │  │   ALB     │  │  │  │   ALB     │  │  ││   ALB   │  │  │
│  │  └───────────┘  │  │  └───────────┘  │  │└─────────┘  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
│           │                     │                   │        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │  Private AZ-1   │  │  Private AZ-2   │  │ Private AZ-3│  │
│  │  ┌───────────┐  │  │  ┌───────────┐  │  │┌─────────┐  │  │
│  │  │EKS Nodes  │  │  │  │EKS Nodes  │  │  ││EKS Nodes│  │  │
│  │  │Application│  │  │  │General    │  │  ││Karpenter│  │  │
│  │  └───────────┘  │  │  └───────────┘  │  │└─────────┘  │  │
│  └─────────────────┘  └─────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────┘
                                │
                    ┌─────────────────┐
                    │   S3 Buckets    │
                    │ ┌─────────────┐ │
                    │ │Application  │ │
                    │ │    Data     │ │
                    │ │Application  │ │
                    │ │    Logs     │ │
                    │ └─────────────┘ │
                    └─────────────────┘
```

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0
3. **kubectl** for Kubernetes management
4. **AWS Account** with necessary permissions

## Quick Start

### 1. Configure Variables

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit the variables file with your specific values
vim terraform.tfvars
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan the Deployment

```bash
terraform plan
```

### 4. Apply the Configuration

```bash
terraform apply
```

### 5. Configure kubectl

```bash
# Get cluster credentials
aws eks update-kubeconfig --region eu-central-1 --name microservice-production

# Verify cluster access
kubectl get nodes
```

## Configuration

### Key Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|:--------:|
| `cluster_name` | Name of the EKS cluster | `microservice-production` | No |
| `aws_region` | AWS region | `eu-central-1` | No |
| `kubernetes_version` | Kubernetes version | `1.28` | No |
| `domain_name` | Domain name for the application | `garuooo.com` | No |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` | No |
| `enable_cluster_encryption` | Enable cluster encryption | `true` | No |
| `enable_karpenter` | Enable Karpenter | `true` | No |

### Node Group Configuration

#### Application Node Group
- **Purpose**: Run microservice application workloads
- **Instance Types**: t3.large, t3.xlarge, m5.large, m5.xlarge
- **Scaling**: 2-10 nodes (desired: 3)
- **Storage**: 50GB GP3 volumes
- **Labels**: Purpose=application-workloads

#### General Node Group
- **Purpose**: Run general infrastructure workloads
- **Instance Types**: t3.medium, t3.large, m5.medium, m5.large
- **Scaling**: 1-5 nodes (desired: 2)
- **Storage**: 30GB GP3 volumes
- **Labels**: Purpose=general-workloads

### Storage Configuration

| Service | Bucket | Retention | Purpose |
|---------|--------|-----------|---------|
| Application Data | `{cluster_name}-application-data` | 90 days | Application data storage |
| Application Logs | `{cluster_name}-application-logs` | 30 days | Application logs storage |

## Security Features

- **Cluster Encryption**: EKS secrets encrypted with KMS
- **IRSA**: IAM Roles for Service Accounts for secure AWS access
- **VPC Flow Logs**: Network traffic monitoring
- **S3 Encryption**: All storage buckets encrypted
- **Node Security**: Proper IAM roles and security groups

## Monitoring and Logging

- **Cluster Logging**: API, audit, authenticator, controller, scheduler logs
- **VPC Flow Logs**: Network traffic analysis
- **CloudWatch**: Centralized logging and monitoring
- **Node Monitoring**: CloudWatch agent on all nodes

## Cost Optimization

- **Single NAT Gateway**: Cost-optimized for production
- **Spot Instances**: Supported via Karpenter
- **Right-sizing**: Appropriate instance types for production
- **Storage Lifecycle**: Automatic cleanup of old data

## Microservice Deployment

### 1. Deploy Application Services

```bash
# Create namespace for your application
kubectl create namespace microservice-app

# Deploy your microservices
kubectl apply -f k8s/
```

### 2. Configure Ingress

```bash
# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=microservice-production \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 3. Deploy Ingress Resources

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservice-ingress
  namespace: microservice-app
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: ${production_certificate_arn}
spec:
  rules:
  - host: api.garuooo.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: microservice-api
            port:
              number: 80
```

## Troubleshooting

### Common Issues

1. **Cluster Access Denied**
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Update kubeconfig
   aws eks update-kubeconfig --region eu-central-1 --name microservice-production
   ```

2. **Node Group Scaling Issues**
   ```bash
   # Check node group status
   aws eks describe-nodegroup --cluster-name microservice-production --nodegroup-name application
   ```

3. **S3 Access Issues**
   ```bash
   # Check IRSA role bindings
   kubectl get serviceaccounts -n default
   kubectl describe serviceaccount application-sa -n default
   ```

### Useful Commands

```bash
# Get cluster information
terraform output

# Check cluster status
aws eks describe-cluster --name microservice-production

# List node groups
aws eks list-nodegroups --cluster-name microservice-production

# Check S3 buckets
aws s3 ls | grep microservice-production

# View cluster logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks/microservice-production
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all resources including data in S3 buckets. Make sure to backup any important data before running destroy.

## Next Steps

After the infrastructure is deployed:

1. **Deploy Microservices**: Use Helm charts or kubectl to deploy your microservices
2. **Configure Monitoring**: Set up Prometheus, Grafana, or other monitoring tools
3. **Set up CI/CD**: Configure deployment pipelines
4. **Configure DNS**: Point your domain to the ALB
5. **Set up Logging**: Configure centralized logging for your applications

## Support

For issues and questions:
- Check the [Terraform AWS EKS Module documentation](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- Review AWS EKS documentation
- Check the module README files in `../../modules/AWS/`
