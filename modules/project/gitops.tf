# harness gitops cluster resources for each spoke cluster, registered against
# the account-level gitops agent running in the hub cluster. credentials are
# not re-created here - they reference the same client cert/key/ca secrets
# already provisioned per cluster in connectors.tf.
resource "harness_platform_gitops_cluster" "this" {
  for_each   = var.clusters
  depends_on = [time_sleep.wait_for_secrets]

  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  identifier = replace(each.key, "-", "_")
  agent_id   = var.gitops_agent_id

  request {
    upsert = true

    secret_expressions = {
      certData = harness_platform_secret_text.cluster["${each.key}_client_cert"].identifier
      keyData  = harness_platform_secret_text.cluster["${each.key}_client_key"].identifier
    }

    cluster {
      server = each.value.master_url
      name   = each.key

      config {
        cluster_connection_type = "TLS_CLIENT_CERT"

        tls_client_config {
          # kind clusters use self-signed API server certs not worth
          # validating in this lab; mTLS client cert/key auth above is
          # still enforced via secret_expressions.
          insecure = true
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      request[0].upsert,
      request[0].cluster[0].config[0].bearer_token,
      request[0].cluster[0].config[0].cluster_connection_type,
    ]
  }
}
