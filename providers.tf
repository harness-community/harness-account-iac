terraform {
  required_providers {
    harness = {
      source  = "harness/harness"
      version = "~> 0.40"
    }
  }
}

provider "harness" {
  # Configuration options
  endpoint         = var.harness_endpoint
  account_id       = var.harness_account_id
  platform_api_key = var.harness_platform_api_key
}
