locals {
  safe_project_name = replace(replace(var.name, "-", "_"), " ", "_")
}

resource "harness_platform_project" "this" {
  identifier  = local.safe_project_name
  name        = var.name
  org_id      = var.org_id
  description = var.description
  tags        = ["source:opentofu"]

}

resource "harness_platform_pipeline" "example" {
  name       = "validate connectors"
  identifier = "validate_connectors"
  org_id     = var.org_id
  project_id = local.safe_project_name
  tags       = ["source:opentofu"]
  yaml = templatefile("${path.module}/templates/pipelines/validate.yaml.tmpl", {
    ORG_ID        = var.org_id
    PROJECT_ID    = local.safe_project_name
    PIPELINE_NAME = "validate connectors"
    PIPELINE_ID   = "validate_connectors"

    K8S_CONNECTOR_ID = "<+input>"
    K8S_NAMESPACE    = "<+input>"

    DOCKER_CONNECTOR_ID = "<+input>"
    IMAGE               = "busybox:latest"
  })
}
