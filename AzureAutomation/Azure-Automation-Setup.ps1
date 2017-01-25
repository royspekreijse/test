#region setup
$WorkingDir = $psISE.CurrentFile.FullPath | Split-Path
Set-Location $WorkingDir

#Log on to Azure environment
Add-AzureRmAccount -SubscriptionName "Visual Studio Premium met MSDN"

#Get Azure Automation Account
$AAAccT = Get-AzureRmAutomationAccount -Name 'CSAutomation' -ResourceGroupName 'CS'

#endregion setup

#Initialize blob storage; New-AzureRmAutomationModule only accepts URI and no direct\local URL
Try
{
    $StorageAcct = Get-AzureRmStorageAccount -ResourceGroupName $AAAcct.ResourceGroupName -ErrorAction Stop
}
Catch 
{
    $StorageAcct = New-AzureRmStorageAccount -ResourceGroupName $AAAcct.ResourceGroupName -Name dscmodules -Type Standard_LRS -Location westeurope
}

Try
{
    $StorageAcct | Get-AzureStorageContainer -Name dscmodules -ErrorAction Stop
}
Catch
{
    $null = $StorageAcct | New-AzureStorageContainer -Name dscmodules -Permission Container
}

#region download public modules
#http://stackoverflow.com/questions/16597874/powershell-retrieve-file-from-github
#https://gallery.technet.microsoft.com/scriptcenter/a-GitHub-Repository-265c0b49
#https://www.powershellgallery.com/packages/DownloadGithub/1.0/Content/DownloadGithub.ps1

$ModulesPath = (Join-Path -Path $WorkingDir  -ChildPath "Modules")
$WebModules = @('xActiveDirectory','xComputerManagement','xDnsServer','xNetworking')

ForEach ($WebModule in $WebModules) {
    Find-Package -Name $WebModule | Save-Package -Path $ModulesPath
    Compress-Archive -Path "$($ModulesPath)\$($WebModule)" -DestinationPath "$($ModulesPath)\$($WebModule).zip"
    Remove-Item -Path "$($ModulesPath)\$($WebModule)" -Recurse -Force
}
#endregion download public modules

#region upload modules to BLOB storage & import into Azure Automation account
$ModulesInstalled = $AAAccT | Get-AzureRmAutomationModule 
$ModulesToInstall = Get-ChildItem $ModulesPath
#$Modules = Compare-Object -ReferenceObject ($ModulesInstalled.Name) -DifferenceObject ($ModulesToInstall.Name.Trim('.zip')) -PassThru
$Modules = $ModulesToInstall
Foreach ($Module in $Modules) {
    $ModuleUpload = Set-AzureStorageBlobContent -Context $StorageAcct.Context -Container dscmodules -File "$($ModulesPath)\$($Module).zip"
    $ModuleUpload.ICloudBlob.StorageUri.PrimaryUri.OriginalString
    $Upload = $AAAcct | New-AzureRmAutomationModule -Name $Module -ContentLink $ModuleUpload.ICloudBlob.StorageUri.PrimaryUri.OriginalString

    while ($Upload.ProvisioningState -ne 'Succeeded' -and $Upload.ProvisioningState -ne 'Failed') {
    $Upload = $Upload | Get-AzureRmAutomationModule
    $Upload.ProvisioningState
    Start-Sleep -Seconds 3
    }
    $Upload | Get-AzureRmAutomationModule
}
#endregion upload modules to BLOB storage


#region upload Runbooks
#PowerShell...
$PSRunbooksPath = (Join-Path -Path $WorkingDir  -ChildPath "PSRunbooks")
$Runbooks = Get-ChildItem $PSRunbooksPath
Foreach ($Runbook in $Runbooks) {
    $RunbookUpload = Set-AzureStorageBlobContent -Context $StorageAcct.Context -Container dscmodules -File "$($ModulesPath)\$($Runbook).zip"

}
#Workflow...
$WFRunbooksPath = (Join-Path -Path $WorkingDir  -ChildPath "WFRunbooks")
$Runbooks = Get-ChildItem $PSRunbooksPath
Foreach ($Runbook in $Runbooks) {
    $RunbookUpload = Set-AzureStorageBlobContent -Context $StorageAcct.Context -Container dscmodules -File "$($ModulesPath)\$($Runbook).zip"

}

#Endregion upload Runbooks



#Region import DSC configurations
#Import DSC configuration
$DSCConfigurations = (Join-Path -Path $WorkingDir  -ChildPath "DSCConfigurations")
Foreach ($DSCConfiguration in $DSCConfigurations) {
    $AAAccT | Import-AzureRmAutomationDscConfiguration -SourcePath $DSCConfiguration -Published -Force
}

#$AAAccT | Import-AzureRmAutomationDscConfiguration -SourcePath "$($env:USERPROFILE)\Documents\Github\" -Published -Force
$AAAccT | Get-AzureRmAutomationDscCompilation -Name 

#Compile DSC configuration
$Job = $AAAccT | Get-AzureRmAutomationDscCompilation -Name | Start-AzureRmAutomationDscCompilationJob

#wait for compile job to finish
while (-not($job | Get-AzureRmAutomationDscCompilationJob).endtime){Start-Sleep -Seconds 3}

#Show Node configurations
$AAAccT | Get-AzureRmAutomationDscNodeConfiguration
#Endregion import DSC configurations