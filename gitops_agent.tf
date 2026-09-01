# harness gitops agent, deployed into the build-farm ("hub") cluster following
# the same hub-and-spoke model as the build-farm delegate: one agent here,
# spoke clusters (e.g. app-a) added as gitops clusters reachable via masterURL.

resource "harness_platform_gitops_agent" "hub" {
  identifier  = "hub"
  name        = "hub"
  description = "GitOps agent deployed in the build-farm hub cluster"
  type        = "CONNECTED_ARGO_PROVIDER"
  operator    = "ARGO"

  metadata {
    namespace         = "gitops-agent"
    high_availability = false
  }
}

resource "helm_release" "gitops_agent" {
  provider = helm.build_farm

  name             = "gitops-agent"
  repository       = "https://harness.github.io/gitops-helm"
  chart            = "gitops-helm"
  namespace        = "gitops-agent"
  create_namespace = true

  values = [yamlencode({
    harness = {
      identity = {
        accountIdentifier = data.harness_platform_current_account.current.account_id
        agentIdentifier   = harness_platform_gitops_agent.hub.identifier
      }
      secrets = {
        agentSecret = harness_platform_gitops_agent.hub.agent_token
      }
      configMap = {
        http = {
          agentHttpTarget = "https://app.harness.io/gitops"
        }
      }
    }
    # kind node is resource constrained, so trim the chart's defaults
    # (1 cpu/2Gi per component) down to something a lab node can schedule.
    # ponytail: fixed-size trim, bump if the hub cluster gets bigger nodes.
    agent = {
      image = {
        tag = "v0.125.0"
      }
      resources = {
        requests = { cpu = "250m", memory = "256Mi" }
        limits   = { cpu = "250m", memory = "256Mi" }
      }
    }
    "argo-cd" = {
      controller = {
        resources = {
          requests = { cpu = "500m", memory = "512Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }
      }
      applicationSet = {
        resources = {
          requests = { cpu = "250m", memory = "256Mi" }
          limits   = { cpu = "250m", memory = "256Mi" }
        }
      }
      redis = {
        resources = {
          requests = { cpu = "250m", memory = "256Mi" }
          limits   = { cpu = "250m", memory = "256Mi" }
        }
      }
      repoServer = {
        resources = {
          requests = { cpu = "500m", memory = "512Mi" }
          limits   = { cpu = "500m", memory = "512Mi" }
        }
      }
    }
  })]
}

# give the agent time to register/connect to the harness control plane before
# any gitops cluster resources try to attach to it.
resource "time_sleep" "wait_for_gitops_agent" {
  depends_on      = [helm_release.gitops_agent]
  create_duration = "60s"
}
