#Source:
#https://github.com/OneGet/oneget/blob/WIP/Test/Examples/Sample_Install_Package.ps1
#
configuration Sample_Install_Package
{
    param
    (
        #Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )


    Import-DscResource -Module PackageManagement -ModuleVersion 1.2.0

    Node $NodeName
    {               
        #register package source       
        PackageManagementSource PSGallery
        {

            Ensure      = "Present"
            Name        = "psgallery"
            ProviderName= "PowerShellGet"
            SourceLocation   = "https://www.powershellgallery.com/api/v2/"  
            InstallationPolicy ="Trusted"
        }

        #Install a package from the Powershell gallery
        PackageManagement GistProvider
        {
            Ensure            = "present" 
            Name              = "gistprovider"
            Source            = "PSGallery"
            DependsOn         = "[PackageManagementSource]PSGallery"
        }             
        
        PackageManagement PowerShellTeamOSSUpdateInfo
        {
            Ensure   = "present"
            Name     = "Get-PSTOss.ps1"
            ProviderName = "Gist"
            Source   = "dfinke"
            DependsOn = "[PackageManagement]GistProvider"
        }                  
    } 
}


#Compile it
Sample_Install_Package 

#Run it
Start-DscConfiguration -path .\Sample_Install_Package -wait -Verbose -force 