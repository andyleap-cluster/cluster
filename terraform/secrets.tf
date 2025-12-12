# Kubernetes secrets for cluster services

# Create a Linode API token with minimal scope for cert-manager DNS-01 challenges
resource "linode_token" "cert_manager" {
  label  = "cert-manager-dns"
  scopes = "domains:read_write"
}

# Create Kubernetes secret for cert-manager webhook to access Linode DNS API
# The webhook expects secret name "linode-credentials" with key "token"
resource "kubernetes_secret" "cert_manager_linode" {
  metadata {
    name      = "linode-credentials"
    namespace = "cert-manager"
  }

  data = {
    "token" = linode_token.cert_manager.token
  }
}
