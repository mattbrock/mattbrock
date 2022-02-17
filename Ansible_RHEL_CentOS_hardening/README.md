# RHEL 7 and CentOS 7 server hardening

Here are Ansible playbooks and related support files for hardening servers running RHEL 7, CentOS 7 and related distros. See my relevant blog posts for more information:

* New blog post describing the [automated process for CentOS 7 server hardening](https://cetre.co.uk/blog/ansible-playbooks-for-security-hardening-on-centos-7-servers/) using these Ansible playbooks.
* My original blog post with the [manual process for security hardening CentOS 7](https://cetre.co.uk/blog/security-hardening-on-centos-7-red-hat-enterprise-linux-7-amazon-linux/) and related Linux distros.

## Important notes

If SELinux is active on your server(s) it will probably interfere with these playbooks, so you have the choice to disable it if you wish in order to run these playbooks.
These playbooks could be later improved by adding options to take SELinux into account, if active.

Before running _harden\_ssh.yml_, if you have a firewall on the server(s) then ensure it's set to allow SSH access on port 1022 (or whichever alternative port you're using, if you're using a different one) otherwise you may risk locking yourself out of the server.

## The Ansible playbooks

1. _harden\_ssh.yml_ should normally be run first. This adds SSH server security and it will change the port the SSH server is running on, so you'll then want to add the connection variable `ansible_port=1022` to your host definition(s) in your Ansible inventory before running the other playbooks.
1. _harden\_os.yml_ is for the rest of the general server and OS hardening.
1. _harden\_php\_apache.yml_ can be run to harden PHP and Apache if you have those installed and running.
