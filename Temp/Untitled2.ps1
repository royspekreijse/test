Remove-Module MachineReport
import-module C:\Users\peppe\OneDrive\GitHub\CS-Analytics\MachineReport\0.1.2\MachineReport.psd1
$PreviousVerbosePreference = $VerbosePreference
$PreviousDebugPreference = $DebugPreference
$VerbosePreference = 'continue'
$DebugPreference = 'continue'

publish-report -StorageAccountName csdiskreport -force

$teststring = "Dit is jan met LUN 5"
$result= $teststring -replace '.*LUN '

