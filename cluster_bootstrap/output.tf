locals {
  clusters = {
    for c in [
      kind_cluster.build_farm_east,
      kind_cluster.build_farm_west,
      kind_cluster.app_a,
      ] : c.name => {
      master_url           = "https://${c.name}-control-plane:6443"
      ca_cert              = c.cluster_ca_certificate
      client_cert          = c.client_certificate
      client_key           = c.client_key
      client_key_algorithm = "RSA"
    }
  }
}

output "clusters" {
  value     = local.clusters
  sensitive = true
}

output "build-farm-east-endpoint" {
  value = kind_cluster.build_farm_east.endpoint
}

output "build-farm-west-endpoint" {
  value = kind_cluster.build_farm_west.endpoint
}

output "app-a-endpoint" {
  value = kind_cluster.app_a.endpoint
}

