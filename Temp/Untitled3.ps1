

        $StorageAccountName = 'csanalyticsdev'

        [int16]$NumberOfPreviousDays = 7
$Force = $true


    #Get the settings
    $SplatSettings = @{}
    If ($Path) {$SplatSettings.Path = $Path}
    $AzureTableSettings = @()
    $AzureTableSettings = (Get-AzureTableSettings @SplatSettings).Where{$_.StorageAccountName -eq $StorageAccountName} #Not a true object, but array-like
    If (!($AzureTableSettings)) {
        Throw "No settings found for Storage Account name: $($StorageAccountName). Cannot continue!"
    }

    #Get the items for this command
    $SplatSettings = @{
        CustomersTable                 = $AzureTableSettings.CustomersTable
        MachinesTable                  = $AzureTableSettings.MachinesTable
        MachineStorageMetricsTable     = $AzureTableSettings.MachineStorageMetricsTable
        IaaSMachineStorageMetricsTable = $AzureTableSettings.IaaSMachineStorageMetricsTable
        StorageAccountName             = $AzureTableSettings.StorageAccountName
        StorageKey                     = $AzureTableSettings.StorageKey
    }
    #$AzureTableSettings[0].PSObject.Properties | ForEach-Object { $SplatSettings[$_.Name] = $_.Value }

    If ($Force) {
        $SplatSettings.Force = $Force
    }
    If ($NumberOfPreviousDays) {
        $SplatSettings.NumberOfPreviousDays = $NumberOfPreviousDays
    }

    #Load the data into environment. These are the global variables Customers, Machines, MachineStorageMetrics and IaaSMachineStorageMetrics
    Get-AzureData @SplatSettings