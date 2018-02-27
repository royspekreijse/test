function Format-OutputColor {
    <#
    .SYNOPSIS
    Formats the output color for better readability

    .DESCRIPTION
    Formats the output color for better readability, stores the values in global variables to reset back to default.

    .EXAMPLE
    PS> Format-OutputColor

    .EXAMPLE
    PS> Format-OutputColor -ResetToDefault
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $false)]
        [Switch]
        $ResetToDefault
    )
    process {
        $a = (Get-Host).PrivateData
        if ($ResetToDefault) {
            #Gets the saved color from the global variables.
            if ($a) {
                if ($a.WarningBackgroundColor) {
                    $PreviousWarningBackgroundColor = Get-Variable -Name "PreviousWarningBackgroundColor" -Value $a.WarningBackgroundColor -Scope Global
                    $PreviousWarningForegroundColor = Get-Variable -Name "PreviousWarningForegroundColor" -Value $a.WarningForegroundColor -Scope Global
                    if ($PreviousWarningBackgroundColor) {
                        $a.WarningBackgroundColor = $PreviousWarningBackgroundColor
                        $a.WarningForegroundColor = $PreviousWarningForegroundColor
                    }
                }
            }

        }
        else {
            #Set new color and saves the values in global variables.
            if ($a) {
                if ($a.WarningBackgroundColor) {
                    Set-Variable -Name "PreviousWarningBackgroundColor" -Value $a.WarningBackgroundColor -Scope Global
                    Set-Variable -Name "PreviousWarningForegroundColor" -Value $a.WarningForegroundColor -Scope Global
                    $a.WarningBackgroundColor = "red"
                    $a.WarningForegroundColor = "white"
                }
            }
        }
    }
}