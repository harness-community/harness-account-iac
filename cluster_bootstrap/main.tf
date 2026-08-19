locals {
  # kubeadm patch that adds the node's container-network DNS name as a
  # cert SAN so a delegate in another kind cluster can reach the API
  # server at https://<cluster>-control-plane:6443 without TLS errors.
  #
  # NOTE: a certSANs patch REPLACES kind's default SAN list, so we must
  # re-include 127.0.0.1 / localhost here or host-based access (the helm
  # provider using the 127.0.0.1:<port> kubeconfig) breaks.
  cert_san_patch = { for name in [
    "build-farm",
    "app-a",
    ] : name => "kind: ClusterConfiguration\napiServer:\n  certSANs:\n    - 127.0.0.1\n    - localhost\n    - ${name}-control-plane\n"
  }
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
      kubeadm_config_patches = [local.cert_san_patch["build-farm"]]
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
      kubeadm_config_patches = [local.cert_san_patch["app-a"]]
    }
  }
}
