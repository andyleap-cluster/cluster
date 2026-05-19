# Pocket ID bootstrap
#
# ENCRYPTION_KEY is generated once and lives in TF state forever; rotating
# it would orphan all encrypted-at-rest data in Pocket ID's SQLite DB.
#
# Pocket ID's storage strategy is SQLite-on-emptyDir replicated to Linode
# Object Storage via Litestream (init container restores on pod start,
# sidecar replicates continuously). LKE block-storage volumes have a
# minimum size that makes them expensive for tiny datasets like this.

resource "kubernetes_namespace" "pocket_id" {
  metadata {
    name = "pocket-id"
  }
}

resource "random_password" "pocket_id_encryption_key" {
  length  = 32
  special = false
}

resource "linode_object_storage_bucket" "pocket_id_backups" {
  region = "us-sea"
  label  = "andyleap-dev-pocket-id-backups"
  acl    = "private"
}

# Read-write access key scoped to just the backups bucket; consumed by
# Litestream in the pocket-id StatefulSet.
resource "linode_object_storage_key" "pocket_id_litestream" {
  label = "pocket-id-litestream"
  bucket_access {
    bucket_name = linode_object_storage_bucket.pocket_id_backups.label
    region      = "us-sea"
    permissions = "read_write"
  }
}

resource "kubernetes_secret" "pocket_id_bootstrap" {
  metadata {
    name      = "pocket-id-bootstrap"
    namespace = kubernetes_namespace.pocket_id.metadata[0].name
  }

  data = {
    ENCRYPTION_KEY               = random_password.pocket_id_encryption_key.result
    LITESTREAM_ACCESS_KEY_ID     = linode_object_storage_key.pocket_id_litestream.access_key
    LITESTREAM_SECRET_ACCESS_KEY = linode_object_storage_key.pocket_id_litestream.secret_key
  }
}
