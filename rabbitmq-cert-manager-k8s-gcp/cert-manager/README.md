# cert-manager setup with ingress-nginx

## Requirements

* User needs Kubernetes Engine Admin permissions in IAM.
* GKS cluster set up, and kubectl installed and configured, as described in [provision-cluster](../provision-cluster).
* Domain set up in Cloud DNS.

## ingress-nginx

Deploy ingress-nginx controller:

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.0/deploy/static/provider/cloud/deploy.yaml

Update DNS:

    ./dns.sh

## cert-manager

Deploy cert-manager controller:

    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml

This will take some time, so if you initially get errors with the following command, wait for a minute or so then try again.

Create issuer:

    kubectl create -f issuer.yml

(There is also _issuer-staging.yml_ for using the letsencrypt staging API instead of prod, if needed.)

Deploy ingress and request certificate:

    kubectl apply -f ingress.yml

## Checking the certificate

Get certificate request status/details:

    kubectl describe certificaterequest $(kubectl describe certificate rabbitmq-tls | grep -i request | awk -F '"' '{print $2}')

Get certificate details:

    kubectl describe certificate rabbitmq-tls
    
## Renewing the certificate

An email should be received at the email address specified in _issuer.yml_ when it is time to renew the certificate. It may be wise to set a timed reminder also. If unsure, the certificate status can be checked with the commands above.

The simplest option for renewing is simply to delete the existing certificate and create a new one. This is likely to create a gap in the RabbitMQ service so downtime should be scheduled if appropriate:

Firstly, update the DNS to point to nginx ingress (oddly this doesn't always appear to be necessary when renewing, but it always appears to be necessary when creating the initial certificate, so I think it's best to always do this to be on the safe side, though I don't yet have an explanation for why it sometimes doesn't seem to be needed):

    ./dns.sh

Then delete and recreate the ingress, certificate and Secret:

    kubectl delete -f ingress.yml
    kubectl delete secret rabbitmq-tls
    kubectl apply -f ingress.yml

Then `cd` to the _[rabbitmq-cluster](../rabbitmq-cluster)_ folder and run the command there to revert the DNS back to the RabbitMQ service:

    cd ../rabbitmq-cluster
    ./dns.sh

It appears that RabbitMQ simply uses the updated certificate in the Secret without needing to be restarted/reloaded, though this has not yet been extensively tested. Some errors will likely appear in the RabbitMQ and app logs during the time when the certificate is being updated.

## Deletion

    kubectl delete -f ingress.yml
    kubectl delete secret rabbitmq-tls
    kubectl delete -f issuer.yml
    kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.yaml
    kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.0/deploy/static/provider/cloud/deploy.yaml 
