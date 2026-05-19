# Pocket ID bootstrap
#
# ENCRYPTION_KEY is generated once and lives in TF state forever; rotating
# it would orphan all encrypted-at-rest data in Pocket ID's SQLite DB.
#
# Pocket ID's storage is split across emptyDir + one Linode Object Storage
# bucket:
#   - SQLite DB lives at /app/data/pocket-id.db on emptyDir. Litestream
#     (init+sidecar) replicates it to bucket path "litestream".
#   - User-uploaded files (profile pics, custom branding) go straight
#     to the same bucket via Pocket ID's native S3 file backend, under
#     bucket path "uploads".
# Both Litestream and Pocket ID's S3 backend use the same read_write
# access key. LKE block-storage volumes have a per-volume minimum size
# that makes them expensive for tiny datasets like this one.

resource "kubernetes_namespace" "pocket_id" {
  metadata {
    name = "pocket-id"
  }
}

resource "random_password" "pocket_id_encryption_key" {
  length  = 32
  special = false
}

resource "linode_object_storage_bucket" "pocket_id" {
  region = "us-sea"
  label  = "andyleap-dev-pocket-id"
  acl    = "private"
}

resource "linode_object_storage_key" "pocket_id" {
  label = "pocket-id"
  bucket_access {
    bucket_name = linode_object_storage_bucket.pocket_id.label
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
    LITESTREAM_ACCESS_KEY_ID     = linode_object_storage_key.pocket_id.access_key
    LITESTREAM_SECRET_ACCESS_KEY = linode_object_storage_key.pocket_id.secret_key
    S3_ACCESS_KEY_ID             = linode_object_storage_key.pocket_id.access_key
    S3_SECRET_ACCESS_KEY         = linode_object_storage_key.pocket_id.secret_key
  }
}
