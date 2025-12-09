# OpenTofu state bucket
resource "linode_object_storage_bucket" "terraform_state" {
  region = "us-sea"
  label  = "andyleap-dev-tf"
  acl    = "private"
}
