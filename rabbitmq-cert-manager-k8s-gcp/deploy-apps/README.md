# Application deployment

## Requirements

* GKS cluster set up, and kubectl installed and configured, as described in [provision-cluster](../provision-cluster).
* cert-manager setup complete, as described in [cert-manager](../cert-manager).
* RabbitMQ setup complete, as described in [rabbitmq-cluster](../rabbitmq-cluster).

You will also, of course, need at least one app which talks to RabbitMQ. The app should be containerised and the container stored in Artifact Registry. If unsure how to achieve this, refer to "Containerizing an app with Cloud Build" in [this document](https://cloud.google.com/kubernetes-engine/docs/quickstarts/deploying-a-language-specific-app) which should point you in the right direction (ignore the stuff about creating the cluster onward). It's assumed there is a containerised app in Artifact Registry called **my-app**, so just change the names and settings for your app as needed.

## Permissions

In order for GKE to pull the container images, a service account needs to exist with an associated Secret in Kubernetes, with the account given permission to access the Artifact Registry via the Secret. I got the following script from [here](https://stackoverflow.com/questions/68303913/gcloud-failed-to-pull-image-400-permission-artifactregistry-repositories-d) to achieve this, and added some additions primarily to delete any existing keys before creating a new key. 

(It's simplest to assume we don't have access to any previously-created private keys since they cannot be re-downloaded, so we create a new key here to ensure we can create the Secret in order to pull container images for the apps, and if we're deploying apps on a new cluster with a new key then there's no point in keeping old keys on the service account).

If you've been through this process before then the service account should already exist, unless it's been manually deleted by someone or unless a new GCP project is being used, so the first part of the script - where it tries to create the service account - will likely produce an error. This is to be expected and is nothing to worry about. The rest of the script should run correctly:

    ./permissions.sh

This will produce a file _artifact-registry.json_ containing the private key of the service account. As such it has very restricted permissions and is included in _.gitignore_ so it's not pushed to GitHub. This file can be shared securely with other users if needed. If _artifact-registry.json_ existed prior to running this script then it will be moved to _artifact-registry.json.old_ in case that's needed for reference.

To get a description of the service account and a list of its public keys, run the following (changing "project" to the name of your project):

    gcloud iam service-accounts describe artifact-registry@project.iam.gserviceaccount.com
    gcloud iam service-accounts keys list --iam-account artifact-registry@project.iam.gserviceaccount.com --managed-by=user

## Deployment

Deploy your app:

    kubectl apply -f my-app.yml
## Logs

To get the logs for the app pods in order to ensure they're running correctly (change the `egrep` regex string as needed):

    for pod in $(kubectl get pods | egrep '^my-app' | awk '{print $1}') ; do echo ; echo "=================================" ; echo $pod ; echo "=================================" ; kubectl logs $pod ; echo ; done

## Deletion

    kubectl delete -f my-app.yml 
