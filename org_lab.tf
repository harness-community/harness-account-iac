module "org_lab" {
  source      = "./modules/org"
  name        = "Lab"
  description = "Lab organization"
}

# pull in cluster configs from bootstrap
data "terraform_remote_state" "cluster_bootstrap" {
  backend = "local"
  config = {
    path = "${path.module}/cluster_bootstrap/terraform.tfstate"
  }
}

module "org_lab_project" {
  source      = "./modules/project"
  org_id      = module.org_lab.id
  name        = "App A"
  description = "App A project"
  clusters = {
    "app-a" = data.terraform_remote_state.cluster_bootstrap.outputs.clusters["app-a"]
  }
}
