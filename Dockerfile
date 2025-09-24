# Terraform Testing Image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TERRAFORM_VERSION=1.13.3
ENV AWS_CLI_VERSION=2.15.1
ENV KUBECTL_VERSION=1.28.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    jq \
    ca-certificates \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Detect architecture and set variables
# dpkg --print-architecture returns amd64 or arm64 on Ubuntu
# Map to vendor-specific arch identifiers
RUN ARCH=$(dpkg --print-architecture) \
 && if [ "$ARCH" = "amd64" ]; then \
      TF_ARCH=linux_amd64; \
      AWS_ARCH=x86_64; \
      KUBE_ARCH=amd64; \
    elif [ "$ARCH" = "arm64" ]; then \
      TF_ARCH=linux_arm64; \
      AWS_ARCH=aarch64; \
      KUBE_ARCH=arm64; \
    else \
      echo "Unsupported architecture: $ARCH" >&2; exit 1; \
    fi \
 # Install Terraform
 && wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TF_ARCH}.zip \
 && unzip terraform_${TERRAFORM_VERSION}_${TF_ARCH}.zip \
 && mv terraform /usr/local/bin/ \
 && rm -f terraform_${TERRAFORM_VERSION}_${TF_ARCH}.zip \
 # Install AWS CLI v2
 && curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip \
 && ./aws/install \
 && rm -rf aws awscliv2.zip \
 # Install kubectl
 && curl -sSLo kubectl "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${KUBE_ARCH}/kubectl" \
 && chmod +x kubectl \
 && mv kubectl /usr/local/bin/ \
# Install ArgoCD CLI
 && curl -sSL -o argocd-linux-${KUBE_ARCH} https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${KUBE_ARCH} \
 && chmod +x argocd-linux-${KUBE_ARCH} \
 && mv argocd-linux-${KUBE_ARCH} /usr/local/bin/argocd

# Install testing tools
RUN pip3 install boto3

# Create working directory
WORKDIR /workspace

# Copy Terraform configurations
COPY terraform/ /workspace/terraform/

# Create a simple entrypoint that allows command line usage
RUN echo '#!/bin/bash\nif [ "$1" = "bash" ] || [ "$1" = "sh" ]; then\n    exec "$@"\nelse\n    echo "🚀 Terraform Testing Container Ready!"\n    echo "Available commands:"\n    echo "  terraform --help"\n    echo "  aws --help"\n    echo "  kubectl --help"\n    echo ""\n    echo "To get a shell, run: docker exec -it <container> bash"\n    echo "To test AWS: aws sts get-caller-identity"\n    echo "To test Terraform: terraform version"\n    echo "To validate environments: cd /workspace/terraform/live/<env> && terraform init -backend=false && terraform validate"\n    exec "$@"\nfi' > /workspace/entrypoint.sh && chmod +x /workspace/entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/workspace/entrypoint.sh"]

# Default command
CMD ["bash"]


