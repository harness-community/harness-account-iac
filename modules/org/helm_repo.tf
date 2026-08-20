# generic resources to deploy ad-hoc containers
resource "harness_platform_connector_oci_helm" "stakater" {
  org_id = harness_platform_organization.this.id

  identifier  = "stakater"
  name        = "stakater"
  description = "Helm connector for stakater charts"
  tags        = ["link:github.com/stakater", "source:opentofu"]

  url                = "ghcr.io/stakater/charts"
  delegate_selectors = []
}

resource "harness_platform_file_store_file" "application_values" {
  org_id = harness_platform_organization.this.id

  identifier  = "application_values"
  name        = "application_values"
  description = "Helm values for generic application"
  tags        = ["source:opentofu"]

  parent_identifier = "Root"
  file_content_path = "manifests/application.yaml"
  mime_type         = "application/yaml"
  file_usage        = "MANIFEST_FILE"
}