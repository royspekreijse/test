[CmdletBinding()]
param(
    [string]$onboardURL = "http://acceptatie.configurator.cloud-suite.nl/configuration/deploy",
    [string]$MOFPath = 'C:\Support\MOF',
    [bool]$MyVerbose = $false #For debugging
)

If ($MyVerbose)
{
    $PreviousVerbosePreference = $VerbosePreference
    $VerbosePreference = "Continue"

    Start-Transcript "$($PSScriptRoot)\$($MyInvocation.MyCommand.Name).log"
}

If (!(Test-path -Path $MOFPath)){New-Item -Path $MOFPath -ItemType Directory}

$keys = @()
$keys = (Invoke-WebRequest -Uri $onboardURL -UseBasicParsing).Content|ConvertFrom-Json 
While (($keys|Get-Member).Name -notcontains "Endpoint"){
    $keys = @()
    $keys = (Invoke-WebRequest -Uri $onboardURL -UseBasicParsing).Content|ConvertFrom-Json 
    Start-Sleep -Seconds 60
}

[DscLocalConfigurationManager()]
configuration LCM {

    param (
        #It is not possible to use de $key object as a parameter; this results in an error on calling the DSC function.
        [Parameter(Mandatory)]
        [string]$KeyEndPoint,
        [Parameter(Mandatory)]
        [string]$KeyPrimaryKey
    )

    Settings {
        ConfigurationMode = 'ApplyOnly'
        RefreshMode = 'Pull'
        RefreshFrequencyMins = 30
        RebootNodeIfNeeded = $true
        ActionAfterReboot = 'ContinueConfiguration'
        ConfigurationModeFrequencyMins = 15
    }

    ConfigurationRepositoryWeb AADSC {
        ServerURL = $KeyEndPoint
        RegistrationKey = $KeyPrimaryKey
    }

    ResourceRepositoryWeb AADSC {
        ServerURL = $KeyEndPoint
        RegistrationKey = $KeyPrimaryKey
    }

    ReportServerWeb AADSC {
        ServerURL = $KeyEndPoint
        RegistrationKey = $KeyPrimaryKey
    }
}

#It is not possible to use de $key object as a parameter; this results in an error on calling the DSC function.
LCM -OutputPath $MOFPath -KeyEndpoint $Keys.Endpoint -KeyPrimaryKey $Keys.PrimaryKey

# Make sure that LCM is set          
Set-DSCLocalConfigurationManager -Path $MOFPath –Verbose          

#Remove this script from startup
Unregister-ScheduledTask -TaskName "AAOnboarding" -Confirm:$false

#Remove the local account
([adsi]"WinNT://$($env:COMPUTERNAME)").Delete('User','Automation') 


If ($MyVerbose)
{
    #Clean-up
    $VerbosePreference = $PreviousVerbosePreference
    Stop-Transcript
}

