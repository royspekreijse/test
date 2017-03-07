#region setup
#$WorkingDir = $psISE.CurrentFile.FullPath | Split-Path
#Set-Location $WorkingDir

#[CmdletBinding()]
#Param(
    [PSCredential]$AACredential = [pscredential]::new('beheerder@peppekerstenshotmail.onmicrosoft.com',(ConvertTo-SecureString -String '@Welkom2017@' -AsPlainText -Force))
    [String]$AASubscriptionName = "Visual Studio Premium met MSDN"
#)

#region setup
$MOFPath = 'C:\Support\MOF'

#Log on to Azure environment
Add-AzureRmAccount -Credential $AACredential -SubscriptionName $AASubscriptionName 

#Add-AzureRmAccount
$AAAcct = Get-AzureRmAutomationAccount -Name 'CSAutomation' -ResourceGroupName 'CS'


function Wait-AADSCCompileJob {
    param (
        [parameter(Mandatory,ValueFromPipeline)]
        [Microsoft.Azure.Commands.Automation.Model.CompilationJob] $CompileJob,

        [int] $Sleep = 2,

        [Switch] $PassThru
    )
    process {
        while ($null -eq $CompileJob.EndTime -and $null -eq $CompileJob.Exception) {
            $CompileJob = $CompileJob | Get-AzureRmAutomationDscCompilationJob
            Start-Sleep -Seconds $Sleep
        }
        if ($PassThru) {
            Write-Output -InputObject $CompileJob
        }
    }
}
#endregion


$DSCConf1 = $AAAcct | Import-AzureRmAutomationDscConfiguration -SourcePath 'C:\Users\peppe\OneDrive\GitHub\CS-CloudDesktop\2016\CC\CC.ps1' `
                                                                    -Published -Force

#https://gallery.technet.microsoft.com/scriptcenter/ipcalc-PowerShell-Script-01b7bd23
#http://www.itadmintools.com/2011/08/calculating-tcpip-subnets-with.html
function toBinary ($dottedDecimal){
 $dottedDecimal.split(".") | %{$binary=$binary + $([convert]::toString($_,2).padleft(8,"0"))}
 return $binary
}
function toDottedDecimal ($binary){
 $i=0
 do {$dottedDecimal += "." + [string]$([convert]::toInt32($binary.substring($i,8),2)); $i+=8 } while ($i -le ($MaskBits-8))
 return $dottedDecimal.substring(1)
}
<#
$MaskBits = $ConfigurationData.NonNodeData.Network.MaskBits
$ipBinary = toBinary $ConfigurationData.NonNodeData.Network.SubnetID
$networkScope = toDottedDecimal $($ipBinary.substring(0,$MaskBits).padright($MaskBits,"0"))
$ReversedNetwork = [string]$networkScope -split '\.'
$Result = $null
for($x=($ReversedNetwork.Count -1); $x -ge 0; $x--){$Result += "$($ReversedNetwork[$x])."}
$ReversedDNSZoneName = "$($Result)in-addr.arpa" 
#>

$ReversedDNSZoneName = "9.17.172.in-addr.arpa" 

$DomainName = 'internal.john99.nl'
$DomainNetbiosName = 'john99'
$NodeName = 'john99-cc' 

$WebAccessServer = @()
$WebAccessServer = $ConfigurationData.AllNodes.Where{$_.Role.Name -icontains 'rdw'}.NodeName
$SessionHost = @()
$SessionHost = $ConfigurationData.AllNodes.Where{$_.Role.Name -icontains 'rdsh'}.NodeName

$WebAccessServer = 'john99-rdgw'
$SessionHost = 'john99-rdsh1'

$ParamSplat = @{
    NodeName = $NodeName
    DomainName = $DomainName
    DomainNetbiosName = $DomainNetbiosName
    safemodePassword = 'Test123_' 
    DomainAccountName = 'Administrator'
    DomainAccountPassword = 'Test123_'
    ReversedDNSZoneName = $ReversedDNSZoneName
    WebAccessServer = $WebAccessServer
    SessionHost = $SessionHost
}

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = $NodeName
            PsDscAllowPlainTextPassword = $true
        }
    )
}


$DSCompileJob = $DSCConf1 | Start-AzureRmAutomationDscCompilationJob -Parameters $ParamSplat -ConfigurationData $ConfigData
$DSCompileJob = $DSCompileJob | Wait-AADSCCompileJob -PassThru
$DSCompileJob
$DSCompileJob.JobParameters
#endregion


$DSCConf2 = $AAAcct | Import-AzureRmAutomationDscConfiguration -SourcePath 'C:\Users\peppe\OneDrive\GitHub\CS-CloudDesktop\2016\RDGW\RDGW.ps1' `                                                                   -Published -Force

$NodeName = 'john99-rdgw' 

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = $NodeName 
            PsDscAllowPlainTextPassword = $true
        }
    )
}

$ParamSplat = @{
    NodeName = $NodeName
    DomainName = $DomainName
    DomainAccountName = 'Administrator'
    DomainAccountPassword = 'Test123_'
    DNSIPAddress = @('172.17.9.2')
    OUPath = "OU=Computers,OU=Shared,DC=internal,DC=john99,DC=nl"
}

$DSCompileJob = $DSCConf2 | Start-AzureRmAutomationDscCompilationJob -Parameters $ParamSplat -ConfigurationData $ConfigData
$DSCompileJob = $DSCompileJob | Wait-AADSCCompileJob -PassThru
$DSCompileJob
$DSCompileJob.JobParameters


$DSCConf3 = $AAAcct | Import-AzureRmAutomationDscConfiguration -SourcePath 'C:\Users\peppe\OneDrive\GitHub\CS-CloudDesktop\2016\RDSH\RDSH.ps1' `
                                                                    -Published -Force
$NodeName = 'john99-rdsh1' 

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = $NodeName
            PsDscAllowPlainTextPassword = $true
        }
    )
}


$ParamSplat = @{
        NodeName = $NodeName
        DomainName = $DomainName
        DomainAccountName = 'Administrator'
        DomainAccountPassword = 'Test123_'
        DNSIPAddress = @('172.17.9.2')
        OUPath = "OU=Computers,OU=Shared,DC=internal,DC=john99,DC=nl"
}


$DSCompileJob = $DSCConf3 | Start-AzureRmAutomationDscCompilationJob -Parameters $ParamSplat -ConfigurationData $ConfigData
$DSCompileJob = $DSCompileJob | Wait-AADSCCompileJob -PassThru
$DSCompileJob
$DSCompileJob.JobParameters

<#
$AAAcct | New-AzureRmAutomationCredential -Name MyCreds -Value $params3.Credential

$Params3 = @{
    Credential = 'MyCreds'
}
$Params3CompileJob = $ImportParams3 | Start-AzureRmAutomationDscCompilationJob -Parameters $Params3 -ConfigurationData $ConfigData1
$Params3CompileJob = $Params3CompileJob | Wait-AADSCCompileJob -PassThru
$Params3CompileJob
$Params3CompileJob.JobParameters
#endregion

#region Configuration using AA Assets
<# ConfigWithAAAssets.ps1
configuration ConfigWithAAAssets {
    Import-DscResource -ModuleName PSDesiredStateConfiguration -ModuleVersion 1.1
    node localhost {
        
        $Cred = Get-AutomationPSCredential -Name MyCreds
        $UserName = Get-AutomationVariable -Name MyUserName

        user NewUser {
            UserName = $UserName
            Password = $Cred
            Ensure = 'Present'
            FullName = $UserName
        }
    }
}
#>

<#
psEdit $WorkingDir\ConfigWithAAAssets.ps1
$AAAcct | New-AzureRmAutomationVariable -Name MyUserName -Value 'Ben' -Encrypted $false

$ImportAssets = $AAAcct | Import-AzureRmAutomationDscConfiguration -SourcePath $WorkingDir\ConfigWithAAAssets.ps1 `
                                                                   -Published

$AssetsCompileJob = $ImportAssets | Start-AzureRmAutomationDscCompilationJob -ConfigurationData $ConfigData1
$AssetsCompileJob = $AssetsCompileJob | Wait-AADSCCompileJob -PassThru
$AssetsCompileJob
#endregion
#>


<#
#get statusreport from AA for supplied config
$Node = $AAAcct | Get-AzureRmAutomationDscNode -Name "piet44-cc"
$AAAcct | Get-AzureRmAutomationDscNodeReport -NodeId $Node.Id -Latest


$AAAcct | Set-AzureRmAutomationDscNode -NodeConfigurationName $ConfigName -Id $Node.Id
#>