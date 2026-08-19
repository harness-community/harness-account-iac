locals {
  safe_org_name = replace(replace(var.name, "-", "_"), " ", "_")
}

resource "harness_platform_organization" "this" {
  identifier  = local.safe_org_name
  name        = var.name
  description = var.description
  tags        = ["source:terraform"]
}