# Linode token for DNS management
resource "linode_token" "lkedns" {
  label  = "lkedns-production"
  scopes = "domains:read_write"
}

resource "linode_domain" "main" {
    type = "master"
    domain = "andyleap.dev"
    soa_email = "andyleap@gmail.com"
}

resource "linode_domain_record" "star" {
    domain_id = linode_domain.main.id
    name = "*"
    record_type = "CNAME"
    target = "andyleap.dev"
}

resource "linode_domain_record" "keybase" {
  domain_id = linode_domain.main.id
  record_type = "TXT"
  target = "keybase-site-verification=4fetXyozvbk69u_2Dhpz5S-_CFHg2l6zZ2fANHSyRRM"
}