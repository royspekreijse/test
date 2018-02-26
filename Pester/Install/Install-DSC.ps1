Configuration CSAnalytics
{
<#


#>

    param             
    (
        #For Azure Automation mis-use the node function to differentiate between customers. In AA the node function is not really used (thus far), except for setting sDscAllowPlainTextPassword and creating the MOF filename.
        [string]$NodeName,
        #As a result of this; the $Node.NodeName value within the $ConfigurationData value cannot be used. Als, if the node section was properly used within this configuration, testing so far resulted in only being able to call 
        #a $ConfigurationData data-set with 1 node. Otherwise errors of some kind...
        #This parameter is deliberately called MachineName, as $NodeName is being interpreted the same as/replaced by the $Node.NodeName value within the configuration when called from Azure Automation
        [string]$MachineName,
        [Parameter(Position = 0, HelpMessage = 'Specify the Entity long name (max 15 char)')]
        [String] $EntityLong = 'Main',
        [Parameter(Position = 0, HelpMessage = 'Specify the Entity short name (max 6 char)')]
        [String] $EntityShort = 'Main',
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = 'Specify the FQDN of the new domain')]
        [string]$DomainName,
        [Parameter(Position = 1, Mandatory = $True, HelpMessage = 'Specify the Netbios name of the new domain')]
        [string]$DomainNetbiosName,
        [string]$safemodePassword,             
        [string]$DomainAccountName,
        [string]$DomainAccountPassword,
        [string]$ReversedDNSZoneName,
        [bool]$ComplexityEnabled = $True, #Whether password complexity is enabled for the default password policy.
        [int]$LockoutDuration = 30, #Length of time that an account is locked after the number of failed login attempts (minutes).
        [int]$LockoutObservationWindow = 30, # Maximum time between two unsuccessful login attempts before the counter is reset to 0 (minutes).
        [int]$LockoutThreshold = 10, #Number of unsuccessful login attempts that are permitted before an account is locked out.
        [int]$MinPasswordAge = 1440, #Minimum length of time that you can have the same password (minutes).
        [int]$MaxPasswordAge = 259200, #Maximum length of time that you can have the same password (minutes).
        [int]$MinPasswordLength = 7, #Minimum number of characters that a password must contain.
        [int]$PasswordHistoryCount = 24, #Number of previous passwords to remember.
        [bool]$ReversibleEncryptionEnabled = $False, #Whether the directory must store passwords using reversible encryption.

        [string]$WebAccessServer,
        [string]$SessionHost,
        [string]$RDBrokerPublicFQDN,

        [Parameter(HelpMessage = 'Specify the ADFS account servicename')]
        [String] $ADFSAccountName = "svcADFS",
        [Parameter(HelpMessage = 'Specify the password for the ADFS account servicename')]
        [string]$ADFSAccountPassword,
        [Parameter(HelpMessage = 'Specify the public FQDN for this ADFS install')]
        [String]$ADFSPublicFQDN,
        [string]$ADFSDisplayName = "Welkom bij $($EntityLong)",
        [string]$ADFSDBFolder = 'F:\WID', # WID DB location
        [int]$CertExpYears = 3, #How many years certificate expires. 10jaar geldig maken?
        [string]$PFXExportPath = "C:\support\cert\sts-cs.pfx",        
        [string]$ADFSCertExportPassword
        
    )

    $safemodeCred = [pscredential]::new('dummy', (ConvertTo-SecureString -String $safemodePassword -AsPlainText -Force))
    $domainCred = [pscredential]::new($DomainAccountName, (ConvertTo-SecureString -String $DomainAccountPassword -AsPlainText -Force))

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    #Node "$($AllNodes.Where{$_.NodeName -like '*-cc*'}.NodeName)"
    #Node $NodeName
    #Node "$($ConfigurationData.NonNodeData.Customer.ID)"
    Node $NodeName
    {

        #region GenericPreConfig
           
        iGenericPreconfig Server {}
                       
        #Endregion GenericPreConfig

        #Region PDC
        $Role = @(
            @{
                Name             = 'PDC'
                WindowsFeature   = @(
                    @{
                        Name   = 'AD-Domain-Services' #needed for xActiveDirectory resource
                        Ensure = 'Present'
                    }
                    @{
                        Name   = 'RSAT-AD-PowerShell' #needed for xActiveDirectory resource
                        Ensure = 'Present'
                    }
                )
                OrganizationUnit = @(
                    @{
                        Name       = "$($EntityLong)" #Defaut root OU name is EntityLong.
                        Path       = ''
                        Attributes = @(
                            @{
                                ExtensionName = @("E_$($EntityLong)", "ES_$($EntityShort)", "main")
                            }
                        )
                    }
                    @{
                        Name = 'Computers' #Generic placeholder for accounts. Put standard user accounts here. Accounts should contain the 'Entity=[EntityLong]' value in the 'ExtensionName' attribute
                        Path = "OU=$($EntityLong),"
                    }
                    @{
                        Name = 'Application Servers' #All entity specific application servers should be placed here
                        Path = "OU=Computers,OU=$($EntityLong),"
                    }
                    @{
                        Name = 'Backoffice servers' #Backoffice servers for 
                        Path = "OU=Computers,OU=$($EntityLong),"
                    }
                    @{
                        Name = 'Clients' #Client machine placeholder
                        Path = "OU=Computers,OU=$($EntityLong),"
                    }
                    @{
                        Name = 'Terminal Servers' #All entity specific terminal services must be placed here
                        Path = "OU=Computers,OU=$($EntityLong),"
                    }
                )
            }
        )

        xWaitforDisk Disk2
        {
            DiskNumber       = 2
            RetryIntervalSec = 10
            RetryCount       = 2
        }

        xDisk FVolume
        {
            DiskNumber  = 2
            DriveLetter = 'F'
            FSLabel     = 'Data'
            DependsOn   = '[xWaitForDisk]Disk2'
        }

        File NTDSFiles {            
            DestinationPath = 'F:\NTDS'            
            Type            = 'Directory'            
            Ensure          = 'Present'
            DependsOn       = '[xDisk]FVolume'            
        }            

        File SYSVOLFiles {            
            DestinationPath = 'F:\SYSVOL'            
            Type            = 'Directory'            
            Ensure          = 'Present' 
            DependsOn       = '[xDisk]FVolume'         
        }

    }
}

  