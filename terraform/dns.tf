resource "linode_domain" "main" {
  type = "master"
  domain = "andyleap.dev"
  soa_email = "andyleap@gmail.com"
}

# Look up the Traefik LoadBalancer service to get the external IP
data "kubernetes_service" "traefik" {
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }
}

# A record for the root domain pointing to the LoadBalancer IP
resource "linode_domain_record" "root" {
  domain_id   = linode_domain.main.id
  name        = ""
  record_type = "A"
  target      = data.kubernetes_service.traefik.status[0].load_balancer[0].ingress[0].ip
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

# Home Assistant CNAME pointing to Nabu Casa
resource "linode_domain_record" "home_assistant" {
  domain_id   = linode_domain.main.id
  name        = "home"
  record_type = "CNAME"
  target      = "7m9dm8f7ryknilv6sye73pbgwlew9whh.ui.nabu.casa"
}

# Home Assistant ACME challenge CNAME for SSL certificate validation
resource "linode_domain_record" "home_assistant_acme" {
  domain_id   = linode_domain.main.id
  name        = "_acme-challenge.home"
  record_type = "CNAME"
  target      = "_acme-challenge.7m9dm8f7ryknilv6sye73pbgwlew9whh.ui.nabu.casa"
}
