# minimal log collection for harness continuous verification (CV) health
# sources: loki over elasticsearch, since elasticsearch needs a jvm heap
# (realistically 1-2gb minimum just to stay up) while loki's single-binary
# mode with filesystem storage runs comfortably in <200mb - the right size
# for a kind node. promtail is scoped to a small allowlist of namespaces so
# kube-system/delegate pod logs never get ingested, and retention is capped
# small since this is throwaway dev/test data.
#
# exposed via NodePort (not clusterIP) because the harness delegate that
# will query this lives in the build-farm kind cluster, not app-a. every
# kind node container shares the "kind" docker network, so the delegate can
# reach it at app-a-control-plane:31100 the same way it reaches the app-a
# api server - see cert_san_patch_app_a in main.tf.
locals {
  loki_values = <<EOF
loki:
  isDefault: true
  persistence:
    enabled: false
  service:
    type: NodePort
    nodePort: 31100
  config:
    limits_config:
      retention_period: 24h
    table_manager:
      retention_deletes_enabled: true
      retention_period: 24h
promtail:
  config:
    snippets:
      extraRelabelConfigs:
        - source_labels: [__meta_kubernetes_namespace]
          regex: default|python-app-pr
          action: keep
        - source_labels: [__meta_kubernetes_pod_label_workload]
          target_label: workload
          action: replace
grafana:
  enabled: false
EOF
}

provider "helm" {
  alias = "app_a"
  kubernetes {
    config_path = kind_cluster.app_a.kubeconfig_path
  }
}

resource "helm_release" "loki" {
  count = var.enable_loki ? 1 : 0

  provider = helm.app_a

  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki-stack"
  namespace        = "loki"
  create_namespace = true
  values           = [local.loki_values]

  depends_on = [kind_cluster.app_a]
}
