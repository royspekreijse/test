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
function Convert-PesterXMLToArray {
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [ValidateScript( {
                If (Test-Path $_) {
                    $true
                }
                else {
                    Throw "Invalid path given: $_"
                }
            })]
        [String[]]$FilePath,
        [Parameter(Mandatory = $false)]
        [ValidateSet("Success", "Failure", "Warning" )]
        [string[]]
        $Filters = @()

    )
    begin {
        [array]$retVal = @()
    }

    process {

        try {
            [xml]$pesteroutput = Get-Content $FilePath
        }
        catch {
            Throw "XML is not valid"
        }

        $testoutputs = $pesteroutput.GetElementsByTagName("test-case")

        foreach ($testoutput in $testoutputs) {
            $item = @{
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
                    if (((Test-Path  $thisnode.Name -ErrorAction SilentlyContinue) -eq $false) -and ($thisnode.Name -ne "Pester")) {

                        $infoitems += , $thisnode.Description
                    }
                }
                $thisnode = $thisnode.ParentNode
            }
            [array]::Reverse($infoitems)
            if ($infoitems.Count -ge 1) {
                $item.Describe = $infoitems[0]
            }
            if ($infoitems.Count -ge 2) {
                $item.Context1 = $infoitems[1]
            }
            if ($infoitems.Count -ge 3) {
                $item.Context2 = $infoitems[2]
            }

            if (($Filters.Length -eq 0) -or ($Filters.IndexOf($testoutput.Result) -ne -1)) {
                $retVal += , $item
            }

        }
    }

    end {
        return $retVal
    }
}