#requires -version 3
#Requires -RunAsAdministrator

<#
.Synopsis
    "One-script-to-stop-them-all". Stopt groepen van zowel VMM als Hyper-V als fysieke machines in opgegeven volgorde op basis van een bestand.
    
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
    Compleet pad naar het bron bestand. Verwacht een CSV met de onderstaande kolommen. Het schedingsteken moet een komma zijn.
     'ComputerName' - (Verplicht) De computernaam, of een zoekdeel van de computernaam. 
                      Alle matches van het deel worden aangesproken op gestelde target en binnen gestelde scope
                      Voorbeelden: 
                      *
                      *[deelcomputernaam]*
                      [deelcomputernaam]*
     'Order'        - (Verplicht) Dit is de volgorde, hoe lager het cijfer, hoe eerder het gebeurd. Laagst mogelijk cijfer is 1
     'Target'       - Dit geeft de target aan, keuzes zijn VMM, Hyper-V of Physical. Zonder opgave wordt betreffende machine overgeslagen
                      PAS OP: als target VMM of Hyper-V is, dan wordt naam van de Virtuele Machine gebruikt, NIET de naam in het OS van de VM!!
     'Host'         - niet verplicht. Alleen nodig als target 'Hyper-V' is en via VMM niet te achterhalen is op welke host een VM draait
     'WaitTime'     - niet verplicht. Wachttijd van deze groep. Als verschillende tijden zijn aangegeven, dan wordt de hoogste waarde aangehouden.
     'Filter'       - niet verplicht. Werkt op dit moment alleen bij de VMM target. Als 'LogicalNetwork' ingevuld is, dan wordt het in kolom FilterName genoemde netwerk gefilterd bovenop de ComputerName filter.
     'FilterName'   - niet verplicht. Geef (een deel van) de naam waarop gefilterd moet worden voor betreffend filter zoals aangegeven in de kolom 'Filter'.  Wildcards toegestaan.

.PARAMETER VMMServer
    De VMMServer waarop de virtuele machines draaien.

.PARAMETER IntervalTime
    Wachttijd tussen de status controles van d shutdown acties

.PARAMETER Log
    De locatie van het logbestand 

.PARAMETER Delimter
    Het scheidingsteken wat gebruikt moet worden voor de te importeren CSV. Standaard is een komma (,) 
#>

[CmdletBinding()]
Param(
    [parameter(Mandatory=$true)]
    [String]$FileName, #Complete path to filename to use, expects CSV set-up. Fixed on English/International delimiter ','
    
    [ValidateNotNullOrEmpty()]
    [Int]$IntervalTime = 10, #Wait time in seconds between checks

    [String]$VMMServer,

    [ValidateScript({Test-Path $_})]
    [String]$Log = "$($PSScriptroot)\$($MyInvocation.MyCommand.Name.Split('.')[0]).log",

    [ValidateNotNullOrEmpty()]
    [String]$Delimiter = ','
)

If ($Log)
{
    $PreviousVerbosePreference = $VerbosePreference
    $VerbosePreference = "Continue"
    Start-Transcript $Log
}

#Check if virtualmachinemanager is loaded
If ((Get-Module).Name -notcontains 'virtualmachinemanager'){
    Try{
        Import-Module -Name 'virtualmachinemanager' -ErrorAction Stop -Verbose:$false
        Write-Verbose -Message "Loaded module VirtualMachineManager"
    }Catch{
        Write-Warning -Message 'Could not load PS module virtualmachinemanager, any VMM based Virtual Machine wil not be stopped'
    }
}

Try{
    $VMS = Get-SCVirtualMachine -VMMServer $VMMServer -ErrorAction Stop
}Catch{
    $VMS = @()
}

#Check if ActiveDirectory is loaded
If ((Get-Module).Name -notcontains 'ActiveDirectory'){
    Try{
        Import-Module -Name 'ActiveDirectory' -ErrorAction Stop -Verbose:$false
        Write-Verbose -Message "Loaded module ActiveDirectory"
    }Catch{
        Write-Warning -Message 'Could not load PS module ActiveDirectory, cannot do a domain based search in ComputerName'
    }
}

Try{
    $ADMS = Get-ADComputer -Filter *
}Catch{
    $ADMS = @()
}

#Import and check $FileName
$Machines = Import-Csv -Path $Filename -Delimiter $Delimiter

#Check if all columns are present
$PropertyCheck = $Machines | Get-Member -MemberType NoteProperty
If ($PropertyCheck.Name -notcontains 'ComputerName'){
    Throw "$($Filename) does not contain a valid column ComputerName"
}
If ($PropertyCheck.Name -notcontains 'Order'){
    Throw "$($Filename) does not contain a valid column Order"
}
If ($PropertyCheck.Name -notcontains 'Target'){
    Throw "$($Filename) does not contain a valid column Target"
}
If ($PropertyCheck.Name -notcontains 'Host'){
    Throw "$($Filename) does not contain a valid column Host"
}
If ($PropertyCheck.Name -notcontains 'WaitTime'){
    Throw "$($Filename) does not contain a valid column WaitTime"
}
If ($PropertyCheck.Name -notcontains 'Filter'){
    Throw "$($Filename) does not contain a valid column Filter"
}
If ($PropertyCheck.Name -notcontains 'FilterName'){
    Throw "$($Filename) does not contain a valid column FilterName"
}

#Check if al mandatory values are present
If ($Machines.ComputerName -contains [String]::Empty){
    Throw "Column ComputerName contains empty values. Stopping"
}
$Machines|ForEach-Object{
    Try{
        [System.Convert]::ToInt16($_.Order) | Out-Null
    }Catch{
        Throw "Column Order contains illegal values, probably a string"
    }
    Try{
        [System.Convert]::ToInt16($_.WaitTime) | Out-Null
    }Catch{
        Throw "Column WaitTime contains illegal values, probably a string"
    }
}

Foreach ($MachineGroup in ($Machines | Group-Object -Property 'Order')){
    #Detect actions for each machine within the group, can be multiple targets
    $MachineGroupWaitTime = ($MachineGroup.Group.WaitTime |Measure-Object -Maximum).Maximum
    $VMMMachines = @()
    $HyperVMachines = @()
    $PhysicalMachines = @()
    Foreach ($Machine in $MachineGroup.Group){
        $MachineNotFound = $true
        Switch ($Machine.Target) {
            "VMM"       {
                            Switch ($Machine.Filter){
                                "LogicalNetwork"    {
                                                        $Tempie = $VMS | Where-Object {$_.Name -like $Machine.ComputerName -and $_.VirtualNetworkAdapters.LogicalNetwork.Name -like $Machine.FilterName}
                                                    }
                                Default             {
                                                        $Tempie = $VMS | Where-Object Name -like $Machine.ComputerName
                                                    }
                            }
                            If ($Tempie){
                                $VMMMachines += $Tempie
                                $MachineNotFound = $false
                            }
                        }
            "Hyper-V"   {
                            If ($Machine.Host){
                                $HyperVMachines += [PSCustomObject]@{
                                    HostName = $Machine.Host
                                    ComputerName = $Machine.ComputerName
                                }
                                $MachineNotFound = $false
                            }Else{
                                $Tempie = $VMS | Where-Object Name -like "$($Machine.ComputerName)"
                                Foreach ($VM in $Tempie){
                                    $HyperVMachines += [PSCustomObject]@{
                                        HostName = $VM.HostName
                                        ComputerName = $VM.Name
                                    }
                                    $MachineNotFound = $false
                                }
                            }
            }
            "Physical"  {
                            
                            If ($ADMS){                  
                                $PhysicalMachines += (Get-ADComputer -Filter * | Where-Object Name -like "$($Machine.ComputerName)").Name
                                $MachineNotFound = $false
                            }Else{
                                $PhysicalMachines += $Machine.ComputerName
                                $MachineNotFound = $false
                            }
            }
            Default     {
                            #Do nothing, no machine found
                        }
        }
        If ($MachineNotFound){
            Write-Warning -Message "Order $($Machine.Order): $($Machine.ComputerName) is not found on target: $($Machine.Target), skipping.."
        }

    }


    #Now, try to shutdown every collection of machines....
    Foreach ($VMMMachine in $VMMMachines){
        Write-Verbose -Message "Order $($Machine.Order): Stopping VM $($VMMMachine.Name): VMMServer $($VMMServer)"
        Try {
            $VMMMachine | Stop-SCVirtualMachine -RunAsynchronously -ErrorAction Stop | Out-Null
        }Catch{
            Write-Warning -Message "Order $($Machine.Order): VM $($VMMMachine.Name) on VMMServer $($VMMServer) cannot be stopped. Already down?"
        }
    }

    Foreach ($HVVM in ($HyperVMachines | Group-Object -Property 'HostName')){
        #Start a remote PS session for each host; make it permanent for the time of this loop, needed for -Asjob action. Otherwise this peace of code wouold wait for a real shutdown
        Foreach ($VM in $HVVM.Group){
            $Session = Get-PSSession -ComputerName $VM.HostName
            If (!($Session)){
                $Session = New-PSSession -ComputerName $VM.HostName
            }
            Write-Verbose -Message "Order $($Machine.Order): Stopping VM $($VM.ComputerName): Hyper-V host $($VM.HostName)"
        }
        Invoke-Command -Session $Session -ScriptBlock{Get-VM -VM $USING:HVVM.Group.ComputerName| Stop-VM -Asjob -Passthru}
    }

    Foreach ($PhysicalMachine in $PhysicalMachines){
        Write-Verbose -Message "Order $($Machine.Order): Stopping PhysicalMachine $($PhysicalMachine)"
        Stop-Computer -ComputerName $PhysicalMachine -AsJob -Force
    }


    #Now wait .....
    $Timer = [System.Diagnostics.Stopwatch]::StartNew()
    $Wait = $true
    While ($Wait){
        Start-Sleep $IntervalTime
        $AllDown = $true
        #Check VMM status
        Foreach ($VMMMachine in $VMMMachines){
            If ((Get-SCVirtualMachine -VMMServer $VMMServer -ID $VMMMachine.ID).Status -match "Running"){
                $AllDown = $false
                Write-Warning -Message "Order $($Machine.Order): VM $($VMMMachine.Name): VMMServer $($VMMServer): Status: Running"
            }
        }
        #Check Hyper-V status
        Foreach ($HVVM in ($HyperVMachines | Group-Object -Property 'HostName')){
            Foreach ($VM in $HVVM.Group){
                $Session = Get-PSSession -ComputerName $VM.HostName
                If (!($Session)){
                    $Session = New-PSSession -ComputerName $VM.HostName
                }
                If ((Invoke-Command -Session $Session -ScriptBlock{Get-VM -VM $USING:VM.ComputerName}).State -match "Running"){
                    Write-Warning -Message "Order $($Machine.Order): VM $($VM.ComputerName): Hyper-V host $($VM.Name): Status: Running"
                    $AllDown = $false
                }
            }
            
        }
        #Check Physical machines status
        Foreach ($PhysicalMachine in $PhysicalMachines){
            If((Test-Connection -ComputerName $PhysicalMachine -Count 1 -Quiet) -match 'True'){
                $AllDown = $false
                Write-Warning -Message "Order $($Machine.Order): Physical machine $($PhysicalMachine): Status: Running"
            }
        }
        #Check timer
        If (($Timer.Elapsed.Seconds -gt $MachineGroupWaitTime) -and ($AllDown -eq $false)){
            Write-Warning -Message "Order $($Machine.Order): Maximum waittime ($($MachineGroupWaitTime)s) ended! Machines still running!"
        }
        If (($Timer.Elapsed.Seconds -gt $MachineGroupWaitTime) -or ($AllDown)){
            $Wait = $false
        }
    }
}

#Just remove all remote sessions
Get-PSSession | Remove-PSSession

If ($Log)
{
    $VerbosePreference = $PreviousVerbosePreference
    Stop-Transcript
}