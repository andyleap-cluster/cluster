# Kubernetes secrets for cluster services

# Singress (TLS certificate management)
resource "kubernetes_secret" "singress_api_token" {
  metadata {
    name      = "singress-api-token"
    namespace = "linode"
  }

  data = {
    key    = linode_object_storage_key.singress.access_key
    secret = linode_object_storage_key.singress.secret_key
  }

  type = "Opaque"
}

# LKEDNS (DNS management)
resource "kubernetes_secret" "lkedns_api_token" {
  metadata {
    name      = "lkedns-api-token"
    namespace = "linode"
  }

  data = {
    token = linode_token.lkedns.token
  }

  type = "Opaque"
}

# Auth service (Object storage access)
resource "kubernetes_secret" "auth_api_token" {
  metadata {
    name      = "auth-api-token"
    namespace = "auth"
  }

  data = {
    key    = linode_object_storage_key.auth.access_key
    secret = linode_object_storage_key.auth.secret_key
  }

  type = "Opaque"
}

