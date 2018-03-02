<#
.SYNOPSIS
    Reads all pester tests and returns them as an array
.DESCRIPTION
    Reads an xml file and returns all pester tests as an array.
.EXAMPLE
    PS> Convert-PesterXMLToArray -FilePath  'C:\FileLocation\pester-output.xml'
.EXAMPLE
    PS> Convert-PesterXMLToArray -FilePath  'C:\FileLocation\pester-output.xml' -Filters Failure,Success
#>
function ConvertFrom-PesterXML {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)
        ]
        [ValidateScript( {
                If (Test-Path $_) {
                    $true
                }
                else {
                    Throw "Invalid path given: $_"
                }
            })]
        [Alias('FullName')]
        [String[]]$FilePath,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Success", "Failure", "Warning" )]
        [string[]]
        $Filters = @()

    )
    begin {}

    process {

        try {
            [xml]$pesteroutput = Get-Content $FilePath
        }
        catch {
            Throw "XML is not valid"
        }

        $testoutputs = $pesteroutput.GetElementsByTagName("test-case")

        foreach ($testoutput in $testoutputs) {
            $ReturnInfo = [PSCustomObject]@{
                Name        = $testoutput.Name
                Description = $testoutput.Description
                Result      = $testoutput.Result
                Describe    = ""
                Context1    = ""
                Context2    = ""
            }

            $thisnode = $testoutput.ParentNode
            [array]$infoitems = @()
            while ($thisnode.ParentNode.Name -ne "#document") {
                if ($thisnode.LocalName -eq "test-suite") {
                    if (($thisnode.Description -notmatch '(^([a-z]|[A-Z]):(?=\\(?![\0-\37<>:"\/\\|?*])|\/(?![\0-\37<>:"\/\\|?*])|$)|^\\(?=[\\\/][^\0-\37<>:"\/\\|?*]+)|^(?=(\\|\/)$)|^\.(?=(\\|\/)$)|^\.\.(?=(\\|\/)$)|^(?=(\\|\/)[^\0-\37<>:"\/\\|?*]+)|^\.(?=(\\|\/)[^\0-\37<>:"\/\\|?*]+)|^\.\.(?=(\\|\/)[^\0-\37<>:"\/\\|?*]+))((\\|\/)[^\0-\37<>:"\/\\|?*]+|(\\|\/)$)*()$') -and ($thisnode.Description -ne "Pester")) {
                        <#
                        Write-Output "-----------------------------Begin----------------------------------------------"
                        Write-Output $thisnode | Select-Object LocalName, Description
                        Write-Output "LocalName:" + $thisnode.LocalName
                        Write-Output "Regex:" ($thisnode.Description -notmatch '(^([a-z]|[A-Z]):(?=\\(?![\0-\37<>:"\/\\|?*])|\/(?![\0-\37<>:"\/\\|?*])|$)|^\\(?=[\\\/][^\0-\37<>:"\/\\|?*]+)|^(?=(\\|\/)$)|^\.(?=(\\|\/)$)|^\.\.(?=(\\|\/)$)|^(?=(\\|\/)[^\0-\37<>:"\/\\|?*]+)|^\.(?=(\\|\/)[^\0-\37<>:"\/\\|?*]+)|^\.\.(?=(\\|\/)[^\0-\37<>:"\/\\|?*]+))((\\|\/)[^\0-\37<>:"\/\\|?*]+|(\\|\/)$)*()$')
                        Write-Output "Pester:" ($thisnode.Description -ne "Pester")
                        Write-Output "-----------------------------Eind------------------------------------------------"
                        #>
                        $infoitems += , $thisnode.Description
                    }
                }
                $thisnode = $thisnode.ParentNode
            }
            [array]::Reverse($infoitems)
            if ($infoitems.Count -ge 1) {
                $ReturnInfo.Describe = $infoitems[0]
            }
            if ($infoitems.Count -ge 2) {
                $ReturnInfo.Context1 = $infoitems[1]
            }
            if ($infoitems.Count -ge 3) {
                $ReturnInfo.Context2 = $infoitems[2]
            }

            if (($Filters.Length -eq 0) -or ($Filters.IndexOf($testoutput.Result) -ne -1)) {
                #$retVal += , $item
                if ($PSCmdlet.ShouldProcess("Item added")) {
                    $ReturnInfo
                }
            }

        }
    }

    end {}
}