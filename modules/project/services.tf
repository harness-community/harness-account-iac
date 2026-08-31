resource "harness_platform_file_store_file" "echo_values" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier  = "echo_values"
  name        = "echo_values"
  description = "Helm values override for echo (static workload label)"
  tags        = ["source:opentofu"]

  parent_identifier = "Root"
  file_content_path = "manifests/echo.yaml"
  mime_type         = "application/yaml"
  file_usage        = "MANIFEST_FILE"
}

resource "harness_platform_service" "echo" {

  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier  = "echo"
  name        = "echo"
  description = "http-echo service - logs every request to stdout, for exercising the loki log pipeline"

  yaml = <<-EOT
service:
  name: echo
  identifier: echo
  orgIdentifier: ${var.org_id}
  projectIdentifier: ${harness_platform_project.this.id}
  serviceDefinition:
    spec:
      manifests:
        - manifest:
            identifier: application
            type: HelmChart
            spec:
              store:
                type: OciHelmChart
                spec:
                  config:
                    type: Generic
                    spec:
                      connectorRef: org.${var.generic_helm_chart_connector_id}
                  basePath: /
              chartName: application
              subChartPath: ""
              chartVersion: ""
              helmVersion: V380
              skipResourceVersioning: false
              enableDeclarativeRollback: false
              fetchHelmChartMetadata: false
              optionalValuesYaml: false
        - manifest:
            identifier: values
            type: Values
            spec:
              store:
                type: Harness
                spec:
                  files:
                    - org:/${var.generic_helm_chart_values_file_id}
                    - /${harness_platform_file_store_file.echo_values.identifier}
              optionalValuesYaml: false
      artifacts:
        primary:
          primaryArtifactRef: main
          sources:
            - spec:
                connectorRef: account.${var.dockerhub_connector_id}
                imagePath: mendhak/http-https-echo
                tag: <+input>
                digest: ""
              identifier: main
              type: DockerRegistry
    type: Kubernetes
              EOT
}
