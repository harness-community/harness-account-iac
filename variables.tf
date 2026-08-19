
variable "harness_platform_api_key" {
  type = string
}

variable "harness_account_id" {
  type = string
}

variable "harness_endpoint" {
  type    = string
  default = "https://app.harness.io/gateway"
}

# connector details

## github
variable "git_username" {
  type    = string
  default = null
}

variable "github_token" {
  type    = string
  default = null
}

## dockerhub
variable "docker_username" {
  type    = string
  default = null
}

variable "docker_password" {
  type    = string
  default = null
}
