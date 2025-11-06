# LKE cluster - testing workflow
# This cluster runs the main workloads
resource "linode_lke_cluster" "cluster" {
  label       = "cluster"
  k8s_version = "1.31"
  region      = "us-sea"

  pool {
    type  = "g6-standard-1"
    count = 3
  }

}