resource "harness_platform_environment" "demo" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier = "demo"
  name       = "demo"

  tags = ["source:opentofu"]
  type = "PreProduction"
}