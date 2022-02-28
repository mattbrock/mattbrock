# Ansible EC2 provisioning with Docker containers

This is a suite of Ansible playbooks to provision a basic AWS infrastructure on EC2 with a Staging instance, and to deploy a webapp on the Staging instance which runs in a Docker container. Firstly a Docker image is built locally and pushed to a private Docker Hub repository, then the EC2 SSH key and Security Groups are created, then a Staging instance is provisioned, then the Docker image is pulled on the Staging instance, then a Docker container is started from the image with nginx set up on the Staging instance to proxy web requests to the container. Finally, a DNS entry is added for the Staging instance.

This is a simple Ansible framework to serve as a basis for building Docker images for your webapp and deploying them as containers on Amazon EC2. It can be expanded in multiple ways, the most obvious being to add an auto-scaled Production environment with Docker containers. (For Ansible playbooks suitable for provisioning an auto-scaled Production environment, check out [this suite of playbooks](../Ansible_AWS_provisioning) I created previously.) More complex apps could be split across multiple Docker containers for handling front-end and back-end components, so this could also be added as needed.

CentOS 7 is used for the Docker container, but this can be changed to a different Linux distro if desired. Amazon Linux 2 is used for the Staging instance on EC2.

I created a very basic [Python webapp](https://github.com/mattbrock/simple_webapp) to use as an example for the deployment here, but you can replace that with your own webapp should you so wish.

**N.B.** Until you've tested this and honed it to your needs, **run it in a completely separate environment for safety reasons**, otherwise there is potential here for accidental destruction of parts of existing environments. Create a separate VPC specifically for this, or even use an entirely separate AWS account.

## Installation/setup

1. You'll need an [AWS](https://aws.amazon.com/) account with a [VPC](https://aws.amazon.com/vpc/) set up, and with a DNS domain set up in [Route 53](https://aws.amazon.com/route53/). 
1. Install and configure the latest version of the [AWS CLI](https://aws.amazon.com/cli/). The settings in the AWS CLI configuration files are needed by the Ansible modules in these playbooks. If you're using a Mac, I'd recommend using [Homebrew](https://brew.sh/) as the simplest way of installing and managing the AWS CLI.
1. If you don't already have it, you'll need [Python 3](https://www.python.org/). You'll also need the [boto](https://pypi.org/project/boto/) and [boto3](https://pypi.org/project/boto3/) Python modules (for Ansible modules and dynamic inventory) which can be installed via [pip](https://pypi.org/project/pip/).
1. [Ansible](https://www.ansible.com/) needs to be installed and configured. Again, if you're on a Mac, using Homebrew for this is probably best.
1. Docker needs to be installed and running. For this it's probably best to refer to the [instructions on the Docker website](https://www.docker.com/get-started).
1. A Docker account is required, and a private repository needs to be set up on [Docker Hub](https://hub.docker.com/).
1. Copy _[etc/variables\_template.yml](etc/variables_template.yml)_ to _etc/variables.yml_ and update the static variables at the top for your own environment setup.

## Usage

These playbooks are run in the standard way, i.e: 

    ansible-playbook PLAYBOOK_NAME.yml

Note that Step 4 requires the addition of `-i etc/inventory.aws_ec2.yml` to use the dynamic inventory, and also the addition of `-e 'ansible_python_interpreter=/usr/bin/python3'` to ensure it uses Python 3 on the Staging instance.

To deploy your own webapp instead of my [basic Python app](https://github.com/mattbrock/simple_webapp), you'll need to modify _[build\_local.yml](build\_local.yml)_ so it pulls your own app from your git repository, then you can edit the variables as needed in _etc/variables.yml_.

## Playbooks for build/provisioning/deployment

1. _[build\_local.yml](build\_local.yml)_ - pulls the webapp from GitHub, builds a Docker image using _[docker/Dockerfile](docker/Dockerfile)_ which runs the webapp, and pushes the image to a private Docker Hub repository.
1. _[provision\_key\_sg.yml](provision\_key\_sg.yml)_ - provisions an EC2 SSH key and Security Groups.
1. _[provision\_staging.yml](provision\_staging.yml)_ - provisions a Staging instance based on the official Amazon Linux 2 AMI.
1. _[deploy\_staging.yml](deploy\_staging.yml)_ - sets up the Staging instance, pulls the Docker image on the EC2 instance and runs a container, and sets up nginx to proxy incoming requests (on port 80) to the container (with the app running on port 8080); requires dynamic inventory specification and use of Python 3, so run as follows: 
    * `ansible-playbook -i etc/inventory.aws_ec2.yml -e 'ansible_python_interpreter=/usr/bin/python3' deploy_staging.yml`
1. _[provision\_dns.yml](provision\_dns.yml)_ - provisions the DNS in Route 53 for the Staging instance; note that it may take a few minutes for the DNS to propagate before it becomes usable.

Running later playbooks without having run the earlier ones will fail due to missing components and variables etc. 

Running all five playbooks in succession will set up the entire infrastructure from start to finish.

### Redeployment

Once the Staging environment is up and running, any changes to the app can be rebuilt and redeployed to Staging by running Steps 1 and 4 again.

## Playbooks for deprovisioning

1. _[destroy\_all.yml](destroy\_all.yml)_ - destroys the entire AWS infrastructure. 
1. _[delete\_all.yml](delete\_all.yml)_ - clears all dynamic variables in the _etc/variables.yml_ file, deletes the EC2 SSH key, removes the local Docker image, and deletes the local webapp repo in the _[docker](docker)_ directory.

**USE _destroy\_all.yml_ WITH EXTREME CAUTION!** If you're not operating in a completely separate environment, or if your shell is configured for the wrong AWS account, you could potentially cause serious damage with this. Always check before running that you are working in the correct isolated environment and that you are absolutely 100 percent sure you want to do this. Don't say I didn't warn you!

Due to the fact that it might take some time to deprovision certain elements, some tasks in _destroy\_all.yml_ may initially fail. This should be nothing to worry about. If it happens, wait for a little while then run the playbook again until all tasks have succeeded.

Once everything has been fully destroyed, it's safe to run the _delete\_all.yml_ playbook to clear out the variables file. Do not run this until you are sure everything has been fully destroyed, because the SSH key file can never be recovered again after it has been deleted.

## Checking the Docker image in a local container

After building the Docker image in Step 1, if you want to run a local container from the image for initial testing purposes, you can use standard Docker commands for this:

    docker run -d --name simple-webapp -p 8080:8080 my-repo/simple-webapp

(replacing "my-repo" with the name of your Docker Hub repo, and replacing "simple-webapp" as needed if you're running your own webapp.)

You should then be able to make a request to the local container at:

http://localhost:8080/

To check the logs:

    docker logs simple-webapp

To stop the container:

    docker stop simple-webapp

To remove it:

    docker rm simple-webapp

## Checking the Staging site

To check the app on Staging once deployed in Step 4, you can get the Staging instance's public DNS via the AWS CLI with this command:

    aws ec2 describe-instances --filters "Name=tag:Environment,Values=Staging" --query "Reservations[*].Instances[*].PublicDnsName"

Then check it in your browser at:

http://ec2-xxx-xxx-xxx-xxx.xx-xxxx-x.compute.amazonaws.com/

(replacing "ec2-xxx-xxx-xxx-xxx.xx-xxxx-x.compute.amazonaws.com" with the actual public address of the instance).

To bypass nginx and make the request directly to the container, go to:

http://ec2-xxx-xxx-xxx-xxx.xx-xxxx-x.compute.amazonaws.com:8080/ 

(This is only accessible from your IP and not publicly accessible, as per the Security Group rules.)

Once Step 5 has been run to create the DNS entry (and you've waited a little while for the DNS to propagate) you can visit your Staging site at http://staging.yourdomain.com/ (obviously replacing "yourdomain.com" with your actual domain as specified in the _/etc/variables.yml_ file).

## Checking the logs on the Staging instance, and running other ad hoc Ansible commands

To run ad hoc commands (e.g. `uptime` in this example) remotely with Ansible (without playbooks) you can use the `ansible` command as follows:

    ansible -i etc/inventory.aws_ec2.yml -u ec2-user --private-key etc/ec2_key.pem tag_Environment_Staging -m shell -a uptime

You can use this method to check the Docker webapp logs as follows:

    ansible -i etc/inventory.aws_ec2.yml -u ec2-user --private-key etc/ec2_key.pem tag_Environment_Staging -m shell -a "docker logs simple-webapp"

(replacing `simple-webapp` with the correct app name if you're using your own webapp.)

## Connecting to instances via SSH

If you need to SSH into the Staging instance once it's running after Step 3, get the public DNS name using the command above, then SSH in with:

    ssh -i etc/ec2_key.pem ec2-user@ec2-xxx-xxx-xxx-xxx.xx-xxxx-x.compute.amazonaws.com
