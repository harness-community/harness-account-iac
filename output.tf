output "delegate_version" {
  value = data.harness_platform_delegate_default_version.current.version
}

output "delegate_minimal_version" {
  value = data.harness_platform_delegate_default_version.current.minimal_version
}

output "build_farm_token" {
  value     = harness_platform_delegatetoken.build_farm.value
  sensitive = true
}
