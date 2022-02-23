# Ansible ECS provisioning with Docker containers

This is a suite of Ansible playbooks to provision an ECS (Elastic Container Service) cluster on AWS, running a webapp deployed on Docker containers in the cluster and load balanced from an ALB, with the Docker image for the app pulled from an ECR (Elastic Container Registry) repository. 

Firstly a Docker image is built locally and pushed to a private ECR repository, then the EC2 SSH key and Security Groups are created. Next, a Target Group and corresponding ALB (Application Load Balancer type of ELB) are provisioned, then an ECS container instance is launched on EC2 for the ECS cluster. Finally the ECS cluster is provisioned, an ECS task definition is created to pull and launch the containers from the Docker image in ECR, and finally an ECS Service is provisioned to run the webapp task on the cluster as per the Service definition.

This is an Ansible framework to serve as a basis for building Docker images for your webapp and deploying them as containers on Amazon ECS. It can be expanded in multiple ways, the most obvious being to increase the number of running containers and ECS instances, either with manual scaling or ideally by adding auto-scaling.

CentOS 7 is used for the Docker container, but this can be changed to a different Linux distro if desired. Amazon Linux 2 is used for the ECS cluster instances on EC2.

I created a very basic [Python webapp](https://github.com/mattbrock/simple_webapp) to use as an example for the deployment here, but you can replace that with your own webapp should you so wish.

**N.B.** Until you've tested this and honed it to your needs, **run it in a completely separate environment for safety reasons**, otherwise there is potential here for accidental destruction of parts of existing environments. Create a separate VPC specifically for this, or even use an entirely separate AWS account.

## Installation/setup

1. You'll need an [AWS](https://aws.amazon.com/) account with a [VPC](https://aws.amazon.com/vpc/) set up, and with a DNS domain set up in [Route 53](https://aws.amazon.com/route53/).
1. Install and configure the latest version of the [AWS CLI](https://aws.amazon.com/cli/). The settings in the AWS CLI configuration files are needed by the Ansible modules in these playbooks. Also, the Ansible AWS modules aren't perfect, so there are a few tasks which needs to run the AWS CLI as a local external command. If you're using a Mac, I'd recommend using [Homebrew](https://brew.sh/) as the simplest way of installing and managing the AWS CLI.
1. If you don't already have it, you'll need [Python 3](https://www.python.org/). You'll also need the [boto](https://pypi.org/project/boto/) and [boto3](https://pypi.org/project/boto3/) Python modules (for Ansible modules and dynamic inventory) which can be installed via [pip](https://pypi.org/project/pip/).
1. [Ansible](https://www.ansible.com/) needs to be installed and configured. Again, if you're on a Mac, using Homebrew for this is probably best.
1. Docker needs to be installed and running. For this it's probably best to refer to the [instructions on the Docker website](https://www.docker.com/get-started).
1. Copy _[etc/variables\_template.yml](etc/variables_template.yml)_ to _etc/variables.yml_ and update the static variables at the top for your own environment setup.
1. [ECR Docker Credential Helper](https://github.com/awslabs/amazon-ecr-credential-helper) needs to be installed so that the local Docker daemon can authenticate with Elastic Container Registry in order to push images to a repository there. Follow the link for installation instructions (on a Mac, as usual, I'd recommend the Homebrew method).

### Configuring ECR Docker Credential Helper

The method which worked best for me was to add a suitable "credHelper" section to my _~/.docker/config.json_ file:

    "credHelpers": {
        "000000000000.dkr.ecr.eu-west-2.amazonaws.com": "ecr-login"
    }

(I've replaced my AWS account ID with zeros, but otherwise this is correct.)

So, for me, the whole _~/.docker/config.json_ ended up looking like this. Yours may not be quite the same but hopefully it clarifies how to add the "credHelped" section near the end:

    {
        "auths": {
            "000000000000.dkr.ecr.eu-west-2.amazonaws.com": {},
            "https://index.docker.io/v1/": {
                "auth": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
            }
        },
        "credHelpers": {
            "000000000000.dkr.ecr.eu-west-2.amazonaws.com": "ecr-login"
        }
    }

Hopefully now if your AWS credentials are also set correctly, you should have no trouble pushing Docker images to ECR repositories.

## Usage

These playbooks are run in the standard way, i.e: 

    ansible-playbook PLAYBOOK_NAME.yml

To deploy your own webapp instead of my [basic Python app](https://github.com/mattbrock/simple_webapp), you'll need to modify _[build\_push.yml](build\_push.yml)_ so it pulls your own app from your repo, then you can edit the variables as needed in _etc/variables.yml_.

## Playbooks for build/provisioning/deployment

1. _[build\_push.yml](build\_push.yml)_ - pulls the webapp from GitHub, builds a Docker image using _[docker/Dockerfile](docker/Dockerfile)_ which runs the webapp, and pushes the image to a private ECR repository.
1. _[provision\_key\_sg.yml](provision\_key\_sg.yml)_ - provisions an EC2 SSH key, and Security Groups for ECS container instances and ELB.
1. _[provision\_production.yml](provision\_production.yml)_ - provisions Target Group and associated ALB (Application Load Balancer type of ELB) for load balancing the containers, provisions IAM setup for ECS instances, launches ECS container instance on EC2, provisions ECS cluster, and sets up ECS task definition and Service so the webapp containers deploy on the cluster using the Docker image in ECR.
1. _[provision\_dns.yml](provision\_dns.yml)_ - provisions the DNS in Route 53 for the Staging instance; note that it may take a few minutes for the DNS to propagate before it becomes usable.

There are comments dotted about in the playbooks to help further explain certain aspects of what is going on.

Initially, running later playbooks without having run the earlier ones will fail due to missing components and variables etc. Running all four playbooks in succession will set up the entire infrastructure from start to finish.

Once everything is built successfully, the ECS service will attempt to run a task to deploy the webapp containers in the cluster. Below are instructions for how to check the service event log to see task deployment progress.

### Redeployment

Once the environment is up and running, any changes to the app can be rebuilt and redeployed by running Steps 1 and 3 again. This makes use of the rolling deployment mechanism within ECS for a smooth automated transition to the new version of the app.

## Playbooks for deprovisioning

1. _[destroy\_all.yml](destroy\_all.yml)_ - destroys the entire AWS infrastructure. 
1. _[delete\_all.yml](delete\_all.yml)_ - clears all dynamic variables in the _etc/variables.yml_ file, deletes the EC2 SSH key, removes the local Docker image, and deletes the local webapp repo in the _[docker](docker)_ directory.

**USE _destroy\_all.yml_ WITH EXTREME CAUTION!** If you're not operating in a completely separate environment, or if your shell is configured for the wrong AWS account, you could potentially cause serious damage with this. Always check before running that you are working in the correct isolated environment and that you are absolutely 100 percent sure you want to do this. Don't say I didn't warn you!

Once everything has been fully destroyed, it's safe to run the _delete\_all.yml_ playbook to clear out the variables file. Do not run this until you are sure everything has been fully destroyed, because the SSH key file can never be recovered again after it has been deleted.

## Checking the Docker image in a local container

After building the Docker image in Step 1, if you want to run a local container from the image for initial testing purposes, you can use standard Docker commands for this:

    docker run -d --name simple-webapp -p 8080:8080 $(grep ecr_repo etc/variables.yml | cut -d" " -f2):latest

You should then be able to make a request to the local container at:

http://localhost:8080/

To check the logs:

    docker logs simple-webapp

To stop the container:

    docker stop simple-webapp

To remove it:

    docker rm simple-webapp

## Checking deployment status, logs, etc.

To check the state of the deployment and see events in the service log:

    aws ecs describe-services --cluster simple-webapp --services simple-webapp --output text
    
This should show what's happening on the cluster in terms of task deployment, and hopefully you'll eventually see that the process successfully starts, registers on the load balancer, and completes deployment, at which point it should reach a "steady state":

    EVENTS  2022-02-23T13:04:39.900000+00:00        3a087c70-aaa3-47d5-ae31-040db688155a    (service simple-webapp) has reached a steady state.
    EVENTS  2022-02-23T13:04:39.899000+00:00        c0785dae-154d-440b-b315-f948901d48fb    (service simple-webapp) (deployment ecs-svc/4617274246689568181) deployment completed.
    EVENTS  2022-02-23T13:04:20.239000+00:00        c60ce4fa-e7a6-4776-907b-b931a166109a    (service simple-webapp) registered 1 targets in (target-group arn:aws:elasticloadbalancing:eu-west-2:000000000000:targetgroup/simple-webapp/2ec4fbc39edca3aa)
    EVENTS  2022-02-23T13:03:50.185000+00:00        2e2c4570-2bb3-45f3-83e6-84b61b9c63bb    (service simple-webapp) has started 1 tasks: (task 8b8f8d2258a74885b58e610fbf19a2cc).

Check the webapp via the ALB (ELB):

    curl http://$(grep elb_dns etc/variables.yml | cut -d" " -f2)

Check the webapp using DNS (once the DNS has propagated, and replacing `yourdomain.com` with the domain you are using:

    curl http://staging.yourdomain.com/

Get the container logs from running instances:

    ansible -i etc/inventory.aws_ec2.yml -u ec2-user --private-key etc/ec2_key.pem tag_Environment_Production -m shell -a "docker ps | grep simple-webapp | cut -d\" \" -f1 | xargs docker logs"

You can also use that method to run ad hoc Ansible commands on the instances, e.g. `uptime`:

    ansible -i etc/inventory.aws_ec2.yml -u ec2-user --private-key etc/ec2_key.pem tag_Environment_Production -m shell -a "uptime"

If you need to SSH to the instance, if there's only one instance:

    ssh -i etc/ec2_key.pem ec2-user@$(aws ec2 describe-instances --filters "Name=tag:Environment,Values=Production" --query "Reservations[*].Instances[*].PublicDnsName")
    
For multiple instances, list the public DNS names as follows, then SSH to each individually as needed:

    aws ec2 describe-instances --filters "Name=tag:Environment,Values=Production" --query "Reservations[*].Instances[*].PublicDnsName"