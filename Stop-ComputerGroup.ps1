#requires -version 3

<#
.Synopsis
    Stopt groepen van machines in opgegeven volgorde op basis van een bestand.
.DESCRIPTION
    Dit script kan gebruikt worden om machines in een bepaalde volgorde te stoppen.
    De bron is een csv bestand met twee kolommen. De eerste kolom is de machinenaam, de tweede kolom de volgorde op basis van een cijfer waarbij het laagste cijfer als eerste aan de beurt komt.
    Tussen iedere ronde wordt gewacht totdat (1) alle machines in betreffende groep uit staan of (2) de maximale wachttijd zoals opgegegeven via de parameter 'WaitTime' is bereikt.
        
    Voorwaarden voor de goede werking van dit script:
    - Name resolving moet tot de laatste shutdown werken; IP nummers als machinenaam opgeven werkt niet

    Beperkingen huidig script:
    - Vereist PowerShell versie 3 of hoger
    - Als target worden alleen op Windows gebaseerde machines ondersteund
    - Alleen machines vanuit dezelfde security context kunnen gemanipuleerd worden (gestart met domein account => alleen domein machines <> gestart met een lokaal account => alleen stand alone machines (met dezelfde credentials aanwezig))
    - Vereist dat ICMP/PING open staat op zowel TCP 4 als 6

.PARAMETER FileName
    Compleet pad naar het bron bestand. Verwacht een CSV met twee kolommen 'ComputerName' en 'Order'. Het schedingsteken moet een komma zijn.

.PARAMETER WaitTime
    Maximale wachttijd tussen iedere shutdown groep/ronde.
#>

[CmdletBinding()]
Param(
    [String]$FileName, #Complete path to filename to use, expects CSV set-up. Fixed on English/International delimiter ','
    [Int]$WaitTime = 60 #Maximum wait time in seconds between shutdown cycle rounds
)

#Import and check $FileName
$Machines = Import-Csv -Path $Filename -Delimiter ','
If (!($Machines | Get-Member -MemberType NoteProperty -Name 'ComputerName')){
    Throw "$($Filename) does not contain a valid column ComputerName and/or any values within that column"
}
If (!($Machines | Get-Member -MemberType NoteProperty -Name 'Order')){
    Throw "$($Filename) does not contain a valid column Order and/or any values within that column"
}

Tenant1
Tenant2

DPM 
TenantVM

WAPTenant
WAPAdMin
SCOM    
vmm
SQL

Foreach ($MachineGroup in ($Machines | Group-Object -Property 'Order')){
    $j = Stop-Computer -ComputerName $MachineGroup.Group.ComputerName -AsJob -Force
    $Timer = [System.Diagnostics.Stopwatch]::StartNew()
    $Wait = $true
    While ($Wait){
        $AllDown = $true
        If((Test-Connection -ComputerName $MachineGroup.Group.ComputerName -Count 1 -Quiet) -match 'True'){
            $AllDown = $false
        }
        If (($Timer.Elapsed.Seconds -gt $WaitTime) -or ($AllDown)){
            $Wait = $false
        }
    }
}
