resource "harness_platform_service" "podinfo" {

  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier  = "podinfo"
  name        = "podinfo"
  description = "podinfo service"

  yaml = <<-EOT
service:
  name: podinfo
  identifier: podinfo
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
              optionalValuesYaml: false
      artifacts:
        primary:
          primaryArtifactRef: main
          sources:
            - spec:
                connectorRef: account.${var.dockerhub_connector_id}
                imagePath: stefanprodan/podinfo
                tag: <+input>
                digest: ""
              identifier: main
              type: DockerRegistry
    type: Kubernetes
              EOT
}
