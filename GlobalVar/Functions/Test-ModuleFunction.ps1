
function Test-ModuleFunction
{
    [CmdletBinding()]
    param ( )

    Write-Host "$($MyInvocation.MyCommand.Name): ErrorActionPreference = $ErrorActionPreference"
}