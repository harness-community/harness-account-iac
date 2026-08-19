output "delegate_version" {
  value = data.harness_platform_delegate_default_version.current.version
}

output "delegate_minimal_version" {
  value = data.harness_platform_delegate_default_version.current.minimal_version
}

output "build_farm_east_token" {
  value     = harness_platform_delegatetoken.build_farm_east.value
  sensitive = true
}

output "build_farm_west_token" {
  value     = harness_platform_delegatetoken.build_farm_west.value
  sensitive = true
}
