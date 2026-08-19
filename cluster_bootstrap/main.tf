locals {
  # kubeadm patch that adds the node's container-network DNS name as a
  # cert SAN so a delegate in another kind cluster can reach the API
  cert_san_patch_build_farm = "kind: ClusterConfiguration\napiServer:\n  certSANs:\n    - 127.0.0.1\n    - localhost\n    - build-farm-control-plane\n"
  cert_san_patch_app_a      = "kind: ClusterConfiguration\napiServer:\n  certSANs:\n    - 127.0.0.1\n    - localhost\n    - app-a-control-plane\n"
}

resource "kind_cluster" "build_farm" {
  name            = "build-farm"
  node_image      = "kindest/node:${var.kubernetes_version}"
  wait_for_ready  = true
  kubeconfig_path = "${path.module}/.kube/build-farm.config"

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role                   = "control-plane"
      kubeadm_config_patches = [local.cert_san_patch_build_farm]
    }
  }
}

resource "kind_cluster" "app_a" {
  name            = "app-a"
  node_image      = "kindest/node:${var.kubernetes_version}"
  wait_for_ready  = true
  kubeconfig_path = "${path.module}/.kube/app-a.config"

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role                   = "control-plane"
      kubeadm_config_patches = [local.cert_san_patch_app_a]
    }
  }
}
