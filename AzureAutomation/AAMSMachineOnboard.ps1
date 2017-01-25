#$Password = read-host -assecurestring

#$AACredential = ([pscredential]::new('[account]',(ConvertTo-SecureString -String $Password -AsPlainText -Force)))
#$AACredential = ([pscredential]::new('[account]',(read-host -assecurestring)))
#$AACredential = New-Object -TypeName System.Management.Automation.PSCredential -Argumentlist '[account]', (read-host -assecurestring)
#$AACredential = New-Object -TypeName System.Management.Automation.PSCredential -Argumentlist '[account]', (ConvertTo-SecureString -String "[password]" -AsPlainText -Force)


[CmdletBinding()]
Param(
    [Credential]$AACredential,
    [String]$AASubscriptionName = "Visual Studio Premium met MSDN"
)

#region setup
$MOFPath = 'C:\Support\MOF'

If (Test-Path -Path $MOFPath){New-Item -Path $MOFPath-ItemType Directory}
#Push-Location
#Set-Location $PSScriptRoot # This is an automatic variable set to the current file's/module's directory, PowerShell 3+

#Import the AzureRM modules
If (!((Get-Package).Name -contains 'AzureRM')){Install-Package AzureRM -Force -Confirm:$false}

#Disable data collection, othwerwise this will be asked at first next command, introducing 30second wait time
Disable-AzureDataCollection

#Log on to Azure environment
Add-AzureRmAccount -SubscriptionName $AASubscriptionName -Credential $AACredential

#Get Azure Automation Account
$AAAccT = Get-AzureRmAutomationAccount -Name 'CSAutomation' -ResourceGroupName 'CS'

#endregion

#region create own meta.mof
$Keys = $AAAcct | Get-AzureRmAutomationRegistrationInfo
[DscLocalConfigurationManager()]
configuration LCM {

    param (
        [Parameter(Mandatory,ValueFromPipeline)]
        $Keys
    )

    Settings {
        ConfigurationMode = 'ApplyOnly' #Possible values 'ApplyAndAutoCorrect','ApplyOnly','ApplyAndMonitor'
        RefreshMode = 'Pull'
        RefreshFrequencyMins = 30
        RebootNodeIfNeeded = $true
        ActionAfterReboot = 'ContinueConfiguration'
        ConfigurationModeFrequencyMins = 15
    }

    ConfigurationRepositoryWeb AADSC {
        ServerURL = $Keys.Endpoint
        RegistrationKey = $Keys.PrimaryKey
    }

    ResourceRepositoryWeb AADSC {
        ServerURL = $Keys.Endpoint
        RegistrationKey = $Keys.PrimaryKey
    }

    ReportServerWeb AADSC {
        ServerURL = $Keys.Endpoint
        RegistrationKey = $Keys.PrimaryKey
    }
}
$Keys | LCM -OutputPath $$MOFPath

Set-DscLocalConfigurationManager -Path $MOFPath -Force

<#
#registration key -> cert
Get-Content C:\Windows\System32\Configuration\Metaconfig.mof -Encoding Unicode
Get-Content C:\Windows\System32\Configuration\Metaconfig.mof -Encoding Unicode | Select-String 'RegistrationKey'
Get-Content c:\localhost.meta.mof | Select-String 'RegistrationKey'
Remove-Item c:\localhost.meta.mof -Force
Get-ChildItem -Path cert:\localmachine\my | Select-Object *
$thumbprint = (Get-ChildItem -Path cert:\localmachine\my).Thumbprint
Get-Content C:\Windows\system32\Configuration\DSCEngineCache.mof -Encoding Unicode | Select-String $thumbprint
#endregion

Pop-Location
#>