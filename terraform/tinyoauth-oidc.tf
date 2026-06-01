# OIDC client + admin group for TinyOAuth's own authenticated /debug page.
#
# Unlike the per-app forward-auth clients (e.g. simplelog), this one logs an
# admin into tinyoauth *itself*. tinyoauth exposes a synthetic "self app"
# (reserved key _self_/_self_) that reuses the normal /start -> /callback flow,
# gated to an admin group. The client_id is threaded into tinyoauth as
# TINYOAUTH_ADMIN_CLIENT_ID (see tinyoauth.tf); the allowed group is set
# non-secret in ../tinyoauth/configmap.yaml as admin_groups.
#
# Mechanics mirror terraform/simplelog.tf: PKCE-only public client, no
# client_secret (tinyoauth authenticates the token exchange with an RFC 7523
# JWT-bearer assertion signed by its Kubernetes ServiceAccount token). The
# OAuth callback is served by tinyoauth on its shared auth host.

# Only members of tinyoauth-admins may view /debug. Membership is assigned in
# the Pocket ID UI; tinyoauth fails closed (/debug returns 404) if the group is
# empty of the logged-in user.
resource "pocketid_group" "tinyoauth_admins" {
  name          = "tinyoauth-admins"
  friendly_name = "TinyOAuth Admins"
}

# NB: do not set `client_id` here -- the trozz/pocketid provider sends it as
# JSON `clientId`, but Pocket ID's API expects `id`, so the custom value is
# silently ignored and Pocket ID auto-generates a UUID instead. The
# auto-generated value is exposed via `.id` and threaded into the Secret in
# tinyoauth.tf.
resource "pocketid_client" "tinyoauth_debug" {
  name = "TinyOAuth Debug"

  callback_urls = [
    "https://auth.andyleap.dev/callback",
  ]

  logout_callback_urls = [
    "https://auth.andyleap.dev/sign_out",
  ]

  is_public    = true
  pkce_enabled = true
  launch_url   = "https://auth.andyleap.dev/debug"
}
