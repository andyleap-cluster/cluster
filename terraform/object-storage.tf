# OpenTofu state bucket
resource "linode_object_storage_bucket" "terraform_state" {
  region = "us-east"
  label  = "andyleap-dev-tf"
  acl    = "private"
}

# TLS certificates bucket (existing)
resource "linode_object_storage_bucket" "tls_certs" {
  region = "us-east" 
  label  = "andyleap-dev-tls"
  acl    = "private"
}

# Object storage access keys for existing services
resource "linode_object_storage_key" "singress" {
  label = "singress-production"

  bucket_access {
    bucket_name = "andyleap-dev-tls"
    region      = "us-east"
    permissions = "read_write"
  }

  depends_on = [linode_object_storage_bucket.tls_certs]
}

