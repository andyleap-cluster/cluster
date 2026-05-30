# TinyOAuth session encryption key. 32 random bytes encoded as 64 hex chars,
# which is what TinyOAuth's AES-256-GCM session codec expects.
resource "random_bytes" "tinyoauth_cookie_secret" {
  length = 32
}

# Injects TINYOAUTH_COOKIE_SECRET into the tinyoauth Deployment via envFrom.
# The config.yaml ConfigMap (in git) intentionally omits cookie_secret;
# TinyOAuth's applyEnvFallbacks fills it from this env var at startup.
resource "kubernetes_secret" "tinyoauth_secret" {
  metadata {
    name      = "tinyoauth-secret"
    namespace = "tinyoauth"
  }

  data = {
    TINYOAUTH_COOKIE_SECRET = random_bytes.tinyoauth_cookie_secret.hex
  }
}
