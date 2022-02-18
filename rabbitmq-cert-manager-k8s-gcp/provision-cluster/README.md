# Kubernetes cluster provisioning

## Requirements

### Local setup

* gcloud SDK installed and initialised (instructions [here](https://learn.hashicorp.com/tutorials/terraform/gke?in=terraform/kubernetes&utm_source=WEBSITE&utm_medium=WEB_IO&utm_offer=ARTICLE_PAGE&utm_content=DOCS)).
* kubectl installed (instructions [here](https://learn.hashicorp.com/tutorials/terraform/gke?in=terraform/kubernetes&utm_source=WEBSITE&utm_medium=WEB_IO&utm_offer=ARTICLE_PAGE&utm_content=DOCS)).
* Terraform installed (instructions [here](https://learn.hashicorp.com/tutorials/terraform/install-cli)).

If you have multiple gcloud SDK projects/configurations set up, you must remember to switch from one project (configuration) to another in gcloud SDK otherwise catastrophe could ensue. (Replace "test" with the name of your desired configuration.):

    gcloud config configurations activate test

To check details of the current configuration:

    gcloud config list

### GCS buckets

A GCS bucket needs to exist for remote Terraform state/lock management. This appears to work on an account level, not on a project level, so it's best to identify the bucket accordingly. The bucket is currently named `iac-state` but this should be changed to a more meaningful name to avoid confusion between different projects used by the same account.

When creating the GCS bucket, location type can be single region to save costs (europe-west2 in this case, but change that if needed), storage class should be standard, public access should be prevented, access control can be uniform, and object versioning should be switched on (default values should be fine).

## Usage

**N.B.** Be **very careful** when applying or destroying Terraform configuration as these commands have the potential to break things on a massive scale if you make a mistake. Always check that you are using the correct GCP project before you begin (this should have been done above during the gcloud SDK initialisation).

Terraform state and locking is shared remotely via a GCS bucket, which should make it impossible for more than one person to make changes at any given time for safety reasons, and should also ensure everyone is always working with the current state rather than a potentially out-of-date version (which would be potentially dangerous).

Initialise Terraform:

    terraform init
    
See what Terraform will do if you apply the current configuration:

    terraform plan
    
Apply the current configuration:

    terraform apply
    
Destroy the current configuration:

    terraform destroy
    
## Configure kubectl

Run this command to configure `kubectl` with access credentials. This is needed before you can run the kubectl commands for setting up cert-manager, RabbitMQ, etc:

    gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --zone $(terraform output -raw zone)
    
## Deploy Kubernetes Dashboard

If you also need to deploy the Kubernetes Dashboard, perform the following procedure.

Deploy the Kubernetes Dashboard and create a proxy server to access the Dashboard:

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
    kubectl proxy
    
This will keep running until stopped with CTRL-C so you need to open a new terminal tab/window, and create the ClusterRoleBinding resource:

    kubectl apply -f https://raw.githubusercontent.com/hashicorp/learn-terraform-provision-gke-cluster/master/kubernetes-dashboard-admin.rbac.yaml
    
Then create a token to log in to the Dashboard as an admin user:

    ADMIN_USER_TOKEN_NAME=$(kubectl -n kube-system get secret | grep admin-user-token | cut -d' ' -f1)
    ADMIN_USER_TOKEN_VALUE=$(kubectl -n kube-system get secret "$ADMIN_USER_TOKEN_NAME" -o jsonpath='{.data.token}' | base64 --decode)
    echo "$ADMIN_USER_TOKEN_VALUE"
    
Open the Kubernetes Dashboard in your browser [here](http://127.0.0.1:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/), choose to log in with a token, then copy/paste the output from the above commands. 
