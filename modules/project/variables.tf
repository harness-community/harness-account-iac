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
