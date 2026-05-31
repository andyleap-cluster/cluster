# simplelog: a self-hosted log aggregator. The agent DaemonSet ships container
# logs to the manager, which archives them to a Linode Object Storage bucket
# (the only durable store — no PVC; the manager rebuilds its catalog from S3 on
# startup). LKE block-storage volumes have a per-volume minimum size that makes
# them expensive for this kind of workload.
#
# The query UI has no built-in auth, so it's fronted by the TinyOAuth
# ForwardAuth bouncer + a Pocket ID OIDC client (mirrors terraform/kargo-oidc.tf).
# The K8s manifests live in ../simplelog and are deployed by ArgoCD; this file
# owns only the namespace, the S3 bucket/credentials Secret, and the OIDC
# client/group + the Terraform-owned tinyoauth config-ref ConfigMap.

resource "kubernetes_namespace" "simplelog" {
  metadata {
    name = "simplelog"
  }
}

resource "linode_object_storage_bucket" "simplelog" {
  region = "us-sea"
  label  = "andyleap-dev-simplelog"
  acl    = "private"
}

resource "linode_object_storage_key" "simplelog" {
  label = "simplelog"
  bucket_access {
    bucket_name = linode_object_storage_bucket.simplelog.label
    region      = "us-sea"
    permissions = "read_write"
  }
}

# Only the S3 credentials are secret. The non-secret S3 settings
# (bucket/domain/region/protocol/pathStyle) live in
# ../simplelog/manager-config.yaml and are merged in via envFrom.
resource "kubernetes_secret" "simplelog_s3" {
  metadata {
    name      = "simplelog-s3"
    namespace = kubernetes_namespace.simplelog.metadata[0].name
  }

  data = {
    SL_S3_ACCESS_KEY = linode_object_storage_key.simplelog.access_key
    SL_S3_SECRET_KEY = linode_object_storage_key.simplelog.secret_key
  }
}

# Group-based access control: only members of simplelog-users may reach the UI
# (enforced by the policy in ../simplelog/tinyoauth-policy.yaml).
resource "pocketid_group" "simplelog_users" {
  name          = "simplelog-users"
  friendly_name = "simplelog Users"
}

# OIDC client for the TinyOAuth bouncer's login flow on behalf of simplelog.
# TinyOAuth is PKCE-only (no client_secret to manage); the config-ref ConfigMap
# carries just the client_id + audience. The OAuth callback is served by
# tinyoauth on its shared auth host, not on logs.andyleap.dev.
#
# NB: do not set `client_id` here -- the trozz/pocketid provider sends it as
# JSON `clientId`, but Pocket ID's API expects `id`, so the custom value is
# silently ignored and Pocket ID auto-generates a UUID instead. The
# auto-generated value is exposed via `.id` and threaded into the ConfigMap below.
resource "pocketid_client" "simplelog" {
  name = "simplelog"

  callback_urls = [
    "https://auth.andyleap.dev/callback",
  ]

  logout_callback_urls = [
    "https://auth.andyleap.dev/sign_out",
  ]

  is_public    = true
  pkce_enabled = true
  launch_url   = "https://logs.andyleap.dev"
}

# Terraform-owned config-ref ConfigMap that the simplelog Middleware references
# via its tinyoauth.andyleap.dev/config-ref annotation. Threads Pocket ID's
# auto-generated client id into the bouncer.
resource "kubernetes_config_map" "tinyoauth_app_simplelog" {
  metadata {
    name      = "tinyoauth-app-simplelog"
    namespace = kubernetes_namespace.simplelog.metadata[0].name
  }

  data = {
    client_id = pocketid_client.simplelog.id
    audience  = "https://id.andyleap.dev"
  }
}
