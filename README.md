# harness account iac

! work in progress

this example opentofu project is meant to introduce users to the structure of harness and the basics of creating secrets, delegates, and connectors to enable an enterprise developer platform. this code should not be used in production and is for educational purposes only.

if you are an enterprise customer looking for a scalable automation framework for managing your harness environment see the [harness solutions factory](https://github.com/harness/harness-solutions-factory).

# cluster setup

as a pre-requisite for deploying the resources in this project, we need a few sameple kubernetes clusters for delegate and application deployment.

this lab uses `kind` to run local kubernetes clusters for testing purposes, provisioned via opentofu.

to deploy the required clusters, navigate to the `cluster_bootstrap` directory and execute a `tofu apply`.

this will generate local kubeconfig files for each cluster in the `cluster_bootstrap/.kube` directory, to be referenced in the core tofu configuration.

# running

this project will deploy all baseline resources nessesary to set up a harness account for general usage.

it will create delegate tokens, and deploy delegates into each of the build farms deployed in the cluster setup section using the harness module for helm delegate deployments.

we then create kubernetes connectors for the build farm which will enable us to run pipelines across the account.

optionall, we this create github and dockerhub connectors to enable cloning code and pulling images:
```
git_username    = "rssnyder"
github_token    = "github_pat_xxx"
docker_username = "rssnyder"
docker_password = "dckr_pat_xxx"
```

# orgs

we create a `Lab` organization for demonstration purposes.

# projects

finally we create a project. within this project we create a kubernetes connector that uses masterURL and credentials to connect to one of our application clusters.
