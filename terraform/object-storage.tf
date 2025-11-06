# OpenTofu state bucket
resource "linode_object_storage_bucket" "terraform_state" {
  region = "us-sea"
  label  = "andyleap-dev-tf"
  acl    = "private"
}

# TLS certificates bucket (existing)
resource "linode_object_storage_bucket" "tls_certs" {
  region = "us-sea"
  label  = "andyleap-dev-tls"
  acl    = "private"
}

# Auth service bucket
resource "linode_object_storage_bucket" "auth" {
  region = "us-sea"
  label  = "andyleap-dev-auth"
  acl    = "private"
}

# Object storage access keys for existing services
resource "linode_object_storage_key" "singress" {
  label = "singress-production"

  bucket_access {
    bucket_name = "andyleap-dev-tls"
    region      = "us-sea"
    permissions = "read_write"
  }

  depends_on = [linode_object_storage_bucket.tls_certs]
}

resource "linode_object_storage_key" "auth" {
  label = "auth-production"

  bucket_access {
    bucket_name = "andyleap-dev-auth"
    region      = "us-sea"
    permissions = "read_write"
  }

  depends_on = [linode_object_storage_bucket.auth]
}

