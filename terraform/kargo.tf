# Kargo cluster credentials
# - SSH deploy key on the cluster repo so Kargo can push to the `live` branch
# - Admin credentials Secret consumed by the kargo-api Deployment

# --- Git deploy key ---------------------------------------------------------

resource "tls_private_key" "kargo_deploy" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "kargo" {
  repository = data.github_repository.repo.name
  title      = "kargo-live-branch-writer"
  key        = tls_private_key.kargo_deploy.public_key_openssh
  read_only  = false
}

resource "kubernetes_secret" "kargo_repo_creds" {
  metadata {
    name      = "cluster-repo-creds"
    namespace = "kargo"
    labels = {
      "kargo.akuity.io/cred-type" = "git"
    }
  }

  data = {
    repoURL       = "git@github.com:andyleap-cluster/cluster.git"
    sshPrivateKey = tls_private_key.kargo_deploy.private_key_openssh
  }
}

# --- Admin credentials ------------------------------------------------------

resource "random_password" "kargo_admin" {
  length  = 24
  special = false
}

resource "htpasswd_password" "kargo_admin" {
  password = random_password.kargo_admin.result
}

resource "random_password" "kargo_admin_token_signing_key" {
  length  = 32
  special = false
}

# Kargo's chart reads this Secret when `api.secret.name` is set in values.
# Keys are the env-var names the kargo-api container loads.
resource "kubernetes_secret" "kargo_api" {
  metadata {
    name      = "kargo-api"
    namespace = "kargo"
  }

  data = {
    ADMIN_ACCOUNT_PASSWORD_HASH     = htpasswd_password.kargo_admin.bcrypt
    ADMIN_ACCOUNT_TOKEN_SIGNING_KEY = random_password.kargo_admin_token_signing_key.result
  }
}

output "kargo_admin_password" {
  value     = random_password.kargo_admin.result
  sensitive = true
  description = "Initial Kargo admin password. Retrieve with: tofu output -raw kargo_admin_password"
}

# Plaintext copy of the admin credentials for easy retrieval via kubectl.
# Not consumed by the chart — kargo-api reads its hash + signing key from
# the `kargo-api` Secret above.
#
#   kubectl -n kargo get secret kargo-admin-credentials \
#     -o jsonpath='{.data.password}' | base64 -d
resource "kubernetes_secret" "kargo_admin_credentials" {
  metadata {
    name      = "kargo-admin-credentials"
    namespace = "kargo"
  }

  data = {
    username = "admin"
    password = random_password.kargo_admin.result
  }
}
