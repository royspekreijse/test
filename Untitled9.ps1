function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]        
        [long]
        $InitialSize,
        [parameter(Mandatory = $true)]        
        [long]
        $MaximumSize,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    $ComputerSystem = Get-wmiobject win32_computersystem 
  
    if ($ComputerSystem.AutomaticManagedPageFile)
    {
        if ($Ensure -like 'Present')
        {
            Write-Verbose  $LocalizedData.AutomaticPageFileConfigured
            $ComputerSystem.AutomaticManagedPageFile = $false
            $ComputerSystem.Put() | Out-Null
            Write-Verbose $LocalizedData.DisabledAutomaticPageFile
        }
        else
        {
            Write-Verbose "Nothing to configure here."
        }
    }
    else
    {   
        if ($Ensure -like 'Present')
        {   
            $PageFileSetting = Get-wmiobject Win32_PageFileSetting  
            $PageFileSetting.InitialSize = $InitialSize / 1MB
            $PageFileSetting.MaximumSize = $MaximumSize / 1MB                
            $PageFileSetting.put() | Out-Null

            Write-Verbose ($LocalizedData.PageFileStaticallyConfigured -f $InitialSize, $MaximumSize)            
        }
        else
        {                  
            $ComputerSystem.AutomaticManagedPageFile = $true
            $ComputerSystem.Put() | Out-Null
            Write-Verbose  $LocalizedData.AutomaticPageFileConfigured            
        }
    }
    
    Write-Verbose $LocalizedData.RebootRequired