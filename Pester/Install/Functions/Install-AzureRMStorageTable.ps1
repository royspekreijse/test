Function Install-AzureRmStorageTable {
    [CmdletBinding()]
    param(
        [String]$Repository = "psgallery"
    )

    Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss'): $($MyInvocation.MyCommand.Name): Starting"

    $LatestVersion = (Find-Module -Name 'AzureRmStorageTable' -Repository $Repository).Version
    $InstalledVersion = (Get-Package -Name 'AzureRmStorageTable' -ErrorAction 'SilentlyContinue').Version
    If ($InstalledVersion) {
        If ([System.Version]$InstalledVersion -lt [System.Version]$LatestVersion) {
            Get-Package -Name 'AzureRmStorageTable' | Uninstall-Package -AllVersions -Force
            Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss'): $($MyInvocation.MyCommand.Name): Trying to remove $($InstalledVersion)"
        }
    }
    If ([System.Version]$InstalledVersion -lt [System.Version]$LatestVersion) {
        Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss'): $($MyInvocation.MyCommand.Name): Installing $($LatestVersion)"
        Install-Module -Name 'AzureRmStorageTable' -Repository $Repository -Force
    }
    Else {
        Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss'): $($MyInvocation.MyCommand.Name): Latest module $($LatestVersion) already installed. Skipping"
    }
}