#Just call all functions as resources, if exists
If (Test-Path (Join-Path -Path $PSScriptRoot -ChildPath 'Functions' )){
    Get-ChildItem (Join-Path -Path $PSScriptRoot -ChildPath 'Functions' ) | Where-Object { $_.Name -notlike '_*' -and $_.Name -notlike '*.tests.ps1' -and $_.Name -like '*.ps1'} | ForEach-Object { . $_.FullName }
}

#Just call all helperfunctions as resources, if exists. Call it here, so it gets loaded only once....
If (Test-Path (Join-Path -Path $PSScriptRoot -ChildPath 'Functions\HelperFunctions' )){
    Get-ChildItem (Join-Path -Path $PSScriptRoot -ChildPath 'Functions\HelperFunctions' ) | Where-Object { $_.Name -notlike '_*' -and $_.Name -notlike '*.tests.ps1' -and $_.Name -like '*.ps1'} | ForEach-Object { . $_.FullName }
}


function Test-ModuleFunction
{
    [CmdletBinding()]
    param ( )

    Write-Host "$($MyInvocation.MyCommand.Name): ErrorActionPreference = $ErrorActionPreference"
}

function Test-ModuleFunction2
{
    [CmdletBinding()]
    param ( )

    $ErrorActionPreference = 'Stop'
    Write-Host "$($MyInvocation.MyCommand.Name): ErrorActionPreference = $ErrorActionPreference"
}
