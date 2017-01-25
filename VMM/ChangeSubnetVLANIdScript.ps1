    <#
    .Synopsis
    Changes a VLANId for a Subnet within a Logical Network Site Definition in SCVMM
    .DESCRIPTION
    Changes a VLANId for a Subnet within a Logical Network Site Definition in SCVMM. Optionally
    it changes all dependent VM Network Adapters to the new VLANId

    .EXAMPLE
    Change-SubnetVLANId -NetworkDefinitionName "LNET-TEST" -OldVLANId 31 -NewVLANId 33 -UpdateVMNetworkAdapters

    This changes the VLANId from 31 to 33 for the SubNet Definition in the Logical Network Definition named "LNET-TEST"
    and changes all dependent VM Network Adapters to the new VLANId

    .EXAMPLE
    Change-SubnetVLANId -NetworkDefinitionName "LNET-TEST" -OldVLANId 31 -NewVLANId 33 -UpdateVMNetworkAdapters -Verbose -WhatIf

    Prints verbose Logging Information and proceeds with whatIf (without changing anything, but show what would happen)
    .PARAMETER NetworkDefinitionName
    Name of the Network Site Definition

    .PARAMETER OldVLANId
    The existing VLANId

    .PARAMETER NewVLANId
    The new VLANId
	
	.PARAMETER UpdateVMNetworkAdapters
	If this Switch is provided, the script tries to update all VM Network Adapters connected to the existing VLANId
	
	.PARAMETER VMMServer
	If specified, Script contacts the supplied VMM Server, otherwise it tries LOCALHOST

    .NOTES
    version 1.2
    Written by Michael Rüefli, February 2014
    Changes:
    V1.1 / Fixed Bug when newVLANID is set to 0 (no tagging)
    V1.2 / Added Support for multiple Network Definitions with same Name
#>
    
    [CmdletBinding(SupportsShouldProcess=$True)]
    param(
    [Parameter(Mandatory=$true)]
    [STRING]$NetworkDefinitionName,
    [Parameter(Mandatory=$true)]
    [INT]$OldVLANId,
    [Parameter(Mandatory=$true)]
    [INT]$NewVLANId,
    [Parameter(Mandatory=$false)]
    [SWITCH]$UpdateVMNetworkAdapters,
	[Parameter(Mandatory=$false)]
    [STRING]$VMMServer="LOCALHOST"
    )

    #Connect to SCVMM
	Get-SCVMMServer -ComputerName $VMMServer

    #Get the Logical Network Definition (Network Site Definition)
    $LogicalNetWorkDefinition = Get-SCLogicalNetworkDefinition -Name $NetworkDefinitionName
    If (!$LogicalNetWorkDefinition)
    {
        Write-Warning "No Logical Network Definition found matching name: $NetworkDefinitionName"
        break
    }
    ElseIf ($LogicalNetWorkDefinition.count -gt 1) #If we found multiple matching Definitions, user must select one from list
    {
        Write-Warning "More than one Network Definition found matching name: $NetworkDefinitionName"
        $NetWorkDefinitionList = @()
        $idef = 0
        Foreach ($def in $LogicalNetWorkDefinition)
        {
            $idef ++
            $defobj = New-Object -TypeName PSObject -Property @{
                "Index"=$idef
                "Network Definition Name" = $def.Name
                "ID"=$def.ID
                "LogicalNetwork"=$def.LogicalNetwork
            }
            $NetWorkDefinitionList += $defobj
        }
        $NetWorkDefinitionList
        $selectedIndex = Read-Host "Select the Index Number of the Network Definition you want to change"
        $selectedDefinition = $NetWorkDefinitionList | ? {$_.Index -eq $selectedIndex}
        $LogicalNetWorkDefinition = Get-SCLogicalNetworkDefinition | ? {$_.ID -eq $selectedDefinition.ID}
    }

    #Get the Subnet VLANs from the Network Site Definition
    $SubnetVLANs = $LogicalNetWorkDefinition.SubnetVLans

    #If Site has only a single Subnet Definition, proceed here
    If ($SubnetVLANs.count -eq 1)
    {
        $subnet = $SubnetVLANs.Subnet
        $NewSubnetVlan = New-SCSubnetVLan -Subnet $subnet -VLanID $NewVLANId
        $NewSubnetVlan
        #Update the Subnet / VLAN Definition
        If ($PSCmdlet.ShouldProcess("Setting SubNetVlans: $SubnetVLANs on: $NetworkDefinitionName"))
        {
            Set-SCLogicalNetworkDefinition -LogicalNetworkDefinition $LogicalNetWorkDefinition -SubnetVLan $NewSubnetVlan | out-null
        }
        
        If ($UpdateVMNetworkAdapters)
        {
            #Get the VM Nics mapped to old VLAN ID and reassign them to the new VLAN ID
            $VMNics = Get-SCVirtualMachine | Get-SCVirtualNetworkAdapter | ? {$_.VLanID -eq $OldVLANId}
            Foreach ($nic in $VMNics)
            {
                If ($PSCmdlet.ShouldProcess("Changing VM NetworkAdapter(s) for VM: $($nic.name)  to VLanID: $NewVLANId"))
                {
                    Write-Verbose "Updating VM Networkadapter VLAN Mapping for VM: $($nic.name) to VLanID: $NewVLANId"
                    $nic | Set-SCVirtualNetworkAdapter -VLanID $NewVLANId | Out-Null
                }
            }
        }
    }
    #We jump in here, if the Site has multiple Subnet Definitions
    Else
    {
        $SubnetToReplace = $SubnetVLANs | ? {$_.VLanID -eq $OldVLANId}
        $subnet = $SubnetToReplace.Subnet
        $SubnetVLANs.Remove($SubnetToReplace)
        $SubnetVLANs += New-SCSubnetVLan -Subnet $subnet -VLanID $NewVLANId
        
        If ($PSCmdlet.ShouldProcess("Setting SubNetVlans: $SubnetVLANs on: $NetworkDefinitionName"))
        {
            Set-SCLogicalNetworkDefinition -LogicalNetworkDefinition $LogicalNetWorkDefinition -SubnetVLan $SubnetVLANs | Out-Null
        }
        If ($UpdateVMNetworkAdapters)
        {
            #Get the VM Nics mapped to old VLAN ID and reassign them to the new VLAN ID
            $VMNics = Get-SCVirtualMachine | Get-SCVirtualNetworkAdapter | ? {$_.VLanID -eq $OldVLANId}
            Foreach ($nic in $VMNics)
            {
                If ($PSCmdlet.ShouldProcess("Changing VM NetworkAdapter(s) for VM: $($nic.name)  to VLanID: $NewVLANId"))
                {
                    Write-Verbose "Updating VM Networkadapter VLAN Mapping for VM: $($nic.name) to VLanID: $NewVLANId"
                    $nic | Set-SCVirtualNetworkAdapter -VLanID $NewVLANId | out-null
                } 
            }
        }
    }

