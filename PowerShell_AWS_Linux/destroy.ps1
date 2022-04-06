# Source variables file
. etc/variables.ps1

# Get instance Public DNS from Name
$Instance = (Get-EC2Instance -Filter @( @{name='tag:Name'; values="$InstanceName"}))
$InstancePublicDNS = ($Instance).Instances.publicdnsname

# Create DNS entry definition
$DnsChange = New-Object Amazon.Route53.Model.Change
$DnsChange.Action = "DELETE"
$DnsChange.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$DnsChange.ResourceRecordSet.Name = "www.$ZoneDnsName"
$DnsChange.ResourceRecordSet.Type = "CNAME"
$DnsChange.ResourceRecordSet.TTL = 300
$DnsChange.ResourceRecordSet.ResourceRecords.Add(@{Value=$InstancePublicDns})

# Get Zone ID from DNS Domain Name
$ZoneId = (Get-R53HostedZonesByName -DNSName "$ZoneDnsName").Id

# Delete DNS Record Set
if ((Get-R53ResourceRecordSet -HostedZoneId $ZoneId).ResourceRecordSets.Name | Select-String "www.$ZoneDnsName") {
  $Output = (Edit-R53ResourceRecordSet -HostedZoneId $ZoneId -ChangeBatch_Change $DnsChange)
  Write-Output "DNS entry deleted (CNAME www.$ZoneDnsName -> $InstancePublicDns)"
}

# Terminate EC2 instance if it's running, and remove Name tag
$Instance = (Get-EC2Instance -Filter @( @{name='tag:Name'; values="$InstanceName"}))
$InstanceId = ($Instance).Instances.InstanceId
$InstanceState = ($Instance).Instances.State.Name.Value
if ( ($InstanceId) -and ($InstanceState -ne "terminated") ) {
  $Output = (Remove-EC2Instance -InstanceId $InstanceId -Force)
  while (((Get-EC2Instance -Filter @{Name = "instance-id"; Values = "$InstanceId"}).Instances.State.Name.Value) -ne "terminated") {
    Start-Sleep -s 15
  }
  Remove-EC2Tag -Resource $InstanceId -Tag Name -Force
  Write-Output "Instance $InstanceName ($InstanceId) terminated and Name tag removed"
}

# Delete Security Group if it exists
if ((Get-EC2SecurityGroup).GroupName | Select-String -Pattern "$SecurityGroupName") {
  Remove-EC2SecurityGroup -GroupName "$SecurityGroupName" -Force
  Write-Output "Security Group $SecurityGroupName deleted"
}

# Delete EC2 keypair if it exists
if ((Get-EC2KeyPair).KeyName | Select-String -Pattern "$KeyName") {
  Remove-EC2KeyPair -KeyName "$KeyName" -Force
  Write-Output "Keypair $KeyName deleted"
}

# Delete local key file if it exists
if ((Test-Path "etc/$KeyName.pem" -PathType Leaf)) {
  Remove-Item -Path "etc/$KeyName.pem"
  Write-Output "Private key file etc/$KeyName.pem deleted"
}
