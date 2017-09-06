function Test-ModuleFunction2
{
    [CmdletBinding()]
    param ( )

    $ErrorActionPreference = 'Stop'
    Write-Host "$($MyInvocation.MyCommand.Name): ErrorActionPreference = $ErrorActionPreference"
}