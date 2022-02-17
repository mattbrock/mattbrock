# Automated provisioning and deployment of RabbitMQ with cert-manager on a Kubernetes cluster within GCP (Google Cloud Platform)

**N.B. Use at your own risk!** These procedures will change and destroy your infrastructure. Only use if you understand what you are doing.

Subfolders for each of the steps involved with setting up the cluster, deployments and services:

1. [provision-cluster](provision-cluster) - for provisioning and updating the Kubernetes cluster in GKS, safely isolated in a separate VPC which is also created, and configuring kubectl.
1. [cert-manager](cert-manager) - for setting up cert-manager with ingress-nginx, and issuing a certificate to a Secret for use by RabbitMQ.
1. [rabbitmq-cluster](rabbitmq-cluster) - to set up RabbitMQ, using the certificate created in the previous step.
1. [deploy-apps](deploy-apps) - to deploy applications as Workloads. 
