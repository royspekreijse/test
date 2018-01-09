Param(
    $Path = $PSScriptroot,
    $date = '1/1/1980 00:00'
)
#https://blogs.technet.microsoft.com/heyscriptingguy/2012/06/01/use-powershell-to-modify-file-access-time-stamps/
Function Set-FileTimeStamps{
 Param (
    [Parameter(mandatory=$true)]
    [string[]]$path,
    [datetime]$date = (Get-Date))
    Get-ChildItem -Path $path |
    ForEach-Object {
     $_.CreationTime = $date
     $_.LastAccessTime = $date
     $_.LastWriteTime = $date }
} #end function Set-FileTimeStamps

Function Toggle-ArchiveBit{
 Param (
    [Parameter(mandatory=$true)]
    [string[]]$path
    )
    $attribute = [io.fileattributes]::archive
    Get-ChildItem -Path $path -File -Recurse|
    ForEach-Object {
    Set-ItemProperty -Path $_.fullname -Name attributes `
         -Value ((Get-ItemProperty $_.fullname).attributes -BXOR $attribute) }
}

[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

If (!(Test-Path -Path "$($Path)\Done")){New-item -Path $Path -Name 'Done' -ItemType Directory}

$files = Get-ChildItem -Path $Path -File | Out-GridView -PassThru -Title 'Select file to edit'
Foreach ($file in $files){
    Copy-Item -Path $file.fullname -Destination "$($Path)\Done" -Force
    $doc = Get-Item -Path "$($Path)\Done\$($File.Name)"
    Rename-Item -Path $doc -NewName "$($doc.BaseName).zip"
    expand-archive -Path "$($Doc.Directory)\$($doc.BaseName).zip" -DestinationPath "$($Doc.Directory)\$($doc.BaseName)"

    $wshell = New-Object -ComObject Wscript.Shell
    $wshell.Popup("Verander nu de datums",0,"Wachten tot volgende actie",0x1)
    <#
    [xml]$xml = get-content "$($Doc.Directory)\$($doc.BaseName)\docProps\core.xml"

    $title = 'Document creation time'
    $msg   = "Current creation time is: $($xml.coreProperties.created.'#text') Please enter new time"
    $CreationTime = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)
    #$xml.coreProperties.created.'#text' = $CreationTime
    $title = 'Document last write time'
    $msg   = "Current last write time is: $($xml.coreProperties.modified.'#text') Please enter new time"
    $ModifiedTime = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)
    #$xml.coreProperties.modified.'#text' = $ModifiedTime

    #$xml.Save("$($Doc.Directory)\$($doc.BaseName)\docProps\core.xml")

    #Do a text replace, XML replace adds extra info; not wanted
    $text = get-content "$($Doc.Directory)\$($doc.BaseName)\docProps\core.xml"
    $text = $text -replace "dcterms:created xsi*","dcterms:created xsi:type=`"dcterms:W3CDTF`">$($CreationTime)</dcterms:created><dcterms:modified xsi:type=`"dcterms:W3CDTF`">$($ModifiedTime)</dcterms:modified></cp:coreProperties>"
    $text | Set-Content "$($Doc.Directory)\$($doc.BaseName)\docProps\core.xml" -Force
    #>


    #https://blogs.technet.microsoft.com/heyscriptingguy/2011/01/27/use-powershell-to-toggle-the-archive-bit-on-files/
    $a = Get-item "$($Doc.Directory)\$($doc.BaseName)\docProps\core.xml"

    #Set the attributes for core.xml seperately. Somehow Set-FileStamps does not work for this file
    $a.CreationTime = $date
    $a.LastAccessTime = $date
    $a.LastWriteTime = $date

    $attribute = [io.fileattributes]::archive
    Set-ItemProperty -Path $a.fullname -Name attributes `
         -Value ((Get-ItemProperty $a.fullname).attributes -BXOR $attribute)

    $a = Get-ChildItem "$($Doc.Directory)\$($doc.BaseName)" -Directory -Recurse
    foreach ($b in $a){
        $b.CreationTime = $date
        $b.LastAccessTime = $date
        $b.LastWriteTime = $date
    }

    $a = Get-ChildItem "$($Doc.Directory)\$($doc.BaseName)" -File -Recurse
    foreach ($b in $a.Fullname){
        & attrib -a "$b"
    }

    #Set-FileTimeStamps -Path "$($Doc.Directory)\$($doc.BaseName)" -Date $date

    #Toggle-ArchiveBit -Path "$($Doc.Directory)\$($doc.BaseName)"

    <#Again a stubborn file..
    $a = Get-item "$($Doc.Directory)\$($doc.BaseName)\[Content_Types].xml"
    $attribute = [io.fileattributes]::archive
    Set-ItemProperty -Path $a.fullname -Name attributes `
         -Value ((Get-ItemProperty $a.fullname).attributes -BXOR $attribute)
    #>

    Remove-Item -Path "$($Doc.Directory)\$($doc.BaseName).zip" -Force
    $filesToArchive = Get-ChildItem -Path "$($Doc.Directory)\$($doc.BaseName)" -Recurse
    $filesToArchive | Compress-Archive -DestinationPath "$($Doc.Directory)\$($doc.BaseName).zip"
    Rename-Item -Path "$($Doc.Directory)\$($doc.BaseName).zip" -NewName "$($doc.BaseName).docx"
}


