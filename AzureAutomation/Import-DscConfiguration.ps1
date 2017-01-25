#Log on to Azure environment
Add-AzureRmAccount -SubscriptionName "Visual Studio Premium met MSDN"

#Get Azure Automation Account
$AAAccT = Get-AzureRmAutomationAccount -Name 'CSAutomation' -ResourceGroupName 'CS'

#Import DSC configuration
$AAAccT | Import-AzureRmAutomationDscConfiguration -SourcePath "$($env:USERPROFILE)\Documents\Github\" -Published -Force
$AAAccT | Get-AzureRmAutomationDscCompilation -Name 

#Compile DSC configuration
$Job = $AAAccT | Get-AzureRmAutomationDscCompilation -Name | Start-AzureRmAutomationDscCompilationJob

#wait for compile job to finish
while (-not($job | Get-AzureRmAutomationDscCompilationJob).endtime){Start-Sleep -Seconds 3}

#Show Node configurations
$AAAccT | Get-AzureRmAutomationDscNodeConfiguration



$ACT |  Get-AzureRmAutomationRegistrationInfo

Get-Command -Module AzureRM.Automation -Noun azurermautomationdsc*