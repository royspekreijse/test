remove-module machinereport -ErrorAction SilentlyContinue
import-module C:\Users\peppe\OneDrive\GitHub\CS-Analytics\MachineReport\0.1.2\MachineReport.psd1
Publish-TableStatistics -Force -storageaccountname csanalytics

$MissingIaaSMachines = Get-content C:\Temp\20171208\MachineReport-MissingIaaSMachines.json -raw |convertfrom-json
$NoNettoValues = Get-content C:\Temp\20171208\MachineReport-NoNettoValues.json -raw |convertfrom-json
$NoIaaSMachines = Get-content C:\Temp\20171208\Machines-NoIaaSMachines.json -raw |convertfrom-json

$Result = @()
foreach ($IM in $MissingIaaSMachines){
 $Result += $machines | Where vmId -eq $IM.vmid 
}
$result | ft TimeStamp,PartitionKey,vmName, MAC
$Result | where VMName | ft TimeStamp,PartitionKey,vmName, MAC, vmid

$NNVFW = @()
foreach ($NNV in $NoNettoValues){
 $NNVFW += $machines | Where vmId -eq $NNV.vmid | where vmname -like "*-fw*"
}
$NNVFW | ft TimeStamp,PartitionKey,vmName, MAC, computername

$AllFW = $machines | where vmname -like "*-fw*" | where status -eq 'Active'|ft vmname, vmid

$match = @()
foreach ($NoIaaS in $NoIaaSMachines){
   $match +=  $MissingIaaSMachines | Where vmId -ne $NoIaaS.vmid
}

$NumberOfPreviousDays = 7
#MachineReport
    For ($i = 0; $i -le $NumberOfPreviousDays; $i++) {
        $MachineReportDay = $MachineReport | Where-Object {$_.Timestamp -ge (Get-Date).AddDays( - $i).ToUniversalTime().ToString("yyyy-MM-ddT00:00:00.000Z") -and $_.Timestamp -lt (Get-Date).AddDays( - $i).ToUniversalTime().ToString("yyyy-MM-ddT23:59:59.999Z")}
        If ($MachineReportDay) {Break}

    }
$MachineReportDay | where vmname -like "*-fs*" | Export-Csv c:\temp\fs.csv
