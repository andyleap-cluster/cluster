provider "linode" {
  # Uses LINODE_TOKEN environment variable
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "github" {
  owner = "andyleap-cluster"
  # Uses GITHUB_TOKEN environment variable
}