locals {
  # kubeadm patch that adds the node's container-network DNS name as a
  # cert SAN so a delegate in another kind cluster can reach the API
  cert_san_patch_build_farm = "kind: ClusterConfiguration\napiServer:\n  certSANs:\n    - 127.0.0.1\n    - localhost\n    - build-farm-control-plane\n"
  cert_san_patch_app_a      = "kind: ClusterConfiguration\napiServer:\n  certSANs:\n    - 127.0.0.1\n    - localhost\n    - app-a-control-plane\n"

  # one registry:2 proxy per upstream registry hostname, each on its own port,
  # so pods keep their real image references (docker.io implicitly, or
  # us-docker.pkg.dev/... explicitly) unchanged - containerd transparently
  # redirects pulls for that hostname to the matching local cache container
  docker_cache_registries = var.enable_docker_cache ? var.docker_cache_registries : {}
  docker_cache_entries = {
    for idx, host in sort(keys(local.docker_cache_registries)) :
    host => {
      container_name = "registry-cache-${replace(host, ".", "-")}"
      port           = 5000 + idx
      remote_url     = local.docker_cache_registries[host]
    }
  }

  containerd_patches = [
    for host, e in local.docker_cache_entries : <<-EOT
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors."${host}"]
        endpoint = ["http://${e.container_name}:${e.port}"]
      [plugins."io.containerd.grpc.v1.cri".registry.configs."${host}".tls]
        insecure_skip_verify = true
    EOT
  ]
}

resource "kind_cluster" "build_farm" {
  name            = "build-farm"
  node_image      = "kindest/node:${var.kubernetes_version}"
  wait_for_ready  = true
  kubeconfig_path = "${path.module}/.kube/build-farm.config"

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    containerd_config_patches = local.containerd_patches

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

    containerd_config_patches = local.containerd_patches

    node {
      role                   = "control-plane"
      kubeadm_config_patches = [local.cert_san_patch_app_a]
    }
  }
}

# pull-through caches, one per upstream registry (var.docker_cache_registries),
# reachable from every kind node by container name on the "kind" docker network
# that all kind clusters' node containers join
resource "docker_image" "registry_cache" {
  for_each = local.docker_cache_entries
  name     = "registry:2"
}

resource "docker_container" "registry_cache" {
  for_each = local.docker_cache_entries
  name     = each.value.container_name
  image    = docker_image.registry_cache[each.key].image_id
  restart  = "unless-stopped"

  ports {
    internal = 5000
    external = each.value.port
  }

  env = [
    "REGISTRY_PROXY_REMOTEURL=${each.value.remote_url}",
    "REGISTRY_PROXY_TTL=168h",
  ]

  networks_advanced {
    name = "kind"
  }

  volumes {
    volume_name    = "registry-cache-${replace(each.key, ".", "-")}-data"
    container_path = "/var/lib/registry"
  }

  # the "kind" docker network only exists once a kind cluster has created it
  depends_on = [kind_cluster.build_farm]
}

