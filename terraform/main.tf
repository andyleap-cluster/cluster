terraform {
  required_version = ">= 1.6"

  backend "s3" {
    bucket                      = "andyleap-dev-tf"
    key                         = "opentofu.tfstate"
    region                      = "us-sea-1"
    endpoint                    = "https://us-sea-1.linodeobjects.com"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style             = true
  }

  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

