<#
.SYNOPSIS
Short description

.DESCRIPTION
Tot nu toe gebruikten we een rekenmethode om StorageSpace disken te vergroten. Deze rekenmethode was op basis van trial-and-error gemaakt en is niet waterdicht.
Omdat we nu soms al tiered storage aanbieden op sommige klantservers en e.e.a. verder willen automatiseren voor Windows 2016, ben ik er nogmaals ingedoken.

Met bijgevoegd script als resultaat. Wat is hierin bereikt?
1.	Ontdekt dat het ook mogelijk is om in Windows2012R2 StorageSpaces per tier een disk toe te voegen
2.	Betere controle van geschikte disken; een disk waarvan de beschikbare capaciteit niet volledig toegewezen is aan een partitie, kan ook tevoorschijn komen met “CanPool = True”
3.	Correct en eenduidig achterhalen van de daadwerkelijk toevoegbare GB’s op basis van de extra toegevoegde disk
4.	Eenvoudig toevoegen van één of meerdere disks aan een bepaalde tier op basis van de disk grootte

Getest op: Windows 2012R2 i.c.m. Tiered Storage Pool, ResilliencyType = Simple en ColumnSize = 1
LET OP: Voor andere configuraties is een uitbreiding noodzakelijk. Bij voldoende wenselijkheid/noodzaak zal ik e.e.a. uitzoeken/toevoegen.

Uitgangspunten
-	Tiered Storage Pool, ResilliencyType = Simple en ColumnSize = 1
-	Bestaande StoragePool/VirtualDisk/Disk/Partitie/Volume
-	Relatie/verhouding StoragePool:VirtualDisk:(Logical)Disk:Partitie:Volume = 1:1:1:1
-	Disk grootte is bepalend voor indeling in tier
-	Get-PhysicalDisk functie werkt (het is bekend dat deze af en toe niet goed werkt op Windows2012R2)

Werkwijze
-	Voeg via VMM een disk toe aan de VM voor de gewenste tier met gewenste grootte (let op eventueele afspraken/naamconventies)
-	Kopier bijgevoegd script naar gewenst locatie (bijv C:\Support\Scripts)
-	Start een elevated PS sessie
-	‘Dot-source’ het script: 
o	. C:\Support\Scripts\Expand-SimpleStoragePool.ps1 óf
o	. .\Expand-SimpleStoragePool.ps1
-	Roep functie aan: 
o	PS C:\support\scripts> Expand-SimpleStoragePool -StoragePoolFriendlyName 'SP_Data' -SizeGB 1023 -Tier HDD

Alles gebeurd verder automatisch…. 😊


.EXAMPLE
An example

.NOTES
General notes
#>
Function Get-StoragePoolDisk {
    $PhysicalDisks = Get-PhysicalDisk -CanPool $true
    $LogicalDisks = Get-Disk | Where-Object OperationalStatus -eq 'Offline'
    $EmptyDisks = @()
    ForEach ($LD in $LogicalDisks) {
        $EmptyDisks += $PhysicalDisks | Where-Object UniqueId -eq  $LD.UniqueID
    }
    $EmptyDisks
}

Function Expand-SimpleStoragePoolTier {
    <#
    .LINK
    https://charbelnemnom.com/2015/03/step-by-step-how-to-extend-and-resize-a-two-way-mirrored-storage-tiered-space-storagespaces-ws2012r2/
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [PSObject]$PhysicalDisk,
        [Parameter(Mandatory = $true)]
        [String]$StoragePoolFriendlyName,
        [Parameter(Mandatory = $true)]
        [ValidateSet('SSD', 'HDD')]
        [String]$Tier
    )
    
    Begin {}
    
    Process {
        foreach ($Disk in $PhysicalDisk) {
            $SPPool = Get-StoragePool -FriendlyName $StoragePoolFriendlyName
            $VD = $SPPool | Get-VirtualDisk
            $TierFriendlyName = ($VD | Get-StorageTier | Where-Object MediaType -eq $Tier).FriendlyName
            $SPPool | Add-PhysicalDisk -PhysicalDisks $Disk
            $Disk | Set-PhysicalDisk -MediaType $Tier

            $CurrentTierSize = (Get-StorageTier -FriendlyName $TierFriendlyName).Size
            #Get-StorageTierSupportedSize -FriendlyName $TierFriendlyName -ResiliencySettingName Simple |FT @{l="TierSizeMin(GB)";e={$_.TierSizeMin/1GB}},@{l="TierSizeMax(GB)";e={$_.TierSizeMax/1GB}},@{l="TierSizeDivisor(GB)";e={$_.TierSizeDivisor/1GB}}
            $MaxTierExpand = (Get-StorageTierSupportedSize -FriendlyName $TierFriendlyName -ResiliencySettingName Simple).TierSizeMax
            If ($MaxTierExpand -gt $Disk.Size) {
                $MaxExpand = $Disk.Size
            }
            Else {
                $MaxExpand = $MaxTierExpand
            }
            Resize-StorageTier -FriendlyName $TierFriendlyName -Size ($CurrentTierSize + $MaxExpand)
            #$VD = $SPPool | Get-VirtualDisk
            $VD | Get-Disk | Update-Disk
            $DriveLetter = ($VD | Get-Disk | Get-Partition | Where-Object DriveLetter).DriveLetter
            $MaxSize = (Get-PartitionSupportedSize -DriveLetter $DriveLetter).sizeMax
            Resize-Partition -DriveLetter $DriveLetter -Size $MaxSize
        }
    }

    End {}
}

function Expand-SimpleStoragePool {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$StoragePoolFriendlyName,
        [Parameter(Mandatory = $true)]
        [Int]$SizeGB,
        [Parameter(Mandatory = $true)]
        [ValidateSet('SSD', 'HDD')]
        [String]$Tier
    )

    $NewDisk = Get-StoragePoolDisk
    $Size = $SizeGB * 1GB
    $Disk = $NewDisk |Where-Object {$_.Size -gt ($Size - ($Size / 10)) -and $_.Size -lt ($Size + ($Size / 10))}
    Expand-SimpleStoragePoolTier -PhysicalDisk $Disk -StoragePoolFriendlyName $StoragePoolFriendlyName -Tier $Tier
}

