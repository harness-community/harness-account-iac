variable "kubernetes_version" {
  type    = string
  default = "v1.34.0"
}

variable "enable_docker_cache" {
  description = "Run registry:2 pull-through cache(s) on the host docker and point kind's containerd at them, one per key in var.docker_cache_registries."
  type        = bool
  default     = false
}

variable "docker_cache_registries" {
  description = "Map of upstream registry hostname (exactly as pods reference it, e.g. \"docker.io\" or \"us-docker.pkg.dev\") to its remote URL. Each entry gets its own registry:2 proxy; pods keep their normal image references, no renaming needed."
  type        = map(string)
  default = {
    "docker.io" = "https://registry-1.docker.io"
  }
}

variable "colima" {
  description = "Docker is provided by colima, whose socket lives at ~/.colima/default/docker.sock instead of /var/run/docker.sock."
  type        = bool
  default     = false
}