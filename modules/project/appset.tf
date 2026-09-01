# applicationset deploying the official argo cd example app (helm-guestbook)
# to every cluster registered against the project's gitops agent, using the
# built in cluster generator - no custom repo/manifests needed.

# harness scopes argocd projects to a harness project explicitly; map the
# argocd "default" project (used by the cluster resources and appset below)
# to this project so the applicationset is allowed to target it.
resource "harness_platform_gitops_app_project_mapping" "default" {
  org_id            = var.org_id
  project_id        = harness_platform_project.this.id
  agent_id          = var.gitops_agent_id
  argo_project_name = "default"
}

# the argocd "default" AppProject isn't created automatically by this chart,
# so create it explicitly, wide open (matches upstream argocd's built-in
# default project) so the example apps below can deploy anywhere.
resource "harness_platform_gitops_app_project" "default" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  agent_id   = var.gitops_agent_id
  upsert     = true

  project {
    metadata {
      name      = "default"
      namespace = "gitops-agent"
    }
    spec {
      source_repos = ["*"]
      destinations {
        server    = "*"
        namespace = "*"
      }
      cluster_resource_whitelist {
        group = "*"
        kind  = "Namespace"
      }
    }
  }
}

resource "harness_platform_gitops_applicationset" "example_apps" {
  depends_on = [harness_platform_gitops_cluster.this, harness_platform_gitops_app_project_mapping.default, harness_platform_gitops_app_project.default]

  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  agent_id   = var.gitops_agent_id
  upsert     = true

  applicationset {
    metadata {
      name      = "example-apps"
      namespace = "gitops-agent"
    }

    spec {
      go_template = true

      generator {
        clusters {
          enabled = true
        }
      }

      template {
        metadata {
          name = "{{.name}}-guestbook"
        }

        spec {
          project = "default"

          source {
            repo_url        = "https://github.com/argoproj/argocd-example-apps.git"
            path            = "helm-guestbook"
            target_revision = "HEAD"
          }

          destination {
            server    = "{{.server}}"
            namespace = "guestbook"
          }

          sync_policy {
            automated {
              prune     = true
              self_heal = true
            }
            sync_options = ["CreateNamespace=true"]
          }
        }
      }
    }
  }
}
