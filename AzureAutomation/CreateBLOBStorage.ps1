#Select-AzureRMSubscription -SubscriptionName "Visual Studio Premium met MSDN"
#$AzureOrgIdCredential = Get-AutomationPSCredential -Name 'beheerder'
$AzureOrgIdCredential = Get-Credential

$AzureSubscriptionName = 'Visual Studio Premium met MSDN'

$ResourceGroupName = 'CS'

# Connect to Azure so that this runbook can call the Azure cmdlets
#Add-AzureRmAccount -Credential $AzureOrgIdCredential -SubscriptionName $AzureSubscriptionName 
Add-AzureRmAccount

# Give a name to your new storage account. It must be lowercase!
$StorageAccountName = "csiton"
$StorageAccountName = "csdisks550"

# Choose "West US" as an example.
$Location = "West Europe"

# Give a name to your new container.
$ContainerName = "imagecontainer"
$ContainerName = "vhds"

# Have an image file and a source directory in your local computer.
$ImageToUpload = "C:\Temp\joey-kok.jpg"

# A destination directory in your local computer.
$DestinationFolder = "E:\Temp"


# Create a new storage account
Try{
    $StorAcct = Get-AzureRMStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
}Catch{
    $StorAcct = New-AzureRMStorageAccount –StorageAccountName $StorageAccountName -Location $Location -ResourceGroupName $ResourceGroupName -SkuName "Standard_GRS"
}

Try{
   $StorContainer = $StorAcct | Get-AzureStorageContainer -Name $ContainerName -ErrorAction Stop
}Catch{
    # Create a new container.
    $StorContainer = $StorAcct | New-AzureStorageContainer -Name $ContainerName -Permission Off
}


 # Set a default storage account.
# Set-AzureRMSubscription -CurrentStorageAccountName $StorageAccountName -SubscriptionName $SubscriptionName



# Upload a blob into a container.
#$StorContainer | Set-AzureStorageBlobContent -Container $ContainerName -File $ImageToUpload

# List all blobs in a container.
$StorContainer | Get-AzureStorageBlob -Container $ContainerName

# Download blobs from the container:
# Get a reference to a list of all blobs in a container.
$blobs = $StorContainer | Get-AzureStorageBlob -Container $ContainerName

# Create the destination directory.
New-Item -Path $DestinationFolder -ItemType Directory -Force  

# Download blobs into the local destination directory.
$blobs | Get-AzureStorageBlobContent –Destination $DestinationFolder

# end