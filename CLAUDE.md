# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a Kubernetes cluster configuration repository that uses GitOps with ArgoCD for deployment. The repository is structured around self-managing Kubernetes applications deployed via ArgoCD.

### Key Components

- **ArgoCD**: GitOps controller that automatically deploys applications from this repository
- **Kustomize**: Used for templating and customizing Kubernetes resources
- **OpenTofu/Terraform**: Infrastructure as Code for Linode resources and Kubernetes secrets
- **Application Modules**: Individual services organized in directories (auth, redis, sshsweeper, etc.)
- **Infrastructure Components**: Linode-specific resources and ingress controllers

### Directory Structure

```
cluster/              # ArgoCD Application manifests for cluster components
├── cluster.yaml      # Self-managing ArgoCD application
├── argocd.yaml       # ArgoCD application manifest
├── auth.yaml         # Auth service application manifest
├── redis.yaml        # Redis application manifest
├── sshsweeper.yaml   # SSHSweeper application manifest
└── linode.yaml       # Linode components application manifest

[service]/            # Individual service directories
├── kustomization.yaml # Kustomize configuration
├── deployment.yaml   # Kubernetes Deployment manifest
├── service.yaml      # Kubernetes Service manifest
└── [other].yaml      # Additional Kubernetes resources

terraform/            # Infrastructure as Code
├── main.tf           # Main Terraform configuration
├── object-storage.tf # Linode Object Storage buckets and keys
├── secrets.tf        # Kubernetes secrets managed by Terraform
└── ...               # Other infrastructure components
```

## Development Workflow

### Infrastructure Changes (Terraform/OpenTofu)

Infrastructure changes are managed via OpenTofu and automated through GitHub Actions:

1. **Create Pull Request**: Changes to `terraform/` directory trigger OpenTofu workflow
2. **Plan Phase**: GitHub Action runs `tofu plan` and posts results to PR
3. **Review and Approve**: Review the plan output in PR comments
4. **Apply Phase**: After PR approval, `tofu apply` runs automatically
5. **State Storage**: Terraform state is stored in Linode Object Storage (S3-compatible)

```bash
# Local development (if needed)
cd terraform/
tofu init
tofu plan
tofu apply  # Only run locally for testing, use GitHub Actions for production
```

### Application Changes (GitOps)

All application changes must be made via Pull Requests from feature branches:

1. **Create Feature Branch**: Always branch off `master` for any changes
2. **Make Changes**: Update application configurations, deployments, services, etc.
3. **Create Pull Request**: Submit PR against `master` branch
4. **Review and Merge**: After review, changes are automatically applied by ArgoCD

```bash
# Create feature branch from master
git checkout master
git pull origin master
git checkout -b feature/my-change

# Make your changes
# ...

# Commit and push
git add .
git commit -m "Description of changes"
git push -u origin feature/my-change

# Create PR via GitHub CLI or web interface
gh pr create --title "My Change" --body "Description"

# Preview Kustomize output (optional)
kubectl kustomize [service]/
```

**Important**: Never commit directly to `master`. All changes must go through the PR process.

### ArgoCD Management

The cluster uses ArgoCD for automated deployment. ArgoCD applications are defined in the `cluster/` directory and automatically sync from this repository.

```bash
# View ArgoCD applications (if argocd CLI available)
argocd app list
argocd app sync [app-name]
```

### Working with Kustomize

All services use Kustomize for resource templating and customization:

- **Kustomization Files**: `[service]/kustomization.yaml` in each service directory
- **Base Resources**: Standard Kubernetes YAML manifests (deployment.yaml, service.yaml, etc.)
- **Customizations**: Image tags/digests, labels, namespaces, and patches
- **ArgoCD Special Case**: Uses upstream ArgoCD Kustomize base from GitHub

Use `kubectl kustomize [service]/` to preview generated manifests. Each service directory contains its own kustomization.yaml file that references the required resource files.

### Container Images

Services reference container images:
- Directly in YAML manifests with SHA256 digests (e.g., `blog/blog.yaml`)
- Via Kustomize image transformations in `kustomization.yaml` files

### Key Services

All services use Kustomize for configuration management:

- **ArgoCD**: GitOps controller using upstream Kustomize base
- **Auth**: Passkey authentication service with Redis session storage and S3 data storage (auth.andyleap.dev)
- **Redis**: Redis server for session storage (auth namespace)
- **SSHSweeper**: SSH service with custom private key mounting
- **Singress**: Custom ingress controller with TLS certificate management (in linode/)
- **Linode**: Linode-specific networking and DNS components (LKE DNS, ExtRoute)

### Secrets Management

Secrets are managed by Terraform/OpenTofu and automatically created in the cluster:
- **Object Storage Access**: `singress-api-token`, `auth-api-token` (Linode Object Storage credentials)
- **DNS Management**: `lkedns-api-token` (Linode API token)
- **Location**: Secrets are created in appropriate namespaces by Terraform
- **Rotation**: Update secrets by modifying Terraform configuration and applying

### Service Routing

External routing is handled by the Singress ingress controller:
- Services use the `git.andyleap.dev/singress-target` annotation to specify their external domain
- Singress automatically provisions TLS certificates and stores them in S3
- Examples: `auth.andyleap.dev` (Auth service), `argocd.andyleap.dev` (ArgoCD)

### GitHub Actions Workflow

The repository uses GitHub Actions for automated infrastructure management:

- **Trigger**: Pull requests to master branch with changes in `terraform/` directory
- **Plan**: OpenTofu plan runs and posts results as PR comments
- **Apply**: After PR approval, OpenTofu apply runs automatically
- **State Management**: Plans are stored/retrieved from Linode Object Storage for consistency
- **Security**: Uses environment protection for apply phase requiring approval

## Important Notes

- **Pull Request Workflow**: ALL changes must be made via Pull Requests from feature branches - never commit directly to master
- **GitOps**: Application changes are applied automatically by ArgoCD after PR merge to master
- **Infrastructure**: Infrastructure changes require PR approval and use OpenTofu GitHub Action
- **Container Images**: Use SHA256 digests for immutable deployments via Kustomize image transformations
- **High Availability**: Services use rolling update strategies
- **Self-Managing**: The cluster self-manages via the `cluster/cluster.yaml` ArgoCD application
- **Modular Design**: Each service directory is self-contained with its own Kustomize configuration
- **Revision History**: Deployments use `revisionHistoryLimit: 1` to keep only current revision