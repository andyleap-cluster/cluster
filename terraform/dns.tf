# Linode token for DNS management
resource "linode_token" "lkedns" {
  label  = "lkedns-production"
  scopes = "domains:read_write"
}