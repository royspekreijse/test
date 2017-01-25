function Install-AAOnboarding{
    [CmdletBinding()]
    param(
        [string]$ScheduleExecute = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
        [string]$ScheduleArgument = "-NonInteractive -NoProfile -ExecutionPolicy Unrestricted -Command Import-Module AAOnboarding;Start-AAOnboarding",
        [string]$LogPath = 'C:\Support\Logging',
        [bool]$Logging = $false #For debugging
    )

    If ($Logging)
    {
        $PreviousVerbosePreference = $VerbosePreference
        $VerbosePreference = "Continue"
        If (!(Test-path -Path $LogPath)){New-Item -Path $LogPath -ItemType Directory}
        Start-Transcript "$($LogPath)\$($MyInvocation.MyCommand.Name).log"
    }

    #Plan the full AV scan
    $action = New-ScheduledTaskAction -Execute $ScheduleExecute -Argument $ScheduleArgument
    $trigger =  New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\System" -RunLevel "Highest"
    Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "AAOnboarding" -Description "ITON Azure Automation DSC onboarding script"

    If ($Logging)
    {
        $PreviousVerbosePreference = $VerbosePreference
        Stop-Transcript
    }
}

function Start-AAOnboarding{
    [CmdletBinding()]
    param(
        [string]$onboardURL = "http://acceptatie.configurator.cloud-suite.nl/configuration/deploy",
        [string]$MOFPath = 'C:\Support\MOF',
        [string]$LogPath = 'C:\Support\Logging',
        [bool]$Logging = $true #For debugging
    )

    If ($Logging)
    {
        $PreviousVerbosePreference = $VerbosePreference
        $VerbosePreference = "Continue"
        If (!(Test-path -Path $LogPath)){New-Item -Path $LogPath -ItemType Directory}
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


    If ($Logging)
    {
        #Clean-up
        $VerbosePreference = $PreviousVerbosePreference
        Stop-Transcript
    }
}

