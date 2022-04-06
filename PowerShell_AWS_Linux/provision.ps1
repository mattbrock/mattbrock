# Source variables file
. etc/variables.ps1

# Create EC2 keypair if it doesn't already exist
# and output private key to local file
if (!((Get-EC2KeyPair).KeyName | Select-String -Pattern "$KeyName")) {
  (New-EC2KeyPair -KeyName "$KeyName").KeyMaterial | Out-File -Encoding ascii -FilePath etc/$KeyName.pem
  Write-Output "Keypair $KeyName created and private key saved to etc/$KeyName.pem"
}

# SSH deployment cannot work unless the private key
# file has the correct permissions. I cannot find a
# standard way of achieving this in PowerShell.
# This command will work on macOS, Linux and Unix
# but won't work on Windows. On Windows this should
# be changed or removed as needed.
chmod 600 etc/$KeyName.pem

# Create EC2 Security Group if it doesn't already exist
# and add inbound rules for SSH and HTTP
if (! ((Get-EC2SecurityGroup).GroupName | Select-String -Pattern "$SecurityGroupName")) {
  $SecurityGroupID = (New-EC2SecurityGroup -GroupName "$SecurityGroupName" -GroupDescription "$SecurityGroupDescription")
  $PermitSSH = @{ IpProtocol="tcp"; FromPort="22"; ToPort="22"; IpRanges="0.0.0.0/0" }
  $PermitHTTP = @{ IpProtocol="tcp"; FromPort="80"; ToPort="80"; IpRanges="0.0.0.0/0" }
  $SecurityGroupRules = (Grant-EC2SecurityGroupIngress -GroupId "$SecurityGroupId" -IpPermission @( $PermitSSH, $PermitHTTP ))
  Write-Output "Security Group $SecurityGroupName created"
}

# Find latest official Amazon Linux 2 Kernel 5 AMI image
$AL2Image = (Get-EC2Image -Owners amazon -Filters @{Name = "name"; Values = "amzn2-ami-kernel-5*"}, @{Name = "architecture"; Values = "x86_64"} | Sort-Object CreationDate | Select-Object ImageId | Select-Object -Last 1).ImageId

# Create EC2 instance tag specification for Name tag
$NameTag = [Amazon.EC2.Model.Tag]@{ Key = "Name"; Value = "$InstanceName" }
$TagSpecification = [Amazon.EC2.Model.TagSpecification]::new()
$TagSpecification.ResourceType = "Instance"
$TagSpecification.Tags.Add($NameTag)

# Launch instance from Amazon Linux 2 AMI
# if it's not already running
if (! ((Get-EC2Instance -Filter @( @{name='tag:Name'; values="$InstanceName"})).Instances | Select-Object InstanceId)) {
  $EC2Instance = (New-EC2Instance -ImageId "$AL2Image" -KeyName $KeyName -SecurityGroups $SecurityGroupName -InstanceType $InstanceType -TagSpecification $TagSpecification)
  $ReservationID = ($EC2Instance).ReservationId
  while (((Get-EC2Instance -Filter @{Name = "reservation-id"; Values = "$ReservationId"}).Instances.State.Name.Value) -ne "running") { 
    Start-Sleep -s 15
  }
  $InstanceID = (Get-EC2Instance -Filter @{Name = "reservation-id"; Values = "$ReservationId"}).Instances.InstanceId
  Write-Output "Instance $InstanceName launched with ID $InstanceId"
}

# Get instance Public DNS from Name
$Instance = (Get-EC2Instance -Filter @( @{name='tag:Name'; values="$InstanceName"}))
$InstancePublicDNS = ($Instance).Instances.publicdnsname

# Create DNS entry definition
$DnsChange = New-Object Amazon.Route53.Model.Change
$DnsChange.Action = "CREATE"
$DnsChange.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$DnsChange.ResourceRecordSet.Name = "www.$ZoneDnsName"
$DnsChange.ResourceRecordSet.Type = "CNAME"
$DnsChange.ResourceRecordSet.TTL = 300
$DnsChange.ResourceRecordSet.ResourceRecords.Add(@{Value=$InstancePublicDns})

# Get Zone ID from DNS Domain Name
$ZoneId = (Get-R53HostedZonesByName -DNSName "$ZoneDnsName").Id

# Create DNS Record Set if it doesn't already exist
if (!((Get-R53ResourceRecordSet -HostedZoneId $ZoneId).ResourceRecordSets.Name | Select-String "www.$ZoneDnsName")) {
  $Output = (Edit-R53ResourceRecordSet -HostedZoneId $ZoneId -ChangeBatch_Change $DnsChange)
  Write-Output "DNS entry created (CNAME www.$ZoneDnsName -> $InstancePublicDns)"
}
