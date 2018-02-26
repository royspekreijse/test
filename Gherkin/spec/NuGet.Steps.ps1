$TestPassed = $true

Given 'a windows based machine with minimum OS level 2012R2' {
    Switch ($TestPassed) {
        $false { Set-TestInconclusive -Message "previous step not passed" }
        Default {    
            #Detect OS version/type
            $OSVersion = [System.Environment]::OSVersion.Version
            $TestPassed = [System.Version]"$($OSVersion.Major).$($OSVersion.Minor)" -ge [System.Version]'6.2'
            $TestPassed | Should Be $true
        }
    }
}

Given 'a working Internet connection' {
    Switch ($TestPassed) {
        $false { Set-TestInconclusive -Message "previous step not passed" }
        Default {
            $TestPassed = $false
            Try { 
                Test-Connection -ComputerName 8.8.8.8 -Count 1 -ErrorAction Stop
                $TestPassed = $true
            } 
            Catch {}
            $TestPassed | Should Be $true
        }
    }   
}

Given 'PowerShell 5.0 or higher present' {
    Switch ($TestPassed) {
        $false { Set-TestInconclusive -Message "previous step not passed" }
        Default {
            $TestPassed = $PSVersionTable.PSVersion -ge '5.0'
            $TestPassed | Should Be $true
        }
    }   
}

Given 'PowerShell session is running elevated' {
    #Source: https://blogs.msdn.microsoft.com/virtual_pc_guy/2010/09/23/a-self-elevating-powershell-script/
    # Get the ID and security principal of the current user account
    $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
    
    # Get the security principal for the Administrator role
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

    # Check to see if we are currently running "as Administrator"
    $TestPassed = $myWindowsPrincipal.IsInRole($adminRole) 
    $TestPassed | Should Be $true
}

Given 'latest NuGet package provider is not installed' {
    Switch ($TestPassed) {
        $false { Set-TestInconclusive -Message "previous step not passed" }
        Default {    
            $Latest = Find-PackageProvider -Name 'NuGet'
            $Installed = Get-PackageProvider -Name 'NuGet'
            $TestPassed = $Installed.Version -lt $Latest.Version 
            $TestPassed | Should Be $true
        }
    }
}

Then 'install latest NuGet package provider' {
    Switch ($TestPassed) {
        $false { Set-TestInconclusive -Message "previous step not passed" }
        Default {
            $TestPassed = $false
            $Latest = Find-PackageProvider -Name 'NuGet'
            $Installed = Get-PackageProvider -Name 'NuGet'
            If ($Installed.Version -lt $Latest.Version) { 
                Try {
                    Install-PackageProvider -Name 'NuGet' -Force -ErrorAction Stop
                    $TestPassed = $true
                } 
                Catch {}
            }
            $TestPassed | Should Be $true
        }
    }
}

