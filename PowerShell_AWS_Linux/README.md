# AWS Provisioning and Deployment with Linux EC2 instances using PowerShell

Simple PowerShell scripts for automated provisioning of Linux EC2 instances within AWS. Running these will provision an Amazon Linux 2 EC2 instance with SSH key pair and Security Group, with a webapp deployed thereon, plus an associated DNS record in Route 53.

## Requirements

1. An [AWS](https://aws.amazon.com/) account with a [VPC](https://aws.amazon.com/vpc/) set up, and with a DNS domain/zone set up in [Route 53](https://aws.amazon.com/route53/).
1. PowerShell needs to be installed if you don't already have it, as per Microsoft's [instructions](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell) for installing on macOS, Linux, Windows, etc.
1. [AWS Tools for PowerShell](https://aws.amazon.com/powershell/) needs to be installed, as per the installation instructions [for macOS/Linux](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up-linux-mac.html) or [for Windows](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up-windows.html). I installed the AWS.Tools version on macOS, as opposed to the AWSPowerShell.NetCore version.
1. SSH needs to be installed for the deployment phase. This is only likely to be an issue on Windows, so follow Microsoft's [instructions](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse) for getting OpenSSH installed and configured.

## Installing necessary AWS modules in PowerShell

I'm using the AWS.Tools version of AWS Tools for PowerShell on macOS, so I found it necessary to install the necessary AWS modules for shared services, EC2 and Route 53, as follows. (Start Powershell with `pwsh` if needed before running these commands):

    Install-Module -Name AWS.Tools.Common
    Install-Module -Name AWS.Tools.EC2
    Install-Module -Name AWS.Tools.Route53

With the AWSPowerShell.NetCore version of AWS Tools for PowerShell, installing these additional modules does not appear to be necessary.

## Setting up AWS credentials and config

On macOS I found that AWS Tools for PowerShell used my existing AWS credentials and config set up in _~/.aws/credentials_ and _~/.aws/config_ (originally set up for use with the [AWS CLI](https://aws.amazon.com/cli/)) without any additional setup needed. 

If you need help setting up your AWS credentials and config (e.g. default AWS region) for use with PowerShell, refer to the [Getting Started documentation](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-started.html).

## Setting up variables

Copy _etc/variables_template.ps1_ to _etc/variables.ps1_ and edit the file as per your requirements. The `$ZoneDnsName` in particular will need to be changed for the DNS domain you want to use in Route 53.

## Usage

If necessary, run `pwsh` to enter PowerShell if you're on macOS or Linux, or start the Windows PowerShell app if you're on Windows, then change to this _PowerShell_AWS_Linux_ directory to run the scripts.

## Provisioning

Run _[./provision.ps1](provision.ps1)_ to provision the instance and DNS. This will provision an SSH key pair and Security Group, then launch the EC2 instance, then set up a CNAME in the DNS pointing `www.mydomain.com` to the public DNS of the EC2 instance.

**N.B.** This script saves the private SSH key to _etc/$AppName.pem_. For the SSH deployment to work (see below) this file needs to have its permissions set to mode 0600, but there does not seem to be a standard way of achieving this in PowerShell. I've used a non-PowerShell `chmod` command in the script which will work on macOS and Linux.
In Windows PowerShell this line will need to be commented out because `chmod` does not exist in that environment. If the permissions of this file prevent SSH deployment on Windows, you'll need to manually set the permissions before running _deploy.ps1_. If anyone knows of a better solution for solving this across all operating systems, let me know.

## Deployment

Run _[./deploy.ps1](deploy.ps1)_ to deploy the webapp on the EC2 instance. This does the following via SSH connections:

* Downloads my basic Python webapp [simple-webapp](https://github.com/mattbrock/simple_webapp) to the instance and unzips it to the necessary location.
* Installs the systemd service script for the webapp, then enables it and starts it as a service running on port 8080.
* Installs nginx and downloads an nginx config file which proxies all incoming requests on port 80 to the webapp on port 8080.
* Enables nginx and starts it as a service running on port 80.
 
You can modify this script to deploy a different webapp if so desired.

## Deprovisioning

Run _[./destroy.ps1](destroy.ps1)_ to delete the DNS entry, terminate the EC2 instance, remove the Security Group and SSH key pair, and delete the private key file.

**N.B.** Run this script with **extreme caution** as it removes AWS infrastructure and has the potential for serious damage if, for example, you accidentally run it in the wrong environment.

## Checking the deployment

To check the webapp via the EC2 instance Public DNS:

    $InstancePublicDNS = (Get-EC2Instance -Filter @( @{name='tag:Name'; values="simple-webapp"})).Instances.publicdnsname ; curl http://$InstancePublicDNS/

To check the webapp via the Route 53 DNS:

    curl http://www.mydomain.com/

## Checking the logs

To check the nginx access log:

    $InstancePublicDNS = (Get-EC2Instance -Filter @( @{name='tag:Name'; values="simple-webapp"})).Instances.publicdnsname ; ssh -o CheckHostIP=no -o StrictHostKeyChecking=no -i etc/simple-webapp.pem ec2-user@$InstancePublicDNS "sudo tail -50 /var/log/nginx/access.log"

To check the nginx error log:

    $InstancePublicDNS = (Get-EC2Instance -Filter @( @{name='tag:Name'; values="simple-webapp"})).Instances.publicdnsname ; ssh -o CheckHostIP=no -o StrictHostKeyChecking=no -i etc/simple-webapp.pem ec2-user@$InstancePublicDNS "sudo tail -50 /var/log/nginx/error.log"

To check the webapp log:

    $InstancePublicDNS = (Get-EC2Instance -Filter @( @{name='tag:Name'; values="simple-webapp"})).Instances.publicdnsname ; ssh -o CheckHostIP=no -o StrictHostKeyChecking=no -i etc/simple-webapp.pem ec2-user@$InstancePublicDNS "sudo grep simple_webapp /var/log/messages | tail -50"

## Connecting to the EC2 instance

To get an interactive session on the EC2 instance:

    $InstancePublicDNS = (Get-EC2Instance -Filter @( @{name='tag:Name'; values="simple-webapp"})).Instances.publicdnsname ; ssh -o CheckHostIP=no -o StrictHostKeyChecking=no -i etc/simple-webapp.pem ec2-user@$InstancePublicDNS
