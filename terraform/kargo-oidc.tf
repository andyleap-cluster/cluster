# Kargo OIDC client + RBAC group in Pocket ID, plus the kargo-oidc
# Secret that threads Pocket ID's auto-generated client ID into the
# Kargo API Deployment.
#
# Kargo's OIDC is PKCE-only -- no client_secret to manage. We'd
# normally pin a stable custom client_id ("kargo") so values.yaml
# could hardcode it, but the trozz/pocketid provider sends the
# custom field under JSON `clientId` while Pocket ID's API expects
# `id`, so the custom value is silently ignored and Pocket ID
# auto-generates a UUID instead. To avoid hardcoding that UUID in
# values.yaml, we write it into a Secret that the chart mounts via
# api.envFrom; pod env merging makes the Secret's OIDC_CLIENT_ID
# override the placeholder the chart emits into kargo-api's
# ConfigMap.
#
# Group-based RBAC: members of `kargo-admins` get Kargo admin
# privileges, members of `kargo-viewers` get read-only access to all
# Kargo resources. Both flow through the chart's api.oidc.admins /
# api.oidc.viewers `claims.groups` mappings -- no K8s
# ClusterRoleBinding plumbing required, Kargo does its own RBAC
# internally from the OIDC claims and impersonates the matching
# system-role ServiceAccount the chart renders for each tier.

resource "pocketid_group" "kargo_admins" {
  name          = "kargo-admins"
  friendly_name = "Kargo Admins"
}

resource "pocketid_group" "kargo_viewers" {
  name          = "kargo-viewers"
  friendly_name = "Kargo Viewers"
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
