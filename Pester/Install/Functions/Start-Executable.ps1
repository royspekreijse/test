Function Start-Executable {
    <#
    .SYNOPSIS
        Runs an external executable file, and validates the error level.

    .PARAMETER Executable
        The path to the executable to run and monitor.

    .PARAMETER Arguments
        An array of arguments to pass to the executable when it's executed.

    .PARAMETER SuccessfulErrorCode
        The error code that means the executable ran successfully.
        The default value is 0.

    .NOTES
        From Convert-WindowsImage.ps1 by Artem Pronichkin.
        Link: https://gallery.technet.microsoft.com/scriptcenter/Convert-WindowsImageps1-0fe23a8f
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateNotNullOrEmpty()]
        $Executable,

        [Parameter(Mandatory = $true)]
        [string[]]
        [ValidateNotNullOrEmpty()]
        $Arguments,

        [Parameter()]
        [int]
        [ValidateNotNullOrEmpty()]
        $SuccessfulErrorCode = 0

    )

    Write-Verbose "Running $Executable $Arguments"
    $ret = Start-Process           `
        -FilePath $Executable      `
        -ArgumentList $Arguments   `
        -NoNewWindow               `
        -Wait                      `
        -RedirectStandardOutput "$($env:temp)\$($Executable)-StandardOutput.txt" `
        -RedirectStandardError  "$($env:temp)\$($Executable)-StandardError.txt"  `
        -Passthru

    Write-Verbose "Return code was $($ret.ExitCode)."

    if ($ret.ExitCode -ne $SuccessfulErrorCode) {
        throw "$Executable failed with code $($ret.ExitCode)!"
    }
}