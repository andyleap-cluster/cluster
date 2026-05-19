# Kargo OIDC client + RBAC group in Pocket ID.
#
# Unlike ArgoCD, Kargo's OIDC implementation is PKCE-only and doesn't
# use a client_secret -- so this file does NOT create a kubernetes_secret.
# kargo/values.yaml references the client_id directly. We pin the
# client_id input to a stable string so the value can be hardcoded in
# the chart values without the chicken-and-egg of "TF generates an ID
# that values.yaml needs to know at apply time."
#
# Group-based RBAC: members of `kargo-admins` get Kargo admin privileges
# via the chart's api.oidc.admins.claims.groups mapping (no K8s
# ClusterRoleBinding plumbing required -- Kargo does its own RBAC
# internally from the OIDC claims).

resource "pocketid_group" "kargo_admins" {
  name          = "kargo-admins"
  friendly_name = "Kargo Admins"
}

resource "pocketid_client" "kargo" {
  name = "Kargo"

  # NB: do not set `client_id` here -- the trozz/pocketid provider
  # sends it as JSON `clientId`, but Pocket ID's API expects `id`,
  # so the custom value is silently ignored and Pocket ID
  # auto-generates a UUID instead. The auto-generated value is
  # exposed via `.id` and threaded into the Secret below.

  # Kargo's UI sets redirect_uri = window.location.origin + pathname at
  # login-click time, which is typically /login. Register both /login
  # and / so deep-link users coming through the auth gate still match.
  callback_urls = [
    "https://kargo.andyleap.dev/login",
    "https://kargo.andyleap.dev/",
  ]

  logout_callback_urls = [
    "https://kargo.andyleap.dev/login",
  ]

  is_public    = true
  pkce_enabled = true
  launch_url   = "https://kargo.andyleap.dev"
}

# Override the OIDC_CLIENT_ID env var that the chart emits into the
# kargo-api ConfigMap. Kargo's chart concatenates api.envFrom AFTER
# its built-in configmap/secret entries, and pod env merging makes
# the later source win on key collisions -- so mounting this Secret
# via api.envFrom in kargo/values.yaml swaps the placeholder for
# Pocket ID's actual auto-generated client id.
resource "kubernetes_secret" "kargo_oidc" {
  metadata {
    name      = "kargo-oidc"
    namespace = "kargo"
  }

  data = {
    OIDC_CLIENT_ID = pocketid_client.kargo.id
  }
}
