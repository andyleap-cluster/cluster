# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a Kubernetes cluster configuration repository that uses GitOps with ArgoCD for deployment. The repository is structured around self-managing Kubernetes applications deployed via ArgoCD.

### Key Components

- **ArgoCD**: GitOps controller that automatically deploys applications from this repository
- **Traefik**: Ingress controller with automatic Let's Encrypt TLS
- **Kustomize**: Used for templating and customizing Kubernetes resources
- **OpenTofu/Terraform**: Infrastructure as Code for Linode resources

### Directory Structure

```
cluster/              # ArgoCD Application manifests for cluster components
├── cluster.yaml      # Self-managing ArgoCD application
├── argocd.yaml       # ArgoCD application manifest
└── traefik.yaml      # Traefik ingress controller application

argocd/               # ArgoCD configuration
└── kustomization.yaml

traefik/              # Traefik ingress controller
├── kustomization.yaml
├── namespace.yaml
├── crds.yaml         # Traefik CRDs (IngressRoute, Middleware, etc.)
├── rbac.yaml         # ServiceAccount, ClusterRole, ClusterRoleBinding
├── deployment.yaml   # Traefik deployment
├── service.yaml      # LoadBalancer service
└── ingressroute-argocd.yaml  # IngressRoute for ArgoCD UI

terraform/            # Infrastructure as Code
├── main.tf           # Main Terraform configuration
├── providers.tf      # Provider configuration
├── lke.tf            # Linode Kubernetes Engine cluster
├── dns.tf            # DNS zone and records
├── object-storage.tf # Terraform state bucket
├── secrets.tf        # Kubernetes secrets (currently empty)
└── github-secrets.tf # GitHub Actions secrets
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

Use `kubectl kustomize [service]/` to preview generated manifests.

### Deployment Best Practices

When creating or modifying deployments, follow these practices:

- **Revision History**: Use `revisionHistoryLimit: 1` to keep only current revision and reduce cluster resource usage
- **Resource Limits**: Always set appropriate resource requests and limits
- **Security Hardening**: Drop all capabilities with `capabilities.drop: ALL` and set `allowPrivilegeEscalation: false`

### Key Services

- **ArgoCD**: GitOps controller using upstream Kustomize base (argocd.andyleap.dev)
- **Traefik**: Ingress controller with automatic Let's Encrypt TLS certificates

### Service Routing

External routing is handled by Traefik:
- Services use Traefik `IngressRoute` CRDs to define routing rules
- TLS certificates are automatically provisioned via Let's Encrypt ACME
- Example: `argocd.andyleap.dev` routes to the ArgoCD server

To add a new service with external access:
1. Create an `IngressRoute` resource in the service's namespace
2. Specify the `Host()` match rule and target service
3. Use `certResolver: letsencrypt` for automatic TLS

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
- **Self-Managing**: The cluster self-manages via the `cluster/cluster.yaml` ArgoCD application
- **Modular Design**: Each service directory is self-contained with its own Kustomize configuration
- **Revision History**: Deployments use `revisionHistoryLimit: 1` to keep only current revision
