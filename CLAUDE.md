# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a Kubernetes cluster configuration repository that uses GitOps with ArgoCD for deployment. The repository is structured around self-managing Kubernetes applications deployed via ArgoCD.

### Key Components

- **ArgoCD**: GitOps controller that automatically deploys applications from this repository
- **Kustomize**: Used for templating and customizing Kubernetes resources
- **Application Modules**: Individual services organized in directories (blog, database, sshsweeper, etc.)
- **Infrastructure Components**: Linode-specific resources, metrics-server, and ingress controllers

### Directory Structure

```
cluster/              # ArgoCD Application manifests for cluster components
├── cluster.yaml      # Self-managing ArgoCD application
├── database.yaml     # Database application manifest
├── blog.yaml         # Blog application manifest
└── ...

[service]/            # Individual service directories
├── kustomization.yaml # Kustomize configuration
├── deployment.yaml   # Kubernetes Deployment manifest
├── service.yaml      # Kubernetes Service manifest
└── [other].yaml      # Additional Kubernetes resources
```

## Development Workflow

### Applying Changes

Since this is a GitOps repository, changes are applied automatically by ArgoCD when committed to the master branch. Manual application of manifests:

```bash
# Apply specific manifests (if needed for testing)
kubectl apply -f cluster/
kubectl apply -f database/
kubectl apply -k [service]/  # For Kustomize-based services

# Preview Kustomize output
kubectl kustomize [service]/
```

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

All services now use Kustomize for configuration management:

- **ArgoCD**: GitOps controller using upstream Kustomize base
- **Database**: PostgreSQL deployment with persistent storage and pgAdmin
- **Blog**: Web application with S3 integration for static assets  
- **SSHSweeper**: SSH service with custom private key mounting
- **Singress**: Custom ingress controller with TLS certificate management (in linode/)
- **Static**: Static file serving with S3 backend
- **Kube-system**: Metrics server and other system components
- **Linode**: Linode-specific networking and DNS components

### Secrets Management

Services use Kubernetes secrets for sensitive configuration:
- Database credentials (`postgres-secret`)
- S3 API tokens (`s3-api-token`, `singress-api-token`) 
- Application-specific secrets (`blog-pg`)

## Important Notes

- All changes should be committed to trigger ArgoCD sync
- Container images use SHA256 digests for immutable deployments via Kustomize image transformations
- Services are designed to be highly available with rolling update strategies
- The cluster self-manages via the `cluster/cluster.yaml` ArgoCD application
- ArgoCD itself is deployed using the upstream Kustomize base for better maintainability
- Each service directory is self-contained with its own Kustomize configuration