function New-gMSA{
    #Bron: https://blogs.technet.microsoft.com/askpfeplat/2012/12/16/windows-server-2012-group-managed-service-accounts/
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^\w{1,15}$")]# May not be longer than NetBiosName
        [string]$Name,
        [Parameter(
            Position=1, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('PrincipalsAllowedToRetrieveManagedPassword')]
        $Principals

    )

    If (!(Get-KDSRootKey)){Add-KDSRootKey –EffectiveImmediately}
    New-ADServiceAccount -name $gMSA -DNSHostName "$($gMSA).$((Get-ADDomain).DNSRoot))" -PrincipalsAllowedToRetrieveManagedPassword $Principals
}

If ((Get-WindowsFeature -Name 'RSAT-AD-PowerShell').InstallState -ne 'Installed'){
    Install-WindowsFeature -Name 'RSAT-AD-PowerShell'}
Get-ADComputer -filter {Name -eq 'worker1'}| New-gMSA -Name 'svc_scheduler'

<#
On client side:
If ((Get-WindowsFeature -Name 'RSAT-AD-PowerShell').InstallState -ne 'Installed'){
    Install-WindowsFeature -Name 'RSAT-AD-PowerShell'}
Install-AdServiceAccount 'svc_scheduler'
Test-AdServiceAccount 'svc_scheduler'
#>