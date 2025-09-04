# LKE cluster
resource "linode_lke_cluster" "cluster" {
  label       = "cluster"
  k8s_version = "1.31"
  region      = "us-east"

  pool {
    type  = "g6-standard-1"
    count = 3
  }

}