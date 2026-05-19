# ArgoCD OIDC client + RBAC group in Pocket ID, and the matching
# kubernetes_secret that argocd-server reads via $<secret>:<key>
# references in argocd-cm.
#
# Group-based RBAC: argocd-admins members get role:admin in ArgoCD.
# Add yourself to the group manually via Pocket ID's UI -- the
# provider has no data source for existing users and we don't want
# to import the bootstrap-created passkey user into TF state.

resource "pocketid_group" "argocd_admins" {
  name          = "argocd-admins"
  friendly_name = "ArgoCD Admins"
}

resource "pocketid_client" "argocd" {
  name = "ArgoCD"

  callback_urls = [
    "https://argocd.andyleap.dev/auth/callback",
    # CLI / PKCE flow callback (argocd login --sso)
    "http://localhost:8085/auth/callback",
  ]

  logout_callback_urls = [
    "https://argocd.andyleap.dev",
  ]

  is_public    = false
  pkce_enabled = true
  launch_url   = "https://argocd.andyleap.dev"
}

# argocd-server reads $argocd-oidc:<key> references in the argocd-cm
# ConfigMap from this Secret.
resource "kubernetes_secret" "argocd_oidc" {
  metadata {
    name      = "argocd-oidc"
    namespace = "argocd"
    # ArgoCD only follows references to Secrets carrying this label.
    labels = {
      "app.kubernetes.io/part-of" = "argocd"
    }
  }

  data = {
    clientID     = pocketid_client.argocd.client_id
    clientSecret = pocketid_client.argocd.client_secret
  }
}
