locals {
  # Harness delegates are JVM workloads; 1 CPU / 1Gi is below Harness's
  # documented minimum (1 CPU / 2Gi) and was causing startup/liveness
  # probe failures and crash-looping on both build farms. Bumping to
  # 2 CPU / 2Gi, which fits comfortably in the shared kind/Docker host
  # once the unused app-b cluster is removed.
  delegate_values = <<EOF
tags: build-farm,kind
cpu: 2
memory: 2048
EOF
}

# east build farm
resource "harness_platform_delegatetoken" "build_farm_east" {
  name       = "build-farm-east"
  account_id = data.harness_platform_current_account.current.account_id
}

provider "helm" {
  alias = "east"
  kubernetes {
    config_path = "${path.module}/cluster_bootstrap/.kube/east.config"
  }
}

module "build_farm_east" {
  source  = "harness/harness-delegate/kubernetes"
  version = "0.2.3"

  providers = {
    helm = helm.east
  }

  account_id       = data.harness_platform_current_account.current.account_id
  delegate_token   = harness_platform_delegatetoken.build_farm_east.value
  delegate_name    = "build-farm-east"
  deploy_mode      = "KUBERNETES"
  namespace        = "harness-delegate-ng"
  manager_endpoint = data.harness_platform_current_account.current.endpoint
  delegate_image   = "us-docker.pkg.dev/gar-prod-setup/harness-public/harness/delegate:${data.harness_platform_delegate_default_version.current.minimal_version}"
  replicas         = 1
  upgrader_enabled = false
  values           = local.delegate_values
}

resource "harness_platform_connector_kubernetes" "build_farm_east" {
  identifier  = "build_farm_east"
  name        = "build_farm_east"
  description = "Kubernetes connector for build farm east"
  tags        = ["source:terraform"]

  inherit_from_delegate {
    delegate_selectors = ["build-farm-east"]
  }
}

# west build farm
resource "harness_platform_delegatetoken" "build_farm_west" {
  name       = "build-farm-west"
  account_id = data.harness_platform_current_account.current.account_id
}

provider "helm" {
  alias = "west"
  kubernetes {
    config_path = "${path.module}/cluster_bootstrap/.kube/west.config"
  }
}

module "build_farm_west" {
  source  = "harness/harness-delegate/kubernetes"
  version = "0.2.3"

  providers = {
    helm = helm.west
  }

  account_id       = data.harness_platform_current_account.current.account_id
  delegate_token   = harness_platform_delegatetoken.build_farm_west.value
  delegate_name    = "build-farm-west"
  deploy_mode      = "KUBERNETES"
  namespace        = "harness-delegate-ng"
  manager_endpoint = data.harness_platform_current_account.current.endpoint
  delegate_image   = "us-docker.pkg.dev/gar-prod-setup/harness-public/harness/delegate:${data.harness_platform_delegate_default_version.current.minimal_version}"
  replicas         = 1
  upgrader_enabled = false
  values           = local.delegate_values
}

resource "harness_platform_connector_kubernetes" "build_farm_west" {
  identifier  = "build_farm_west"
  name        = "build_farm_west"
  description = "Kubernetes connector for build farm west"
  tags        = ["source:terraform"]

  inherit_from_delegate {
    delegate_selectors = ["build-farm-west"]
  }
}

# global connector for HA and DR of build farms
resource "harness_platform_connector_kubernetes" "build_farm" {
  identifier  = "build_farm"
  name        = "build_farm"
  description = "Kubernetes connector for build farm pools"
  tags        = ["source:terraform"]

  inherit_from_delegate {
    delegate_selectors = ["build-farm"]
  }
}