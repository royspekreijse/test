While ($true) {
    Get-Process | Where-Object -Property Description -like 'Microsoft OneDrive for*' | Stop-Process
    Start-Sleep -Seconds 60
}