$infile = Get-Content -Raw "C:\Users\peppe\OneDrive\GitHub\CS-Automation-Runbooks\Runbooks\pk-ConfigurationData.json"
$ConfigData = ConvertFrom-Json -InputObject $infile


'[{"title":"PowerShell"},{"title":"Test"}]' | ConvertFrom-JSON


(New-Object PSObject |
   Add-Member -PassThru NoteProperty Name 'John Doe' |
   Add-Member -PassThru NoteProperty Age 10          |
   Add-Member -PassThru NoteProperty Amount 10.1     |
   Add-Member -PassThru NoteProperty MixedItems (1,2,3,"a") |
   Add-Member -PassThru NoteProperty NumericItems (1,2,3) |
   Add-Member -PassThru NoteProperty StringItems ("a","b","c")
) | ConvertTo-JSON


[pscustomobject]@{a=1; b=2; c=3; d=4}| ConvertTo-JSON 

-Compress

 
