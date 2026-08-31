variable "org_id" {
  type = string
}

variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = "A project"
}

# projects spoke clusters
variable "clusters" {
  type = map(object({
    master_url            = string
    ca_cert               = optional(string)
    client_key            = string
    client_cert           = string
    client_key_passphrase = optional(string)
    client_key_algorithm  = string
  }))
  default = null
}

variable "dockerhub_connector_id" {
  type = string
}

variable "generic_helm_chart_connector_id" {
  type = string
}

variable "generic_helm_chart_values_file_id" {
  type = string
}

variable "loki_endpoint" {
  description = "Base URL of the in-cluster loki service (e.g. output of cluster_bootstrap's loki-endpoint), or null to skip creating the connector."
  type        = string
  default     = null
}

variable "gitops_agent_id" {
  description = "Identifier of the Harness GitOps agent to register spoke clusters against (include scope prefix, e.g. 'account.hub')."
  type        = string
}
