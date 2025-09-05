provider "linode" {
  # Uses LINODE_TOKEN environment variable
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "github" {
  owner = "andyleap-cluster"
  app_auth {
    # Uses GITHUB_APP_ID, GITHUB_APP_INSTALLATION_ID, GITHUB_APP_PEM_FILE environment variables
  }
}