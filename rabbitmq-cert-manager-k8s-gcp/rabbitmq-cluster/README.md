# RabbitMQ cluster setup

## Requirements

* User needs Kubernetes Engine Admin permissions in IAM.
* GKS cluster set up, and kubectl installed and configured, as described in [provision-cluster](../provision-cluster).
* cert-manager setup complete, as described in [cert-manager](../cert-manager).

## Manually creating a self-signed certificate (not needed now, so ignore)

This should no longer be necessary since we get the certificate via cert-manager now, but just in case we need manual self-signed certificates again, download tls-gen from [here](https://github.com/michaelklishin/tls-gen) (ensure the folder name is _tls-gen_) then do the following.

To create a self-signed cert/key pair:

    cd tls-gen/basic
    make
    cd ../..

To create a Secret in the Kubernetes cluster containing a cert/key pair (named "rabbitmq-tls" in this case, change if needed):

    kubectl create secret tls rabbitmq-tls --cert=tls-gen/basic/result/server_certificate.pem --key=tls-gen/basic/result/server_key.pem

## Deployment

Deploy the RabbitMQ Cluster Operator:

    kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml

(More details on installing the RabbitMQ Cluster Operator, if needed, are [here](https://www.rabbitmq.com/kubernetes/operator/install-operator.html).)

Set up your RabbitMQ _definitions.json_ file as needed. There's one included here which gives an example of setting up a user and a vhost for app access.

Create ConfigMap for RabbitMQ definitions to set up user and vhost etc:

    kubectl create configmap definitions --from-file=definitions.json

To deploy the Workloads and Services with the certificate previously created via cert-manager, and with the ConfigMap mounted to import definitions:

    kubectl apply -f cluster.yml

Further instructions for deploying/using the cluster etc. are [here](https://www.rabbitmq.com/kubernetes/operator/using-operator.html).

## Update DNS

Update the DNS with the new external IP (if this initially fails it probably means you need to wait longer for the cluster to come up):

    ./dns.sh
 
**Note for future todo:** This currently has to use the same DNS name as ingress-nginx because otherwise the certificate can't be validated, so basically this is a bit of a hack. The solution is probably to use
wildcard DNS so that ingress-nginx can respond from one DNS name and MQ can use a different DNS name, so that we don't have to keep swapping the same DNS name from one service to another. I think this means 
setting up an issuer in cert-manager using something other than letsencrypt so we can have wildcard support. Needs further investigation and reworking.

## Test that RabbitMQ connections are working (optional)

Install and run PerfTest (change username, password, hostname and virtualhost as needed in the URI):

    kubectl run perf-test --image=pivotalrabbitmq/perf-test -- --uri "amqps://username:password@mq.example.com:5671/virtualhost"

Check logs to see if connections are successful (won't work until PerfTest is fully deployed):

    kubectl logs -f perf-test

Delete PerfTest:

    kubectl delete pod perf-test

## Check logs

Get the logs from the RabbitMQ cluster pod(s):

    for pod in $(kubectl get pods | egrep "^rabbitmq-cluster-server" | awk '{print $1}') ; do kubectl logs $pod ; done

## Deletion

    kubectl delete -f cluster.yml
    kubectl delete configmap definitions
    kubectl delete -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml 
