$Processes = Get-WMIObject -Class Win32_Process -Filter "Name='PowerShell.EXE'" | Where-Object {$_.CommandLine -Like $($MyInvocation.MyCommand.Name)}
$Processes | Select Handle,CommandLine | FT -AutoSize
If ($Processes.Count -ne $Null) {
    Stop-Process $Processes.Handle -Force
}