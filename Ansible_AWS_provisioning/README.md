# Ansible AWS provisioning

This is a suite of Ansible playbooks to provision an entire AWS infrastructure with a Staging instance and an auto-scaled load-balanced Production environment, and to deploy a webapp thereon. First the EC2 SSH key and Security Groups are created, then a Staging instance is provisioned, then the webapp is deployed on Staging from GitHub, then an image is taken from which to provision the Production environment. The Production environment is set up with auto-scaled EC2 instances running behind a load balancer. Finally, DNS entries are added for the Production and Staging environments.

This is currently configured for very modest requirements, with a maximum of three t2.micro instances for auto-scaling, but it's trivial to change these settings. There's no reason why this set of playbooks shouldn't handle scaling out to a much larger infrastructure, with more powerful and specialised instance types as needed.

I created a very basic [Python webapp](https://github.com/mattbrock/simple_webapp) to use as an example for the deployment here, but you can replace that with your own webapp should you so wish.

## Installation/setup

1. You'll need an [AWS](https://aws.amazon.com/) account with a [VPC](https://aws.amazon.com/vpc/) set up, and with a DNS domain set up in [Route 53](https://aws.amazon.com/route53/).
1. Install and configure the latest version of the [AWS CLI](https://aws.amazon.com/cli/). The settings in the AWS CLI configuration files are needed by the Ansible modules in these playbooks. Also, the Ansible modules don't yet support target tracking auto-scaling policies, so there is one task which needs to run the AWS CLI as a local external command for that purpose. If you're using a Mac, I'd recommend using [Homebrew](https://brew.sh/) as the simplest way of installing and managing the AWS CLI.
1. If you don't already have it, you'll need [Python 3](https://www.python.org/). You'll also need the [boto](https://pypi.org/project/boto/) and [boto3](https://pypi.org/project/boto3/) Python modules (for Ansible modules and dynamic inventory) which can be installed via [pip](https://pypi.org/project/pip/).
1. [Ansible](https://www.ansible.com/) needs to be installed and configured. Again, if you're on a Mac, using Homebrew for this is probably best.
1. Copy _[etc/variables\_template.yml](etc/variables_template.yml)_ to _etc/variables.yml_ and update the static variables at the top for your own environment setup.

## Usage

These playbooks are run in the standard way, i.e: 

`ansible-playbook PLAYBOOK_NAME.yml`. 

Note that Step 3 also requires the addition of `-i etc/inventory.aws_ec2.yml` to use the dynamic inventory.

To deploy your own webapp instead of my [basic Python app](https://github.com/mattbrock/simple_webapp), you'll need to edit _[deploy\_staging.yml](deploy\_staging.yml)_ so that Step 3 deploys your app with your own specific requirements, files, configuration, etc.

## Playbooks for provisioning/deployment

1. _[provision\_key\_sg.yml](provision\_key\_sg.yml)_ - provisions an EC2 SSH key and Security Groups.
1. _[provision\_staging.yml](provision\_staging.yml)_ - provisions a Staging instance based on the official Amazon Linux 2 AMI.
1. _[deploy\_staging.yml](deploy\_staging.yml)_ - sets up a Staging instance and deploys the app on it. 
    * Requires dynamic inventory specification, so run as follows: 
    * `ansible-playbook -i etc/inventory.aws_ec2.yml deploy_staging.yml`
1. _[image\_staging.yml](image\_staging.yml)_ - builds an AMI image from the Staging instance.
1. _[provision\_tg\_elb.yml](provision\_tg\_elb.yml)_ - provisions a Target Group and Elastic Load Balancer ready for the Production environment.
1. _[provision\_production.yml](provision\_production.yml)_ - provisions the auto-scaled Production environment from the Staging AMI, and attaches the Auto Scaling group to ELB Target Group.
    * This playbook does not wait for instances to be deployed as specified, so it will take some time after the playbook runs before the additions/changes become apparent.
1. _[provision\_dns.yml](provision\_dns.yml)_ - provisions the DNS in Route 53 for the Production environment and the Staging instance.
    * Note that it may take a few minutes for the DNS to propagate before it becomes usable.

Running later playbooks without having run the earlier ones will fail due to missing components and variables etc. 

Running all seven playbooks in succession will set up the entire infrastructure from start to finish.

Once the infrastructure is up and running, any changes to the app can be redeployed to Staging by running Step 3 again. You would then run Step 4 and Step 6 to rebuild the Production environment from the updated Staging environment. Note that in this situation, the old instances in Production are replaced with new ones in a rolling fashion, so it will take a while before the old instances are terminated and the new ones are in place.

## Playbooks for deprovisioning

1. _[destroy\_all.yml](destroy\_all.yml)_ - destroys the entire infrastructure. 
1. _[delete\_all.yml](delete\_all.yml)_ - clears all dynamic variables in the _etc/variables.yml_ file.

**USE _destroy\_all.yml_ WITH EXTREME CAUTION!** If your shell is configured for the wrong AWS account, you could potentially cause serious damage with this. Always check before running that your shell is configured for the correct environment and that you are absolutely 100 percent sure you want to do this. Don't say I didn't warn you!

Due to the fact that it might take some time to deprovision certain elements, some tasks in _destroy\_all.yml_ may initially fail. This should be nothing to worry about. If it happens, wait for a little while then run the playbook again until all tasks have succeeded.

Once everything has been fully destroyed, it's safe to run the _delete\_all.yml_ playbook to clear out the variables file. Do not run this until you are sure everything has been fully destroyed, because the SSH key file can never be recovered again after it has been deleted.

## Checking the Staging and Production sites

To check the app on Staging once deployed in Step 3, you can get the Staging instance's public DNS via the AWS CLI with this command:

`aws ec2 describe-instances --filters "Name=tag:Environment,Values=Staging" --query "Reservations[*].Instances[*].PublicDnsName"`

Then check it in your browser on port 8080 at:

http://ec2-xxx-xxx-xxx-xxx.xx-xxxx-x.compute.amazonaws.com:8080/ 

(replacing "ec2-xxx-xxx-xxx-xxx.xx-xxxx-x.compute.amazonaws.com" with the actual public address of the instance).

To check the app on Production once deployed in Step 6, you can get the ELB's DNS name by grepping the _variables.yml_ file:

`grep elb_dns etc/variables.yml | cut -d " " -f 2`

Then just check that in your web browser.

Once Step 7 has been run to create the DNS entries (and you've waited a little while for the DNS to propagate) you can visit your Production site at http://www.yourdomain.com/ and your Staging site at http://staging.yourdomain.com:8080/ (noting the use of port 8080 for Staging, and obviously replacing "yourdomain.com" with your actual domain as specified in the _/etc/variables.yml_ file).

## Load testing to check auto-scaling response

If you don't have enough traffic coming in to trigger an Auto Scaling event and you're wondering if the scaling is working as intended, you can use a benchmarking tool such as Apache's [ab](https://httpd.apache.org/docs/current/programs/ab.html) to artifically create large amounts of incoming traffic. This should raise the load on the Production instance enough to trigger the automatic launch of an additional Production instance. I've found running this command from two separate servers simultaneously is usually sufficient (if you don't have any suitable servers, you can temporarily fire up a couple of EC2 instances for the purpose):

`ab -c 250 -n 1000000 http://www.yourdomain.com/`

This will simulate 250 simultaneous requests from each server, and will keep going until you cancel it (or until it hits a million requests, but an auto-scaling event should occur well before that number gets reached).

## Connecting to instances via SSH

If you need to SSH into the Staging instance once it's running after Step 2, get the public DNS name using the command above, then SSH in with:

`ssh -i etc/ec2_key.pem ec2-user@ec2-xxx-xxx-xxx-xxx.xx-xxxx-x.compute.amazonaws.com`

If you need to SSH into the Production instances once they're running after Step 6, get the list of public DNS names for the Production instances with this command (there may only be one instance):

`aws ec2 describe-instances --filters "Name=tag:Environment,Values=Production" --query "Reservations[*].Instances[*].PublicDnsName"`

Then connect via SSH in the same way as with the Staging instance.

## Running ad hoc Ansible commands

To run ad hoc commands (e.g. `uptime` in this example) remotely with Ansible (without playbooks) you can use the `ansible` command as follows:

`ansible -i etc/inventory.aws_ec2.yml -u ec2-user --private-key etc/ec2_key.pem tag_Environment_Staging -m shell -a uptime`

That can be used for the Staging instance. To run the command on all the Production instances at once, replace "tag_Environment_Staging" with "tag_Environment_Production". 
