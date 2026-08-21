resource "harness_platform_template" "pipeline_template_remote" {
  identifier = "kubernetes_rolling_deploy"
  name       = "kubernetes rolling deploy"
  comments   = "Perform a rolling kubernetes deployment"
  version    = "v1"
  is_stable  = true
  template_yaml = templatefile("${path.module}/templates/stages/kubernetes_rolling_deploy.yaml.tmpl", {
    TEMPLATE_NAME       = "kubernetes rolling deploy"
    TEMPLATE_IDENTIFIER = "kubernetes_rolling_deploy"
  })
}