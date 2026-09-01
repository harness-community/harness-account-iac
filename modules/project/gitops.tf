# harness gitops cluster resources for each spoke cluster, registered against
# the account-level gitops agent running in the hub cluster. the harness
# secrets in connectors.tf hold the same client cert/key so they can be
# reused for CD connectors; the gitops cluster's `secret_expressions`
# credential-resolution feature is a no-op on this account (verified: the
# resulting argocd cluster secret has no certData/keyData at all), so the
# cluster config is fed the cert/key straight from the source values instead.
# ponytail: plaintext in state here mirrors what argocd's own in-cluster
# secret already stores in cleartext; revisit if/when secret_expressions
# resolution is confirmed working on the account.
resource "harness_platform_gitops_cluster" "this" {
  for_each   = var.clusters
  depends_on = [time_sleep.wait_for_secrets, harness_platform_secret_text.cluster]

  org_id       = var.org_id
  project_id   = harness_platform_project.this.id
  identifier   = replace(each.key, "-", "_")
  agent_id     = var.gitops_agent_id
  force_update = true

  request {
    upsert = true

    cluster {
      server = each.value.master_url
      name   = each.key

      config {
        cluster_connection_type = "TLS_CLIENT_CERT"

        tls_client_config {
          cert_data = base64encode(each.value.client_cert)
          key_data  = base64encode(each.value.client_key)
          ca_data   = each.value.ca_cert != null ? base64encode(each.value.ca_cert) : null
          # kind clusters use self-signed API server certs not worth
          # validating in this lab.
          insecure = each.value.ca_cert == null
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      request[0].upsert,
      request[0].cluster[0].config[0].bearer_token,
    ]
  }
}
