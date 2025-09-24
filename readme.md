## Project Startup Guide

### Architecture Overview
This project provisions a production-grade EKS environment designed around two workload classes, automated node provisioning with Karpenter, and GitOps for application delivery.

- General vs Application workloads
  - General workloads: run on a self-managed node group labeled for general-purpose tasks and controller add-ons. These nodes carry labels like `Purpose=general-workloads` and are suitable for shared services, controllers, and baseline components.
  - Application workloads: run on a dedicated self-managed node group labeled `Purpose=application-workloads` and tainted with `type=application-workloads:NoSchedule`. Only pods that tolerate this taint will schedule here, isolating prod application traffic from general system components.

- Scheduling and isolation
  - Pods targeting application capacity should use `tolerations` for `type=application-workloads:NoSchedule` and optionally node `affinity`/`nodeSelector` for `Purpose=application-workloads`.
  - General pods do not have this toleration and thus stay off the application nodes.

- Autoscaling with Karpenter
  - Karpenter discovers the cluster via `karpenter.sh/discovery=<cluster_name>` subnet tags and IRSA.
  - It rapidly provisions right-sized instances in response to pending pods and scales down underutilized capacity.
  - Spot-first utilization: for cost efficiency, non-critical workloads should prefer Spot capacity. Karpenter replaces interrupted Spot nodes quickly and can fall back to On-Demand when Spot is unavailable to improve resilience.

- Node pools
  - `general` node group: shared services, controllers, and baseline system components.
  - `application` node group: tainted and labeled for production application workloads, isolated from general services.

- Application scalability and reliability
  - Horizontal Pod Autoscaler (HPA) is configured for the microservice to scale pods based on resource metrics: `task/k8s/production/microservice/hpa.yaml`.
  - Pod Disruption Budget (PDB) ensures a minimum number of replicas remain available during voluntary disruptions: `task/k8s/production/microservice/pdb.yaml`.

- Monitoring and observability
  - `kube-prometheus-stack` (Prometheus, Alertmanager, Grafana) is installed via GitOps.
  - Helm values are under `task/k8s/production/helm-values/kube-prometheus-stack.yaml` and the Argo CD Application is under `task/argocd/production/kube-prometheus-stack.yaml`.
  - Metrics from the microservice can be scraped using `ServiceMonitor`/`PodMonitor` resources; dashboards and alerts are managed through the stack.

- Multi-environment overlays
  - Terraform environments live under `task/terraform/live/{development,staging,production}` with separate state backends and variables per environment.
  - Kubernetes manifests follow environment overlays under `task/k8s/{development,staging,production}/...` with environment-specific values in `helm-values/`.
  - Argo CD Applications are defined per environment under `task/argocd/{development,staging,production}/` so each cluster syncs only its own overlay.
  - To add a new environment, copy the relevant `production` folders to a new overlay, adjust backend bucket/key, variables, Helm values, and Argo CD repo/path references, then run the matching CI/CD workflows.

- Storage and networking
  - EBS CSI driver (via IRSA) provides dynamic persistent volumes.
  - AWS Load Balancer Controller exposes services using ALB/NLB as needed.

- GitOps and operations
  - Terraform sets up the base infrastructure (VPC, EKS, IRSA roles, ECR, node groups).
  - CI/CD pipelines (plan/apply/destroy) use GitHub OIDC with least operational friction.
  - Argo CD syncs Kubernetes manifests from Git to the cluster for a fully declarative workflow.

### 0) Build and use the tooling Docker image (bundled Terraform/AWS/kubectl/ArgoCD)
This repository includes a ready-to-use Docker image with Terraform, AWS CLI, kubectl, and ArgoCD CLI preinstalled to simplify setup.

```bash
# From the repo root
docker build -t infra-toolbox -f task/Dockerfile .

# Run an interactive shell with your workspace mounted
docker run -it --rm \
  -e AWS_REGION="us-east-1" \
  -e AWS_ACCESS_KEY_ID={KEY_ID} \
  -e AWS_SECRET_ACCESS_KEY={SECRET_TOKEN} \
  -v "$(pwd)/task":/workspace/task \
  infra-toolbox bash

# Inside the container, verify tools
terraform version
aws --version
kubectl version --client --output yaml
argocd version --client
```

Tip: You can run all following commands inside this container for a consistent environment.

This document walks you through provisioning AWS infrastructure with Terraform, configuring EKS access, installing Argo CD, connecting your Git repository, building and pushing the microservice image to ECR, and deploying the application via GitOps.

### 1) Prerequisites
- Tools: AWS CLI v2, Terraform ≥ 1.3, kubectl, Docker, ArgoCD CLI
- Accounts: AWS account, GitHub repository (fork/clone of this project)
- Set these shell variables (adjust values):
```bash
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID=your_account_id
export OWNER="<your_github_username_or_org>"
export REPO="<your_repo_name>"
```

### 2) Terraform State Backend (S3)
Use a globally unique bucket name.
```bash
export STATE_BUCKET="tf-state-task-123"
aws s3api create-bucket --bucket "$STATE_BUCKET" --region "$AWS_REGION"
aws s3api put-bucket-versioning --bucket "$STATE_BUCKET" --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$STATE_BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

Configure your Terraform backend to use this bucket if not already configured.

Where to set the backend bucket/key/region:
- Edit the S3 backend block in `task/terraform/live/production/provider.tf`:
```hcl
terraform {
  backend "s3" {
    bucket = "<your_bucket_name>"
    key    = "production/state/resource.tfstate"
    region = "<your_region>"
    encrypt = true
    use_lockfile = true
  }
}
```

### 3) GitHub OIDC + Terraform IAM Role (for CI/CD)
Create a GitHub OIDC trust policy and an IAM role for the CI/CD pipelines (restrict permissions in real production; Admin is used here for demo simplicity). As a security best practice, avoid long‑lived AWS access keys/tokens for CI—prefer short‑lived, federated credentials via GitHub OIDC.
```bash

# (If not already present) Create the GitHub OIDC provider in your AWS account
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 || true

Create a GitHub OIDC trust policy and an IAM role for the CI/CD pipelines (restrict permissions in real production; Admin is used here for demo simplicity).

cat > trust.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:${OWNER}/${REPO}:ref:refs/heads/*",
            "repo:${OWNER}/${REPO}:ref:refs/tags/*",
            "repo:${OWNER}/${REPO}:environment:*",
            "repo:${OWNER}/${REPO}:pull_request",
            "repo:${OWNER}/${REPO}:workflow_run"
          ]
        }
      }
    }
  ]
}
EOF


aws iam create-role --role-name gha-terraform-prod --assume-role-policy-document file://trust.json
aws iam attach-role-policy --role-name gha-terraform-prod --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```
Add GitHub repo variables/secrets: `AWS_ACCOUNT_ID_PRODUCTION` (and staging/dev variants if applicable).

### 4) CI/CD — Provision via GitHub Actions
To provision infrastructure using the included GitHub Actions pipelines, first add your AWS account ID as a repository variable.

1. In GitHub, go to: Settings → Secrets and variables → Actions → Variables → New repository variable.
2. Create `AWS_ACCOUNT_ID_PRODUCTION` with the value of your AWS account ID.
3. Ensure the IAM role `gha-terraform-prod` exists with the GitHub OIDC trust policy (from Step 3).

Workflows under `task/.github/workflows/` that automate provisioning:
- `prod-plan.yml` (Production Pull Request Planner)
  - Triggers on PRs to `main` affecting `terraform/live/production/**`, or manual run.
  - Performs TFLint, configures AWS via OIDC, runs `terraform init/validate/plan`, and comments the plan on the PR.
- `prod-apply.yml` (Production Terraform apply)
  - Triggers on merged PRs to `main` that touched production IaC, or manual run.
  - Runs `terraform init` and `terraform apply -auto-approve` in `terraform/live/production/` using OIDC.
- `prod-destroy.yml` (Production Terraform destroy)
  - Manual run only; performs TFLint, configures AWS via OIDC, and runs `terraform destroy -auto-approve`.

How to use to get infra up and running:
- Open a PR with your Terraform changes → `prod-plan.yml` posts the plan on the PR.
- Merge the PR → `prod-apply.yml` applies to production automatically.
- Alternatively, manually run either workflow: GitHub → Actions → select workflow → Run workflow.

If you prefer to run locally instead of CI/CD, use the tooling container and continue with Step 5.

### 5) Provision Infrastructure (Terraform)
```bash
cd task/terraform/live/production
terraform init -upgrade
terraform validate
terraform plan -out tf.plan
terraform apply tf.plan
terraform output
terraform output connection_info
```

Key outputs you’ll need later: cluster name, endpoint, OIDC provider, VPC ID, IRSA role ARNs (LBC, Karpenter), etc.

### 6) Configure kubectl for EKS
```bash
aws eks update-kubeconfig --region "$AWS_REGION" --name microservice-production
kubectl get nodes
kubectl get pods -A
```

App image build/push via CI (optional but recommended):
- Use `task/.github/workflows/app-ecr-deploy.yml` to build, test, and push the microservice image to ECR.
  - Triggers: on push to `main` under `Microservices-main/**` and manual `workflow_dispatch`.
  - What it does: runs unit tests, assumes the GitHub OIDC role `gha-terraform-prod`, ensures the ECR repo exists, then builds and pushes both a version tag and `latest`.
  - Requirements: set repo variable `AWS_ACCOUNT_ID_PRODUCTION` and ensure the OIDC role exists (see Step 3).
  - How to run: GitHub → Actions → “App ECR Build and Push” → Run workflow.

If you prefer to build/push locally instead of CI, follow Step 11.

### 7) Update Helm Values (account-specific)
Edit the following files with your account details and Terraform outputs:
- `task/k8s/production/helm-values/aws-lb-controller.yaml`
- `task/k8s/production/helm-values/karpenter.yaml`

Set at minimum:
- `clusterName`
- `region`
- `vpcId`
- `settings.clusterEndpoint`
- IRSA role ARNs for the controllers (Karpenter controller role ARN, AWS Load Balancer Controller role ARN)

Example placeholders to replace (update before applying Argo CD Apps):
```yaml
# task/k8s/production/helm-values/aws-lb-controller.yaml
clusterName: microservice-production                 # <— your EKS cluster name
region: ${AWS_REGION}                                # <— your region
vpcId: vpc-xxxxxxxx                                  # <— your VPC ID
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/microservice-production-aws-lbc  # <— LBC IRSA role ARN ( created with terraform)
```
```yaml
# task/k8s/production/helm-values/karpenter.yaml
settings:
  clusterName: microservice-production                # <— your EKS cluster name
  clusterEndpoint: https://XXXXXXXXXXXXXXXX.gr7.us-east-1.eks.amazonaws.com  # <— from Terraform output
  interruptionQueue: Karpenter-microservice-production # <— optional: update queue name
serviceAccount:
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::${AWS_ACCOUNT_ID}:role/<karpenter-controller-role>  # <— Karpenter IRSA role ARN ( created with terraform )
```

### 8) Install Argo CD
```bash
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```


Login (CLI via port-forward):
```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443 >/dev/null 2>&1 &
export ARGOCD_SERVER=localhost:8080
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
argocd login "$ARGOCD_SERVER" --username admin --password "$ARGOCD_PASSWORD" --insecure
```
UI: open `https://localhost:8080` (user: `admin`, password from above).

### 9) Connect Your Git Repository to Argo CD
- Public repo:
```bash
argocd repo add https://github.com/${OWNER}/${REPO}.git --name task --type git
```
- Private repo (GitHub PAT with Repository contents: Read):
```bash
export GITHUB_TOKEN="<your_pat>"
argocd repo add https://github.com/${OWNER}/${REPO}.git \
  --name task \
  --type git \
  --username "${OWNER}" \
  --password "$GITHUB_TOKEN"
```

How to create a GitHub Personal Access Token (PAT):
- Navigate to GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens (or classic tokens if needed).
- Scope minimally for read-only repository contents on your repo.
- Copy the token once and set it as `GITHUB_TOKEN` when adding the repo above.

### 10) Register Argo CD Applications
Apply existing Application manifests in this repo:
```bash
kubectl apply -f task/argocd/production/

```

Note: If you forked/renamed this repository, ensure Argo CD `Application` manifests under `task/argocd/production/` reference your Git repository URL and the correct `path`.

### 11) Build and Push App Image to ECR
Terraform created an ECR repo named `python-microservice`.
```bash
aws ecr get-login-password --region "$AWS_REGION" \
| docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker build -t python-microservice:v1.0.0 task/Microservices-main
docker tag python-microservice:v1.0.0 ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/python-microservice:v1.0.0
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/python-microservice:v1.0.0
```

CI/CD pipeline (recommended):
- Workflow: `task/.github/workflows/app-ecr-deploy.yml`
- Triggers: push to `main` under `Microservices-main/**` or manual `workflow_dispatch`.
- What it does:
  - Installs deps and runs tests for the app.
  - Assumes AWS via GitHub OIDC (no static keys).
  - Ensures a private ECR repo exists (`python-microservice`).
  - Builds the Docker image and pushes both a resolved version tag and `latest`.
- How to run manually: GitHub → Actions → “App ECR Build and Push” → Run workflow.
- After push: update `task/k8s/production/microservice/deployment.yaml` `image:` tag to the new version and commit; Argo CD will sync and roll out.

Ensure the Kubernetes Deployment references the ECR image/tag:
- `task/k8s/production/microservice/deployment.yaml` → `image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/python-microservice:v1.0.0`

What to change in Deployment (before apply):
```yaml
# task/k8s/production/microservice/deployment.yaml
spec:
  replicas: 3                                  # adjust if needed
  template:
    spec:
      containers:
      - name: python-microservice
        image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/python-microservice:v1.0.0  # <— set to your ECR URL and tag
        ports:
        - containerPort: 5000
```

Finding your ECR image URL:
- Private ECR format: `${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/python-microservice:<tag>`
- You can list images/tags:
```bash
aws ecr describe-images --repository-name python-microservice --query 'imageDetails[].imageTags' --output json
```

CI/CD option (no manual edit):
- The workflow `task/.github/workflows/app-ecr-deploy.yml` builds and pushes the image on changes to `Microservices-main/**`.
- You can either:
  - Pin `deployment.yaml` to a specific version tag you push via CI (recommended), then `argocd app sync` to deploy, or
  - Temporarily use the `latest` tag and let Argo CD pull on sync (less deterministic).
- After CI push, update the `image:` tag in `deployment.yaml` (or use an image updater tool) and commit; Argo CD will reconcile the new version.

### 12) Sync and Verify
- With Argo CD:
```bash
argocd app list
argocd app sync microservice-application
argocd app get microservice-application
```
- Or apply directly with kubectl:
```bash
kubectl apply -f task/k8s/production/microservice/namespace.yaml
kubectl apply -f task/k8s/production/microservice/configmap.yaml
kubectl apply -f task/k8s/production/microservice/deployment.yaml
kubectl apply -f task/k8s/production/microservice/service.yaml
kubectl apply -f task/k8s/production/microservice/ingress.yaml
kubectl apply -f task/k8s/production/microservice/hpa.yaml
kubectl apply -f task/k8s/production/microservice/pdb.yaml

kubectl -n microservice get pods,svc,ingress
kubectl -n microservice logs deploy/python-microservice -f
```

### 13) App Configuration via Env Vars
The Flask app now reads environment variables provided by the Kubernetes `ConfigMap`:
- `FLASK_ENV` → environment mode
- `LOG_LEVEL` → application logging level
- `PORT` → server port

Files:
- `task/k8s/production/microservice/configmap.yaml`
- `task/Microservices-main/app/__init__.py`
- `task/Microservices-main/app/main.py`

### 14) Accessing Services
- Argo CD UI: `https://localhost:8080` (from port-forward above)
- Microservice local test:
```bash
kubectl -n microservice port-forward svc/python-microservice 8081:5000
curl -s http://localhost:8081/health
```

### 15) Troubleshooting
- Argo CD server unspecified: `export ARGOCD_SERVER=localhost:8080` then login
- Docker cannot resolve `*.svc.cluster.local`: use port-forward and `localhost`
- ECR image pull errors: ensure node role has ECR read policy, image exists, tag matches
- Terraform issues: run in `task/terraform/live/production` → `terraform validate && terraform plan`

### 16) CI/CD Notes
- Use the GitHub OIDC role `gha-terraform-prod` (restrict in production)
- Add repo variables/secrets: `AWS_ACCOUNT_ID_PRODUCTION` (+ staging/dev if needed)
- Pipelines: plan on PR, apply on merge, build/push on tag; Argo CD syncs Git changes

#### GitHub Actions pipelines (how to use and how they simplify the process)
The repository includes three ready-to-use workflows under `.github/workflows/` that automate Terraform operations against `terraform/live/production` using GitHub OIDC (no long-lived AWS keys):

- prod-plan.yml (Production Pull Request Planner)
  - Triggers: on PRs to `main` touching `terraform/live/production/**`, and manual `workflow_dispatch`.
  - What it does:
    - Runs TFLint checks on the production workspace and all modules.
    - Configures AWS via OIDC and assumes `arn:aws:iam::${{ vars.AWS_ACCOUNT_ID_PRODUCTION }}:role/gha-terraform-prod`.
    - Runs `terraform init/validate/plan` in `terraform/live/production/`.
    - Posts a formatted plan summary as comments on the PR for easy review.
  - Why it helps: catches issues early, shows diffs directly in the PR, no local tooling needed.

- prod-apply.yml (Production Terraform apply)
  - Triggers: when a PR to `main` is merged (closed with merge) that touches production IaC, and manual `workflow_dispatch`.
  - What it does:
    - Configures AWS via OIDC and assumes the same CI role.
    - Runs `terraform init` and `terraform apply -auto-approve` in `terraform/live/production/`.
  - Why it helps: applies approved changes consistently and audibly after review/merge; no local credentials required.

- prod-destroy.yml (Production Terraform destroy)
  - Triggers: manual `workflow_dispatch` only.
  - What it does:
    - Runs TFLint inspection similarly to the planner.
    - Configures AWS via OIDC and runs `terraform destroy -auto-approve` in `terraform/live/production/`.
  - Why it helps: provides a controlled, auditable way to tear down resources when needed.

Requirements for all workflows:
- Repository variable `AWS_ACCOUNT_ID_PRODUCTION` must be set (Settings → Secrets and variables → Actions → Variables).
- IAM role `gha-terraform-prod` must exist with a trust policy for GitHub OIDC as defined above.

Manual runs (workflow_dispatch):
- GitHub → Actions → select the desired workflow (Plan/Apply/Destroy) → Run workflow.

Manual workflow runs (if defined with `workflow_dispatch`): GitHub → Actions → select workflow → Run workflow.


