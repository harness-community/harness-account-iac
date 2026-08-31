terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.11.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "docker" {
  host = var.colima ? "unix://${pathexpand("~/.colima/default/docker.sock")}" : null
}