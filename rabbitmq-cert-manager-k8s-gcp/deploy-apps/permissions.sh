#!/bin/bash

# Change these as needed
project=myproject
repo=myrepo
location=europe-west2

# Service Account and Kubernetes Secret name
account=artifact-registry

# Email address of the Service Account
email=${account}@${project}.iam.gserviceaccount.com

# Create Service Account
gcloud iam service-accounts create ${account} \
--display-name="Read Artifact Registry" \
--description="Used by GKE to read Artifact Registry repos" \
--project=${project}

# Delete existing user keys
for key_id in $(gcloud iam service-accounts keys list --iam-account $email --managed-by=user | grep -v KEY_ID | awk '{print $1}') ; do
  gcloud iam service-accounts keys delete $key_id --iam-account $email
done

# Move old key file out of the way if it exists
[ -f ${account}.json ] && mv -f ${account}.json ${account}.json.old

# Create new Service Account key
gcloud iam service-accounts keys create ${PWD}/${account}.json \
--iam-account=${email} \
--project=${project}

# Grant Service Account role to reader Artifact Reg
gcloud projects add-iam-policy-binding ${project} \
--member=serviceAccount:${email} \
--role=roles/artifactregistry.reader

# Create a Kubernetes Secret representing the Service Account
kubectl create secret docker-registry ${account} \
--docker-server=https://${location}-docker.pkg.dev \
--docker-username=_json_key \
--docker-password="$(cat ${PWD}/${account}.json)" \
--docker-email=${email} \
--namespace=default
