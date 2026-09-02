# standalone gitops application (not appset-managed), sourced from our own
# writable harness code repo (gitops_sample - see code_repo.tf), so the PR
# pipeline below has a dedicated release-repo target to commit/PR against.
# store.type = "HarnessCode" + repoName is the dedicated store type for
# referencing a Harness Code repo directly (confirmed via schema probe -
# it's a real enum value alongside Git/Github/Bitbucket/etc) - no external
# git connector or PAT needed, since it's all internal to the account.
resource "harness_platform_service" "python_app_pr_gitops" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier  = "python_app_pr_gitops"
  name        = "python app pr gitops"
  description = "release-repo target for the gitops PR pipeline (Update Release Repo / Merge PR), backed by the gitops_sample harness code repo"

  yaml = <<-EOT
service:
  name: python app pr gitops
  identifier: python_app_pr_gitops
  orgIdentifier: ${var.org_id}
  projectIdentifier: ${harness_platform_project.this.id}
  serviceDefinition:
    type: Kubernetes
    spec:
      manifests:
        - manifest:
            identifier: release_repo
            type: ReleaseRepo
            spec:
              store:
                type: HarnessCode
                spec:
                  gitFetchType: Branch
                  branch: main
                  paths:
                    - gitops-sample-app/charts/Python-App/values.yaml
                  repoName: ${harness_platform_repo.gitops_sample.identifier}
  EOT
}

resource "harness_platform_gitops_applications" "python_app_pr" {
  depends_on = [harness_platform_gitops_app_project.default, harness_platform_gitops_repository.gitops_sample]

  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  agent_id   = var.gitops_agent_id
  cluster_id = harness_platform_gitops_cluster.this["app-a"].identifier
  repo_id    = harness_platform_gitops_repository.gitops_sample.identifier
  name       = "python-app-pr"
  upsert     = true

  application {
    metadata {
      name = "python-app-pr"
      labels = {
        "harness.io/serviceRef" = harness_platform_service.python_app_pr_gitops.id
        "harness.io/envRef"     = harness_platform_environment.demo.id
      }
    }
    spec {
      project = "default"

      source {
        repo_url        = harness_platform_repo.gitops_sample.git_url
        path            = "gitops-sample-app/charts/Python-App"
        target_revision = "main"

        helm {
          parameters {
            name  = "ingress.enabled"
            value = "false" # no ingress controller in this lab's kind clusters
          }
        }
      }
      destination {
        server    = var.clusters["app-a"].master_url
        namespace = "python-app-pr"
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

# monitored service + loki-backed CV health source for the python_app_pr_gitops
# service, used by the Verify step in the PR pipeline below. GitOps deployments
# don't get Harness-tracked rollout instance data the way a native K8s CD stage
# does, so verification here works off external log data instead - the same
# "loki" custom health source connector already used for the echo service's CV
# setup (see connectors.tf), just with the native GrafanaLokiLogs health source
# type (gated behind the SRM_ENABLE_GRAFANA_LOKI_LOGS feature flag).
resource "harness_platform_monitored_service" "python_app_pr" {
  count = var.loki_endpoint != null ? 1 : 0

  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  identifier = "python_app_pr"

  request {
    name            = "python app pr"
    type            = "Application"
    service_ref     = harness_platform_service.python_app_pr_gitops.id
    environment_ref = harness_platform_environment.demo.id

    health_sources {
      name       = "loki"
      identifier = "loki"
      type       = "GrafanaLokiLogs"
      version    = "v2"
      spec = jsonencode({
        connectorRef = harness_platform_connector_customhealthsource.loki[0].id
        queryDefinitions = [
          {
            name       = "python-app-pr logs"
            identifier = "python_app_pr_logs"
            query      = "{namespace=\"python-app-pr\"}"
            groupName  = "Logs"
            queryParams = {
              serviceInstanceField = "pod"
            }
          }
        ]
      })
    }
  }
}

# PR pipeline: bumps replicaCount in gitops-sample-app/charts/Python-App/values.yaml,
# opens a PR in the gitops_sample harness code repo, merges it, then syncs the
# python-app-pr argocd application so the change actually rolls out, and
# verifies the result against loki logs from the app-a cluster.
resource "harness_platform_pipeline" "pr_sync" {
  depends_on = [
    harness_platform_gitops_applications.python_app_pr,
    harness_platform_environment_clusters_mapping.demo,
    harness_platform_monitored_service.python_app_pr,
  ]

  name       = "gitops PR sync"
  identifier = "gitops_pr_sync"
  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  tags       = ["source:opentofu"]

  yaml = templatefile("${path.module}/templates/pipelines/pr_sync.yaml.tmpl", {
    ORG_ID        = var.org_id
    PROJECT_ID    = harness_platform_project.this.id
    PIPELINE_NAME = "gitops PR sync"
    PIPELINE_ID   = "gitops_pr_sync"

    SERVICE_ID     = harness_platform_service.python_app_pr_gitops.id
    ENVIRONMENT_ID = harness_platform_environment.demo.id
    CLUSTER_ID     = harness_platform_gitops_cluster.this["app-a"].identifier
    AGENT_ID       = var.gitops_agent_id

    APPLICATION_NAME = "python-app-pr"
  })
}
