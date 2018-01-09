function New-TableStatistics2 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Machines,
        [Parameter(Mandatory = $true)]
        [PSObject]$MachineReport,
        [int16]$NumberOfPreviousDays
    )

    #Set write-warning to better stand-out from verbose and debug info.
    $a = (Get-Host).PrivateData
    If ($a) {
        #Not every PS host has this capability
        $PreviousWarningBackgroundColor = $a.WarningBackgroundColor
        $PreviousWarningForegroundColor = $a.WarningForegroundColor
        $PreviousVerboseForegroundColor = $a.VerboseForegroundColor
        $a.WarningBackgroundColor = "red"
        $a.WarningForegroundColor = "white"
        $a.VerboseForegroundColor = 'cyan'
    }
    Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss:fff'): $($MyInvocation.MyCommand.Name): Starting"

    $DateString = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
    $Header = "CloudSuite Reporting - TableStatistics created on $($DateString)"
    $Files = @()

    $Info = [String]::Empty
    #Machines
    $ActiveMachines = $Machines | Where-Object {$_.Status -eq 'Active'}
    $Info += "Machine table contains total of $($Machines.Count) machines`n"
    $IaaSMachines = $ActiveMachines | Where-Object {$_.SubscriptionID -ne '10000000-0000-0000-0000-000000000001' -or $_.SubscriptionID -ne $null -or $_.SubscriptionID -ne '' }
    $AllFW = $IaaSMachines | Where-Object vmName -like "*-fw*"
    $Info += "Machine table contains total of $($IaaSMachines.Count) active machines registered in an IaaS`n"
    $NoIaaSMachines = $ActiveMachines | Where-Object {$_.SubscriptionID -eq '10000000-0000-0000-0000-000000000001' -or $_.SubscriptionID -eq $null -or $_.SubscriptionID -eq '' }
    If ($NoIaaSMachines) {
        $Info += "WARNING: Machine table contains $($NoIaaSMachines.Count) active machine(s) which are not registered in any IaaS`n"
        $FileName = "$($env:TEMP)\Machines-NoIaaSMachines.json"
        $NoIaaSMachines | Select-Object computername, vmName, MAC, vmId | ConvertTo-Json | Out-File $FileName -force
        $Files += $FileName
        $Info += "`n"
    }

    #MachineReport
    For ($i = 0; $i -le $NumberOfPreviousDays; $i++) {
        $MachineReportDay = $MachineReport | Where-Object {$_.CreatedTimestamp -ge (Get-Date).AddDays( - $i).ToUniversalTime().ToString("yyyy-MM-ddT00:00:00.000Z") -and $_.CreatedTimestamp -lt (Get-Date).AddDays( - $i).ToUniversalTime().ToString("yyyy-MM-ddT23:59:59.999Z")}
        If ($MachineReportDay) {Break}

    }
    #Just get last result, if there have been multiple uploads (testing or other reason)
    $Result = @()
    $Grouped = $MachineReportDay | Group-object MAC # Detect multiple uploads within timeframe
    foreach ($Group in $Grouped) {
        $Result += $Group.Group[-1] #Just post last upload
    }
    $MachineReportDay = $Result
    $InfoDay = - $i
    $FWDay = $MachineReportDay | Where-Object vmName -like "*-fw*"
    $Info += "Last MachineReport created on $((Get-Date).AddDays($InfoDay).ToUniversalTime().ToString(`"yyyy-MM-dd`"))`n"
    If ($MachineReportDay.Count -lt $IaaSMachines.Count) {
        $Info += "WARNING: Missing $($IaaSMachines.Count-$MachineReportDay.Count) active machines in MachineReport table from ITON IaaS`n"
        $CompareResult = Compare-Object $IaaSMachines $MachineReportDay -Property vmId
        $MachineReportMissingIaaSMachines = @()
        foreach ($Item in $CompareResult) {
            If ($Item.SideIndicator -eq '<=') {
                $MachineReportMissingIaaSMachines += $IaaSMachines |Where-Object -property vmId -eq $Item.vmId
            }
        }
        $FileName = "$($env:TEMP)\MachineReport-MissingIaaSMachines.json"
        $MachineReportMissingIaaSMachines | Select-Object computername, vmName, MAC, vmId | ConvertTo-Json | Out-File $FileName -force
        $Files += $FileName
    }

    $MachineReportBruto = @()
    For ($i = 0; $i -lt $NumberOfPreviousDays; $i++) {
        #Last day is defined as 'error' day; total count back is more then $NumberOfPreviousDays then
        $DateString = (Get-Date).AddDays( - $i).ToUniversalTime().ToString("yyyy-MM-dd")
        $MachineReportCurrent = $MachineReportDay| Where-Object {$_.IaaSMetricsDate -eq $DateString}
        If ($MachineReportCurrent) {
            $Info += "$($MachineReportCurrent.Count) machines reported bruto values, created on $($DateString)`n"
            $MachineReportBruto += $MachineReportCurrent
        }
    }
    If ($MachineReportBruto.Count -eq $MachineReportDay.Count) {
        $Info += "All machines reported bruto values`n"
    }
    Else {
        $MachineReportNoBrutoValues = @()
        foreach ($Item in $CompareResult) {
            $Info += "WARNING: $($MachineReportDay.Count - $MachineReportBruto.Count) machines have no or older bruto values`n"
            Try {
                $CompareResult = Compare-Object $MachineReportBruto $MachineReportDay -Property vmId -ErrorAction Stop
                foreach ($Item in $CompareResult) {
                    If ($Item.SideIndicator -eq '=>') {
                        $MachineReportNoBrutoValues += $IaaSMachines |Where-Object -property vmId -eq $Item.vmId
                    }
                }
            }
            Catch {
                $MachineReportNoBrutoValues = $MachineReportDay
            }
            $FileName = "$($env:TEMP)\MachineReport-NoBrutoValues.json"
            $MachineReportNoBrutoValues | Select-Object computername, vmName, MAC, vmId | ConvertTo-Json | Out-File $FileName -force
            $Files += $FileName
        }
    }

    $MachineReportNetto = @()
    For ($i = 0; $i -lt $NumberOfPreviousDays; $i++) {
        #Last day is defined as 'error' day; total count back is more then $NumberOfPreviousDays then
        $DateString = (Get-Date).AddDays( - $i).ToUniversalTime().ToString("yyyy-MM-dd")
        $MachineReportCurrent = $MachineReportDay| Where-Object {$_.MachineMetricsDate -eq $DateString}
        $MachineReportCurrent = $MachineReportCurrent | Where-Object NettoOSSize -gt 0 # There must also be values!
        If ($MachineReportCurrent ) {
            $Info += "$($MachineReportCurrent.Count) machines reported netto values, created on $($DateString)`n"
            $MachineReportNetto += $MachineReportCurrent
        }
    }
    If ($MachineReportNetto.Count -eq $MachineReportDay.Count) {
        $Info += "All machines reported netto values`n"
    }
    Else {
        $MachineReportNoNettoValues = @()
        $Info += "WARNING: $($MachineReportDay.Count - $MachineReportNetto.Count) machines have no or older netto values`n"
        Try {
            $CompareResult = Compare-Object $MachineReportNetto $MachineReportDay -Property vmId -ErrorAction Stop
            foreach ($Item in $CompareResult) {
                If ($Item.SideIndicator -eq '=>') {
                    $MachineReportNoNettoValues += $IaaSMachines |Where-Object -property vmId -eq $Item.vmId
                }
            }
        }
        Catch {
            $MachineReportNoNettoValues = $MachineReportDay
        }
        $FileName = "$($env:TEMP)\MachineReport-NoNettoValues.json"
        $MachineReportNoNettoValues | Select-Object computername, vmName, MAC, vmId | ConvertTo-Json | Out-File $FileName -force
        $Files += $FileName
    }

    return [PSCustomObject] @{
        Header = $Header
        Info   = $Info
        Files  = $Files
    }

    If ($a) {
        $a.WarningBackgroundColor = $PreviousWarningBackgroundColor
        $a.WarningForegroundColor = $PreviousWarningForegroundColor
        $a.VerboseForegroundColor = $PreviousVerboseForegroundColor
    }
}