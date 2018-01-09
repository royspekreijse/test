    #Report is disk based. Get each machine
    $VirtualMachines = @()
    $VirtualMachines = $Report | Sort-Object -Property vmId -Unique

    $Totals = @()
    #Get the totals and publish to table
    #$Ctx = New-AzureStorageContext -StorageAccountName $AzureTableSettings.StorageAccountName -StorageAccountKey $AzureTableSettings.StorageKey
    #$MachineReportTableObj = Get-AzureStorageTable -Name $AzureTableSettings.MachineReportTable -Context $Ctx
    Foreach ($VM in $VirtualMachines) {
        #$Property = @{}
        $Totals += Get-Totals -Disk ($Report | Where-Object VMName -eq $VM.VMName)
        #$Totals[0].PSObject.Properties | ForEach-Object { $Property[$_.Name] = $_.Value }
        #$PartitionKey = $Property.CustomerID
        #$Property.Remove('CustomerID')
        #Remove empty values, otherwise errors on upload
        #If (($Property.HeartBeat -eq $null) -or ($Property.HeartBeat -eq "")) {$Property.HeartBeat = [String]::Empty}
        #If (($Property.Status -eq $null) -or ($Property.Status -eq "")) {$Property.Status = [String]::Empty}
        #If (($Property.Computername -eq $null) -or ($Property.Computername -eq "")) {$Property.Computername = [String]::Empty}
        #Write-Verbose -Message "$($MyInvocation.MyCommand.Name): Adding entry in $($AzureTableSettings.MachineReportTable) for $($Property.VMName)."
        #Add the generic properties for this machine to the Machines table if it not yet exists
        #[PSCustomObject]$Property
        #Add-StorageTableRow -table $MachineReportTableObj  `
        #    -partitionKey $PartitionKey `
        #    -rowKey ([guid]::NewGuid().tostring()) `
        #    -property $Property `
        #    1>$null
    }