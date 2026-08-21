# harness account iac

! work in progress

this example opentofu project is meant to introduce users to the structure of harness and the basics of creating secrets, delegates, and connectors to enable an enterprise developer platform. this code should not be used in production and is for educational purposes only.

if you are an enterprise customer looking for a scalable automation framework for managing your harness environment see the [harness solutions factory](https://github.com/harness/harness-solutions-factory).

# cluster setup

as a pre-requisite for deploying the resources in this project, we need a few sameple kubernetes clusters for delegate and application deployment.

this lab uses `kind` to run local kubernetes clusters for testing purposes, provisioned via opentofu.

to deploy the required clusters, navigate to the `cluster_bootstrap` directory and execute a `tofu apply`.

this will generate local kubeconfig files for each cluster in the `cluster_bootstrap/.kube` directory, to be referenced in the core tofu configuration.

you can then use the cluster by doing `KUBECONFIG=cluster_bootstrap/.kube/build-farm.config kubectl get pods -A`.

# account level

this project will deploy all baseline resources nessesary to set up a harness account for general usage.

### a note on delegate selectors

as a general tip, we set `execute_on_delegate` to false to allow connectors to be used anywhere: harness cloud pipelines, k8s/vm/ecr/docker pipelines, etc. if you have a connector which is behind a firewall (only accessable via delegate) set this to true **but leave the selectors empty** to target __any__ delegate, harness will pick one at runtime with network access to the specified endpoint. this way if you every change delegate tags, you dont accidently break a connector.

**if you ever put delegate selectors on a connector/pipeline/stage/step you should always use __tags__ and not __names__ of delegates, so tags can be applied to multiple delegates to avoid a single point of failure.**

## github (scm)

to resolve git repos (to store resource configs, clone code, reference manifests) we create a connector at the account level which can read public github repositories.

```
git_username    = "rssnyder"
github_token    = "github_pat_xxx"
```

## dockerhub (container images)

being able to resolve container images is core to running harness pipelines. we create an account level connector to dockerhub to resolve public images. although we can leave this connector ananomus it is best to add a token to avoid rate limiting when running a large number of pipeline executions.

## delegate tokens

to deploy a harness delegate, we create specific tokens at the account level. this way if a token needs to be rotated we can target a specific delegate rather than many delegates which may be used a shared token

```
docker_username = "rssnyder"
docker_password = "dckr_pat_xxx"
```

## delegate deployment

finally, we deploy a delegate into a kubernetes cluster (using our local kind cluster created above). doing this allows network access to private endpoints, and unlocks the ability to run containerized pipelines.

the delegate is core to the functionality of a harness account, and in production you would run several replicas, with delegates deployed across clusters/regions for high avaliblity.

## kubernetes connector

to enable the aformentioned containerized pipelines we create a kubernetes connector which will be refereneced in pipelines to define where the pipeline should execute. we generally refer to this as the "build farm" and is "generic compute infrastructure" and should be provisioned in a way that allows it to be used for executions across your harness account.

we pin this connector to the delegate tag __build-farm__ and in production you would deploy multiple build farm clusters with delegates that share this tag.

## helm chart template

to easily enable deployments of simple containers, we create an oci helm chart connector to point at `` which is a generic chart that enables deployments based on a values file.

we also create a harness file in the built-in file store with an example values file for this chart which pulls in the container information from the artifact defined on a service.

## templates

to created best-practice patterns we can create account level tempaltes for repeatable resources across the entire account.

here we create a basic kubernetes rolling deployment stage template to be reused across projects when doing deployments of this type.

# orgs

we create a `Lab` organization for demonstration purposes.

# projects

finally we create a project for `application a`.

within this project we create a kubernetes connector that uses masterURL and credentials to connect to one of our application clusters. this cluster is connected to from the build-farm delegate, and uses a masterURL so we do not have to deploy a delegate in each cluster, following the "hub and spoke" model.

we then create a pipeline which runs a simple hello world script, which takes in the kubernetes connector, namespace, docker connector and image as a runtime input so it can be used to test the different resources created in this lab.

## service

we create a service for an example app `pod info` which leverages the generic helm chart defined at the account level.

an artifact is defined to target the image and pull in the target tag at runtime.

# advanced configuration

## registry cache

when running multiple clusters on your laptop, it is recommended to use a local registry cache to avoid downloading the same images multiple times and potentially hitting rate limits. by passing `enable_docker_cache = true` to the `cluster_bootstrap` module, a local registry cache will be deployed and the clusters will beconfigured to route image pulls through the cache.

when doing this in production, if you are unable to set up a registry cache at the cluster level, you can set a default connector on pipeline to pull images through a particular repository (specified by a connector) with the setting `pipeline.stages[].stage.spec.infrastructure.spec.harnessImageConnectorRef`.

this field is mainly used to control which registry is used when pulling the default harness images used in steps. (all built in steps are just docker images, and every stage uses the `addon` and `lite-engine` containers to control execution)