output "id" {
  value = harness_platform_organization.this.id
}

output "generic_helm_chart_connector_id" {
  value = harness_platform_connector_oci_helm.stakater.id
}

output "generic_helm_chart_values_file_id" {
  value = harness_platform_file_store_file.application_values.id
}
