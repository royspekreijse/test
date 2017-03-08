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

<#
$CustomerName = 'john99'
$CustomerShortName = 'john99'
$CustomerID = 'kvk123456789'
$Password = 'Test123_'
$DomainAccountName = 'Administrator'
$DNSIPAddress = @('172.17.9.2')
$ReversedDNSZoneName = "9.17.172.in-addr.arpa" 
#>


$CustomerName = 'john100'
$CustomerShortName = 'john10'
$CustomerID = 'kvk987654321'
$Password = 'Test123_'
$DomainAccountName = 'Administrator'
$DNSIPAddress = @('172.17.37.2')
$ReversedDNSZoneName = "37.17.172.in-addr.arpa" 

$DomainName = "internal.$($CustomerName).nl"
$DomainNetbiosName = $CustomerName

$WebAccessServer = "$($CustomerShortName)-rdgw"
$SessionHost = "$($CustomerShortName)-rdsh1"
$ConnectionBroker = "$($CustomerShortName)-cc"


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


#$WebAccessServer = @()
#$WebAccessServer = $ConfigurationData.AllNodes.Where{$_.Role.Name -icontains 'rdw'}.NodeName
#$SessionHost = @()
#$SessionHost = $ConfigurationData.AllNodes.Where{$_.Role.Name -icontains 'rdsh'}.NodeName

$NodeName = "$($CustomerShortName)-cc"



$ParamSplat = @{
    NodeName = "$($NodeName)-$($CustomerID)"
    MachineName = $NodeName
    DomainName = $DomainName
    DomainNetbiosName = $DomainNetbiosName
    safemodePassword = $Password
    DomainAccountName = $DomainAccountName
    DomainAccountPassword = $Password
    ReversedDNSZoneName = $ReversedDNSZoneName
    WebAccessServer = $WebAccessServer
    SessionHost = $SessionHost
}

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "$($NodeName)-$($CustomerID)"
            PsDscAllowPlainTextPassword = $true
        }
    )
}


$DSCompileJob = $DSCConf1 | Start-AzureRmAutomationDscCompilationJob -Parameters $ParamSplat -ConfigurationData $ConfigData
$DSCompileJob = $DSCompileJob | Wait-AADSCCompileJob -PassThru
$DSCompileJob
$DSCompileJob.JobParameters
[console]::beep(500,300)
#endregion


$DSCConf2 = $AAAcct | Import-AzureRmAutomationDscConfiguration -SourcePath 'C:\Users\peppe\OneDrive\GitHub\CS-CloudDesktop\2016\RDGW\RDGW.ps1' `                                                                   -Published -Force

$NodeName = "$($CustomerShortName)-rdgw"

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "$($NodeName)-$($CustomerID)"
            PsDscAllowPlainTextPassword = $true
        }
    )
}

$ParamSplat = @{
    NodeName = "$($NodeName)-$($CustomerID)"
    MachineName = $NodeName
    DomainName = $DomainName
    DomainAccountName = $DomainAccountName
    DomainAccountPassword = $Password
    DNSIPAddress = $DNSIPAddress
    OUPath = "OU=Computers,OU=Shared,DC=internal,DC=$($CustomerName),DC=nl"
    ConnectionBroker = $ConnectionBroker
}

$DSCompileJob = $DSCConf2 | Start-AzureRmAutomationDscCompilationJob -Parameters $ParamSplat -ConfigurationData $ConfigData
$DSCompileJob = $DSCompileJob | Wait-AADSCCompileJob -PassThru
$DSCompileJob
$DSCompileJob.JobParameters
[console]::beep(500,300)

$DSCConf3 = $AAAcct | Import-AzureRmAutomationDscConfiguration -SourcePath 'C:\Users\peppe\OneDrive\GitHub\CS-CloudDesktop\2016\RDSH\RDSH.ps1' `
                                                                    -Published -Force
$NodeName = "$($CustomerShortName)-rdsh1"

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "$($NodeName)-$($CustomerID)"
            PsDscAllowPlainTextPassword = $true
        }
    )
}


$ParamSplat = @{
        NodeName = "$($NodeName)-$($CustomerID)"
        MachineName = $NodeName
        DomainName = $DomainName
        DomainAccountName = $DomainAccountName
        DomainAccountPassword = $Password
        DNSIPAddress = $DNSIPAddress
        OUPath = "OU=Computers,OU=Shared,DC=internal,DC=$($CustomerName),DC=nl"
        ConnectionBroker = $ConnectionBroker
}


$DSCompileJob = $DSCConf3 | Start-AzureRmAutomationDscCompilationJob -Parameters $ParamSplat -ConfigurationData $ConfigData
$DSCompileJob = $DSCompileJob | Wait-AADSCCompileJob -PassThru
$DSCompileJob
$DSCompileJob.JobParameters
[console]::beep(500,300)


$DSCConf4 = $AAAcct | Import-AzureRmAutomationDscConfiguration -SourcePath 'C:\Users\peppe\OneDrive\GitHub\CS-CloudDesktop\2016\RDSH\RDSH.ps1' `
                                                                    -Published -Force
$NodeName = "$($CustomerShortName)-rdsh2"

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = "$($NodeName)-$($CustomerID)"
            PsDscAllowPlainTextPassword = $true
        }
    )
}


$ParamSplat = @{
        NodeName = "$($NodeName)-$($CustomerID)"
        MachineName = $NodeName
        DomainName = $DomainName
        DomainAccountName = $DomainAccountName
        DomainAccountPassword = $Password
        DNSIPAddress = $DNSIPAddress
        OUPath = "OU=Computers,OU=Shared,DC=internal,DC=$($CustomerName),DC=nl"
        ConnectionBroker = $ConnectionBroker
}


$DSCompileJob = $DSCConf4    | Start-AzureRmAutomationDscCompilationJob -Parameters $ParamSplat -ConfigurationData $ConfigData
$DSCompileJob = $DSCompileJob | Wait-AADSCCompileJob -PassThru
$DSCompileJob
$DSCompileJob.JobParameters
[console]::beep(500,300)
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

start-sleep -seconds 1
[console]::beep(500,300)
start-sleep -seconds 1
[console]::beep(500,300)