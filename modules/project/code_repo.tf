# service account + token used by the gitops agent (and later, the PR
# pipeline) to authenticate git operations (clone/push/PR) against the
# harness code repo below - basic-auth git clones only accept
# service-account tokens, not personal platform API keys.
resource "harness_platform_service_account" "gitops" {
  account_id = data.harness_platform_current_account.current.account_id
  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier = "gitops_repo_bot"
  name       = "gitops repo bot"
  email      = "gitops_repo_bot@harness.io"
}

resource "harness_platform_role_assignments" "gitops_code_admin" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  role_identifier           = "_code_admin"
  resource_group_identifier = "_all_project_level_resources"

  principal {
    identifier = harness_platform_service_account.gitops.id
    type       = "SERVICE_ACCOUNT"
  }
}

resource "harness_platform_apikey" "gitops" {
  account_id = data.harness_platform_current_account.current.account_id
  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier  = "gitops_repo_bot"
  name        = "gitops repo bot"
  apikey_type = "SERVICE_ACCOUNT"
  parent_id   = harness_platform_service_account.gitops.id
}

resource "harness_platform_token" "gitops" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier  = "gitops_repo_bot"
  name        = "gitops repo bot"
  apikey_type = "SERVICE_ACCOUNT"
  apikey_id   = harness_platform_apikey.gitops.identifier
  parent_id   = harness_platform_service_account.gitops.id
  account_id  = data.harness_platform_current_account.current.account_id
}

# store the generated token as a harness secret - the source of truth for
# the credential, referenced below by the gitops repository config.
resource "harness_platform_secret_text" "gitops_repo_token" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier  = "gitops_repo_token"
  name        = "gitops_repo_token"
  description = "service account token used by the gitops agent to clone/push the gitops_sample harness code repo"
  tags        = ["source:opentofu"]

  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = harness_platform_token.gitops.value
}

data "harness_platform_current_account" "current" {}

# harness code repo, project-scoped, hydrated (imported) from the harness
# gitops PR-pipeline sample repo so we have a repo we can actually write to
# (argoproj/argocd-example-apps is read-only) for the applicationset source
# and the release-repo config the PR pipeline below commits to.
resource "harness_platform_repo" "gitops_sample" {
  identifier     = "gitops_sample"
  org_id         = var.org_id
  project_id     = harness_platform_project.this.id
  description    = "hydrated from harness-community/Gitops-Samples for the gitops applicationset + PR pipeline"
  default_branch = "main"

  source {
    type = "github"
    repo = "harness-community/Gitops-Samples"
  }
}

# register the harness code repo with the gitops agent, authenticated with
# the service account token above (username is the service account email).
resource "harness_platform_gitops_repository" "gitops_sample" {
  depends_on = [harness_platform_secret_text.gitops_repo_token]

  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  agent_id   = var.gitops_agent_id
  identifier = "gitops_sample"
  upsert     = true

  repo {
    connection_type = "HTTPS"
    name            = "gitops_sample"
    project         = "default"
    repo            = harness_platform_repo.gitops_sample.git_url
    username        = harness_platform_service_account.gitops.email
    password        = harness_platform_secret_text.gitops_repo_token.value
  }
}

output "gitops_sample_repo_git_url" {
  value = harness_platform_repo.gitops_sample.git_url
}
