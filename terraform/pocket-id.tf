# Pocket ID bootstrap secret
#
# ENCRYPTION_KEY is set ONCE at first deploy and must NEVER change
# (rotating it would render existing encrypted-at-rest data unrecoverable).
# Terraform owns it via random_password so the state is the source of
# truth across rebuilds and the operator never has to touch it.
#
# The pocket-id ArgoCD Application has CreateNamespace=true so it can
# create the namespace if Terraform hasn't yet. The kubernetes_namespace
# resource here is just to make TF apply idempotent regardless of
# ordering.

resource "kubernetes_namespace" "pocket_id" {
  metadata {
    name = "pocket-id"
  }
}

resource "random_password" "pocket_id_encryption_key" {
  length  = 32
  special = false
}

# Pocket ID reads its config from env vars; the StatefulSet wires this
# Secret via envFrom so each key becomes its own env var.
resource "kubernetes_secret" "pocket_id_bootstrap" {
  metadata {
    name      = "pocket-id-bootstrap"
    namespace = kubernetes_namespace.pocket_id.metadata[0].name
  }

  data = {
    ENCRYPTION_KEY = random_password.pocket_id_encryption_key.result
  }
}
