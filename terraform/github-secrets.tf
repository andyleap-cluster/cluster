# Data source to get repository information
data "github_repository" "repo" {
  full_name = "andyleap-cluster/cluster"
}

# Create an administrative token for GitHub Actions
resource "linode_token" "github_actions" {
  label  = "github-actions-production"
  scopes = "account:read_write databases:read_write domains:read_write events:read_only firewall:read_write images:read_write ips:read_write linodes:read_write lke:read_write longview:read_write nodebalancers:read_write object_storage:read_write stackscripts:read_write volumes:read_write"
}

# Create GitHub repository secrets for the workflow
resource "github_actions_secret" "linode_token" {
  repository      = data.github_repository.repo.name
  secret_name     = "LINODE_TOKEN"
  plaintext_value = linode_token.github_actions.token
}

# S3 access keys for terraform state backend
resource "github_actions_secret" "linode_s3_access_key" {
  repository      = data.github_repository.repo.name
  secret_name     = "LINODE_S3_ACCESS_KEY"
  plaintext_value = linode_object_storage_key.terraform_state.access_key
}

resource "github_actions_secret" "linode_s3_secret_key" {
  repository      = data.github_repository.repo.name
  secret_name     = "LINODE_S3_SECRET_KEY"
  plaintext_value = linode_object_storage_key.terraform_state.secret_key
}

# Create object storage key for terraform state access
resource "linode_object_storage_key" "terraform_state" {
  label = "terraform-state-production"

  bucket_access {
    bucket_name = "andyleap-dev-tf"
    region      = "us-sea"
    permissions = "read_write"
  }

  depends_on = [linode_object_storage_bucket.terraform_state]
}

# Kubeconfig for cluster access
resource "github_actions_secret" "kubeconfig" {
  repository      = data.github_repository.repo.name
  secret_name     = "KUBECONFIG_CONTENT"
  plaintext_value = base64decode(linode_lke_cluster.cluster.kubeconfig)
}