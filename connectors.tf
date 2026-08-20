# github
resource "harness_platform_secret_text" "github" {
  identifier  = "github"
  name        = "github"
  description = "GitHub personal access token for resolving repositories"
  tags        = ["source:opentofu"]

  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.github_token

  lifecycle {
    enabled = var.github_token != null
  }
}

resource "harness_platform_connector_github" "global" {
  identifier  = "global"
  name        = "global"
  description = "resolve repositories from public github"
  tags        = ["source:opentofu"]

  url                 = "https://github.com"
  connection_type     = "Account"
  validation_repo     = "harness/harness-solutions-factory"
  execute_on_delegate = false

  credentials {
    http {
      username  = var.git_username
      token_ref = "account.${harness_platform_secret_text.github.id}"
    }
  }

  lifecycle {
    enabled = var.git_username != null && var.github_token != null
  }
}

# dockerhub
resource "harness_platform_secret_text" "dockerhub" {
  identifier  = "dockerhub"
  name        = "dockerhub"
  description = "DockerHub username and password for resolving images"
  tags        = ["source:opentofu"]

  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.docker_password

  lifecycle {
    enabled = var.docker_password != null
  }
}

resource "harness_platform_connector_docker" "dockerhub" {
  identifier  = "dockerhub"
  name        = "dockerhub"
  description = "resolve images from public dockerhub"
  tags        = ["source:opentofu"]

  type                = "DockerHub"
  url                 = "https://registry.hub.docker.com/v2"
  execute_on_delegate = false

  credentials {
    username     = var.docker_username
    password_ref = "account.${harness_platform_secret_text.dockerhub.id}"
  }

  lifecycle {
    enabled = var.docker_username != null && var.docker_password != null
  }
}