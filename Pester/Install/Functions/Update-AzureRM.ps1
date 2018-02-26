Function Update-AzureRM {
    [CmdletBinding()]
    param(
        [String]$Repository = "psgallery"
    )

    Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss'): $($MyInvocation.MyCommand.Name): Starting"

    $LatestVersion = (Find-Module -Name 'AzureRm' -Repository $Repository).Version
    $InstalledVersion = (Get-Package -Name 'AzureRM' -ErrorAction 'SilentlyContinue').Version

    If ([System.Version]$InstalledVersion -lt [System.Version]$LatestVersion) {
        Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss'): $($MyInvocation.MyCommand.Name): Trying to remove $($InstalledVersion)"
        Get-Package -Name 'AzureRM' -ErrorAction 'SilentlyContinue' | Uninstall-Package -AllVersions -Force -ErrorAction 'SilentlyContinue'
        #Remove any lingering previous versions of AzureRM (sub)modules
        Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss'): $($MyInvocation.MyCommand.Name): Trying to remove any lingering AzureRM (sub)modules"
        $RemoveFailed = @()
        Do {
            $AzureRMSubmodules = Get-Package | Where-Object -Property Name -like "AzureRM.*"
            foreach ($ARMRemove in $RemoveFailed) {
                $AzureRMSubmodules = $AzureRMSubmodules | Where-Object {$AzureRMSubmodules.Name -notcontains $ARMRemove.Name}
            }
            foreach ($ARMModule in $AzureRMSubmodules) {
                Try {
                    $ARMModule | Uninstall-Package -AllVersions -Force -ErrorAction 'Stop'
                }
                Catch {
                    $RemoveFailed += $ARMModule
                }
            }
        }While ($AzureRMSubmodules)
        $AzureSubmodules = Get-Package | Where-Object -Property Name -like "Azure*"
        #Only remove submodules when the azure module itself is NOT installed
        $RemoveFailed = @()
        If ($AzureSubModules.name -notcontains 'Azure') {
            Do {
                #Select submodules only
                $AzureSubmodules = Get-Package | Where-Object -Property Name -like "Azure.*"
                foreach ($ARemove in $RemoveFailed) {
                    $AzureSubmodules = $AzureSubmodules | Where-Object {$AzureSubmodules.Name -notcontains $ARemove.Name}
                }
                foreach ($AModule in $AzureSubmodules) {
                    Try {
                        $AModule | Uninstall-Package -AllVersions -Force -ErrorAction 'Stop'
                    }
                    Catch {
                        $RemoveFailed += $AModule
                    }
                }
            }While ($AzureSubmodules)
        }
        Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss'): $($MyInvocation.MyCommand.Name): Installing $($LatestVersion)"
        Try {
            Install-Module -Name 'AzureRm' -Repository $Repository -Force -ErrorAction 'Stop'
        }
        Catch {
            Install-Module -Name 'AzureRm' -Repository $Repository -Force -AllowClobber
        }
    }
    Else {
        Write-Debug -Message "$(Get-Date -Format 'HH:mm:ss'): $($MyInvocation.MyCommand.Name): Latest module $($LatestVersion) already installed. Skipping"
    }
}