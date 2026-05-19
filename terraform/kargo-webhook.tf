# Push notification from this repo to Kargo's external webhook receiver,
# so master pushes trigger affected Warehouses within seconds instead of
# waiting for the next ~5 min poll.
#
# A single cluster-scoped ClusterConfig.webhookReceivers entry (see
# kargo/extras/clusterconfig.yaml) handles every Warehouse in every
# project; we register one GitHub webhook for it here.
#
# The receiver's URL path is sha256(project + receiverName + secret).
# For ClusterConfig receivers project is "", so it reduces to
# sha256(receiverName + secret). Source:
#   https://github.com/akuity/kargo/blob/main/pkg/webhook/external/receiver.go
#   ("buildWebhookPath") -- carries a "do not change" warning, so this
# precomputation is stable.

locals {
  kargo_github_receiver_name = "github-cluster-repo"
  kargo_webhook_host         = "kargo-webhooks.andyleap.dev"
  kargo_github_webhook_path = format(
    "/github/%s",
    sha256("${local.kargo_github_receiver_name}${random_password.kargo_github_webhook.result}"),
  )
  kargo_github_webhook_url = "https://${local.kargo_webhook_host}${local.kargo_github_webhook_path}"
}

resource "random_password" "kargo_github_webhook" {
  length  = 32
  special = false
}

# Lives in the system-resources namespace because the receiver is
# defined on ClusterConfig (cluster-scoped) and Kargo looks for its
# Secrets in `global.systemResources.namespace`. The chart auto-creates
# that namespace.
resource "kubernetes_secret" "kargo_github_webhook" {
  metadata {
    name      = "kargo-github-webhook"
    namespace = "kargo-system-resources"
    labels = {
      "kargo.akuity.io/cred-type" = "generic"
    }
  }

  data = {
    secret = random_password.kargo_github_webhook.result
  }
}

resource "github_repository_webhook" "kargo" {
  repository = data.github_repository.repo.name
  events     = ["push"]
  active     = true

  configuration {
    url          = local.kargo_github_webhook_url
    content_type = "json"
    secret       = random_password.kargo_github_webhook.result
    insecure_ssl = false
  }
}

output "kargo_github_webhook_url" {
  value       = local.kargo_github_webhook_url
  sensitive   = true
  description = "Kargo external-webhooks-server URL for this repo's GitHub webhook. The path embeds sha256(receiverName + secret), so treat the URL itself as sensitive."
}
