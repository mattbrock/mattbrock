# Matt Brock

Freelance System Administrator and DevOps Engineer based in London, UK with 25 years of server, infrastructure and automation experience.

* My freelance/contract services: [CETRE SysAdmin & DevOps](https://cetre.co.uk/)

This is a general repository for my various scripts, playbooks, plugins and config examples, most of which have accompanying articles describing their usage on [my blog](https://cetre.co.uk/blog/).

* [Ansible_AWS_provisioning](Ansible_AWS_provisioning) - Ansible playbooks to provision an entire AWS infrastructure with a Staging instance and an auto-scaled load-balanced Production environment.
* [Ansible_Docker_EC2](Ansible_Docker_EC2) - Ansible playbooks to provision a Staging instance on EC2, and to deploy a webapp there which runs in a Docker container.
* [Ansible_Docker_ECS](Ansible_Docker_ECS) - Ansible playbooks to provision an ECS cluster on AWS, running a webapp on Docker containers in the cluster and load balanced from an ALB, with the Docker image pulled from ECR.
* [Ansible_RHEL_CentOS_hardening](Ansible_RHEL_CentOS_hardening) - Ansible playbooks for security hardening on RHEL 7 and CentOS 7 servers.
* [check_hp_ssd](check_hp_ssd) - Nagios plugin to check SSDs on HP ProLiant DL360 servers and other similar ProLiant hardware.
* [convert-facebook-likes-to-csv](convert-facebook-likes-to-csv) - Perl script to convert all liked pages on Facebook to a CSV file for import into a spreadsheet.
* [extract_pgsql_sorts](extract_pgsql_sorts) - extract the details of PostgreSQL temporary files (disk-based sorts) into a more useful format.
* [get_Flickr_faves](get_Flickr_faves) - Bash script and accompanying launchd configuration for using Flickr favourites as a screensaver on OS X.
* [mac-detector](mac-detector) - scans local network for new MAC addresses and reports accordingly.
* [mongo-reclaim](mongo-reclaim) - reclaims storage on two-node MongoDB replica sets by clearing data on both nodes and forcing mongod to rebuild it.
* [pacct-report](pacct-report) - sends a weekly email with a summary of user activity, login information and commands run.
* [postfix_mail_system](postfix_mail_system) - accompanying config files and scripts for my blog article on building a Postfix-based mail system.
* [rabbitmq-cert-manager-k8s-gcp](rabbitmq-cert-manager-k8s-gcp) - Automated provisioning and deployment of RabbitMQ with cert-manager on a Kubernetes cluster within GCP (Google Cloud Platform).
* [reminders2txt](reminders2txt) - exports items from Reminders app on OS X to plaintext.
* [vCard_photo_extractor](vCard_photo_extractor) - script to extract the contact photos from vCard/VCF files.
* [x-forwarded-for_webtraffic](x-forwarded-for_webtraffic) - provides a continuously updating display of client IP addresses on a web server using X-Forwarded-For.
