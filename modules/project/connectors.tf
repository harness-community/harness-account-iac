locals {
  # Build a map of secrets to create for each cluster, excluding
  # master_url and client_key_algorithm. Optional attributes are only
  # included when a value is provided.
  cluster_secrets = merge([
    for cluster_key, cluster in var.clusters : {
      for attr, value in {
        ca_cert               = cluster.ca_cert
        client_key            = cluster.client_key
        client_cert           = cluster.client_cert
        client_key_passphrase = cluster.client_key_passphrase
        } : "${cluster_key}_${attr}" => {
        cluster_key = cluster_key
        attr        = attr
        value       = value
      } if value != null
    }
  ]...)
}

resource "harness_platform_secret_text" "cluster" {
  for_each = local.cluster_secrets

  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier  = replace(each.key, "-", "_")
  name        = each.key
  description = "${each.value.attr} for Kubernetes connector: ${each.value.cluster_key}"
  tags        = ["source:opentofu"]

  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = each.value.value
}

resource "time_sleep" "wait_for_secrets" {
  depends_on      = [harness_platform_secret_text.cluster]
  create_duration = "5s"
}

resource "harness_platform_connector_kubernetes" "clientKeyCert" {
  for_each   = var.clusters
  depends_on = [time_sleep.wait_for_secrets]

  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier  = replace(each.key, "-", "_")
  name        = each.key
  description = "Kubernetes connector for cluster: ${each.key}"
  tags        = ["source:terraform"]

  client_key_cert {
    master_url                = each.value.master_url
    ca_cert_ref               = try(harness_platform_secret_text.cluster["${each.key}_ca_cert"].identifier, null)
    client_cert_ref           = harness_platform_secret_text.cluster["${each.key}_client_cert"].identifier
    client_key_ref            = harness_platform_secret_text.cluster["${each.key}_client_key"].identifier
    client_key_passphrase_ref = try(harness_platform_secret_text.cluster["${each.key}_client_key_passphrase"].identifier, null)
    client_key_algorithm      = each.value.client_key_algorithm
  }
}
