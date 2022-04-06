# Source variables file
. etc/variables.ps1

# Get instance Public DNS from Name
$Instance = (Get-EC2Instance -Filter @( @{name='tag:Name'; values="$InstanceName"}))
$InstancePublicDNS = ($Instance).Instances.publicdnsname

# List of commands to run, to install and 
# configure simple_webapp and nginx
$Commands = @(
  'sudo curl -L -s -o /opt/simple_webapp.zip https://github.com/mattbrock/simple_webapp/archive/refs/heads/master.zip'
  'sudo unzip /opt/simple_webapp.zip -d /opt'
  'sudo mv -fv /opt/simple_webapp-master /opt/simple_webapp'
  'sudo cp -fv /opt/simple_webapp/simple-webapp.service /usr/lib/systemd/system/simple-webapp.service'
  'sudo systemctl daemon-reload'
  'sudo systemctl enable simple-webapp'
  'sudo systemctl start simple-webapp'
  'sudo amazon-linux-extras install nginx1'
  'sudo curl -s -o /etc/nginx/default.d/simple-webapp.conf https://raw.githubusercontent.com/mattbrock/mattbrock/master/Ansible_Docker_EC2/etc/simple-webapp.conf'
  'sudo systemctl enable nginx'
  'sudo systemctl start nginx'
)

# Function to send command via SSH
function Send-Command {
  param ($Command)
  ssh -o CheckHostIP=no -o StrictHostKeyChecking=no -i etc/$KeyName.pem ec2-user@$InstancePublicDNS "$Command"
}

# Iterate through commands and send/run
# each in turn via SSH
$Commands | % { Send-Command $_ }
