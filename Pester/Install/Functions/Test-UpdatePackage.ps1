Function Test-UpdatePackage {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name,
        [String]$Source
    )
    $SplatParam = @{
        Name = $Name
    }
    Try {
        $Installed = Get-Package @SplatParam -ErrorAction Stop #Somehow, Get-Module dus not always work at this point
        ($Source) -and ($SplatParam.Source = $Source) | out-null
        $Latest = Find-Package @SplatParam -ErrorAction Stop
        $Installed.Version -eq $Latest.Version
    }
    Catch {
        $false
    }
}