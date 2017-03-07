$DomainName = 'jan'

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName = 'john99-rdgw' 
            PsDscAllowPlainTextPassword = $true
        }
    )
}

$ParamSplat = @{
        DomainName = $DomainName
        DomainAccountName = 'Administrator'
        DomainAccountPassword = 'Test123_'
        DNSIPAddress = @('172.17.9.2')
        OUPath = "OU=Computers,OU=Shared,DC=internal,DC=john99,DC=nl"
}


. 'C:\Users\peppe\OneDrive\GitHub\CS-CloudDesktop\2016\RDGW\RDGW merged.ps1' 

rdgw @ParamSplat -ConfigurationData $ConfigData -OutputPath c:\temp