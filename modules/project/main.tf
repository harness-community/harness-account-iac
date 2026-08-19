locals {
  safe_project_name = replace(replace(var.name, "-", "_"), " ", "_")
}

resource "harness_platform_project" "this" {
  identifier  = local.safe_project_name
  name        = var.name
  org_id      = var.org_id
  description = var.description
}
