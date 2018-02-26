Function Get-UrlFile {
    #https://blog.jourdant.me/post/3-ways-to-download-files-with-powershell
    param(
        $url,
        $output
    )
    Try {
        Import-Module BitsTransfer -ErrorAction Stop
        Start-BitsTransfer -Source $url -Destination $output -ErrorAction Stop
    }
    Catch {
        (New-Object System.Net.WebClient).DownloadFile($url, $output)
    }
    Unblock-File -Path $output
}