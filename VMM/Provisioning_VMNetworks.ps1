<#
.Synopsis
   Provisioning VM Networks
.DESCRIPTION
   Add and Remove VM Networks on VLAN-based Logical Networks
.EXAMPLE
   CreateVLAN -LogicalNetwork = "Tenant Network" -NetworkName = "Blue Network" -VLANID "999" -$VLANSubnet "10.10.10.0/24" -Hostgroup = "Amsterdam"
   RemoveVLAN -LogicalNetwork = "Tenant Network" -NetworkName = "Blue Network"
.NOTES
   Version 1.0 - Initial Script
   Written by Darryl van der Peijl
   Date: 23.05.2014
   
   Check Uplink Port Profile name on line 40
   Use at own risk
#>

Function CreateVMNetwork {
	param($LogicalNetwork,$NetworkName,$VLANID,$VLANSubnet,$Hostgroup)

#Check if VLAN already exists
$existingvlans = (Get-SCLogicalNetworkDefinition).subnetvlans | Select-Object VLANid
if ($existingvlans.vlanid -eq $VLANID) {
Write-Output "VLAN already exists!!"
}
else{

## Get Logical Network
$logicalNetwork = Get-SCLogicalNetwork -name $LogicalNetwork
## Get Hostgroup
$allHostGroups = Get-SCVMHostGroup -name $Hostgroup
## Create Subnet VLAN
$SubnetVlan = New-SCSubnetVLan -Subnet $VLANSubnet -VLanID $VLANID


## Create Network site in logical network and add VLAN
New-SCLogicalNetworkDefinition -Name $NetworkName -LogicalNetwork $logicalNetwork -VMHostGroup $allHostGroups -SubnetVLan $SubnetVlan -RunAsynchronously | Out-Null

## Enable VLAN on Uplink Port Profile
$portProfile = Get-SCNativeUplinkPortProfile -Name "$LogicalNetwork Uplink Port Profile"
$logicalNetworkDefinitionsToAdd = Get-SCLogicalNetworkDefinition -Logicalnetwork $LogicalNetwork -Name $NetworkName
Set-SCNativeUplinkPortProfile -NativeUplinkPortProfile $portProfile -AddLogicalNetworkDefinition $logicalNetworkDefinitionsToAdd | Out-Null

## Create VM Network
$logicalNetwork = Get-SCLogicalNetwork -Name $LogicalNetwork
$vmNetwork = New-SCVMNetwork -Name $NetworkName -LogicalNetwork $logicalNetwork -IsolationType "VLANNetwork"
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition -Name $NetworkName -LogicalNetwork $logicalNetwork
$vmSubnet = New-SCVMSubnet -Name $NetworkName -LogicalNetworkDefinition $logicalNetworkDefinition -SubnetVLan $subnetVLAN -VMNetwork $vmNetwork
}
}

Function RemoveVMNetwork {
	param($LogicalNetwork,$NetworkName)
	
$VMNetwork = Get-scvmnetwork -name $NetworkName
$VMSubnet = Get-SCVMSubnet -name $VMNetwork
$UplinkPortProfile = Get-SCNativeUplinkPortProfile | where {$_.LogicalNetworkDefinitions.Name -match $VMNetwork}
$logicalNetwork = Get-SCLogicalNetwork -Name $LogicalNetwork

#Remove Logical Network Definition from Uplink Port Profile
$logicalNetworkDefinitionsToRemove += Get-SCLogicalNetworkDefinition -Name $NetworkName
Set-SCNativeUplinkPortProfile -NativeUplinkPortProfile $UplinkPortProfile -RemoveLogicalNetworkDefinition $logicalNetworkDefinitionsToRemove

#Remove VM Network
Remove-SCVMNetwork -VMNetwork $VMNetwork

#Remove Logical Network Definition from Logical Network
$logicalNetworkDefinition = Get-SCLogicalNetworkDefinition -LogicalNetwork $logicalNetwork -Name $NetworkName
Remove-SCLogicalNetworkDefinition -LogicalNetworkDefinition $logicalNetworkDefinition
}





