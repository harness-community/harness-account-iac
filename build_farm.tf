locals {
  delegate_values = <<EOF
tags: build-farm,kind
cpu: 1
memory: 2048
EOF
}

resource "harness_platform_delegatetoken" "build_farm" {
  name       = "harness-account-iac-build-farm"
  account_id = data.harness_platform_current_account.current.account_id
}

provider "helm" {
  alias = "build_farm"
  kubernetes = {
    config_path = "${path.module}/cluster_bootstrap/.kube/build-farm.config"
  }
}

module "build_farm" {
  # source  = "harness/harness-delegate/kubernetes"
  # version = "0.2.3"
  source = "/Users/rileysnyder/git/terraform-kubernetes-harness-delegate"

  providers = {
    helm = helm.build_farm
  }

  account_id       = data.harness_platform_current_account.current.account_id
  delegate_token   = harness_platform_delegatetoken.build_farm.value
  delegate_name    = "build-farm"
  deploy_mode      = "KUBERNETES"
  namespace        = "harness-delegate-ng"
  chart_version    = "1.0.0"
  manager_endpoint = var.manager_endpoint
  delegate_image   = "us-docker.pkg.dev/gar-prod-setup/harness-public/harness/delegate:${data.harness_platform_delegate_default_version.current.version}"
  replicas         = 1
  upgrader_enabled = false
  values           = local.delegate_values
}

# single connector for the build farm; delegate_selectors matches the
# delegate_name above so this doubles as the HA/DR connector too.
resource "harness_platform_connector_kubernetes" "build_farm" {
  identifier  = "build_farm"
  name        = "build_farm"
  description = "Kubernetes connector for build farm pool"
  tags        = ["source:opentofu"]

  inherit_from_delegate {
    delegate_selectors = ["build-farm"]
  }
}
