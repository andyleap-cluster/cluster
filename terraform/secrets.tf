# Kubernetes secrets for cluster services

# Create a Linode API token with minimal scope for cert-manager DNS-01 challenges
resource "linode_token" "cert_manager" {
  label  = "cert-manager-dns"
  scopes = "domains:read_write"
}

# Create Kubernetes secret for cert-manager to access Linode DNS API
resource "kubernetes_secret" "cert_manager_linode" {
  metadata {
    name      = "linode-dns-token"
    namespace = "cert-manager"
  }

  data = {
    "api-token" = linode_token.cert_manager.token
  }
}
