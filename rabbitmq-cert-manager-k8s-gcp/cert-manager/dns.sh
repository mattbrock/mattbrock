#!/bin/bash

# Change these as needed
# and also in the dns.yml.master file
dns_zone=example-com
dns_name=mq.example.com

file=dns.yml
old_data=$(dig +short -t a $dns_name)
new_data=$(kubectl get svc --namespace=ingress-nginx | grep LoadBalancer | awk '{print $4}')

[ -f $file ] && rm -f $file
cp -f ${file}.master $file
sed -i "s/OLD_DATA/${old_data}/" $file
sed -i "s/NEW_DATA/${new_data}/" $file
gcloud dns record-sets transaction execute --zone=${dns_zone} --transaction-file=dns.yml

[ $? -eq 0 ] && echo "IP updated from $old_data to $new_data"
