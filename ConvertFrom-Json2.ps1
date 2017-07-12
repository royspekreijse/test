function ParseItem($jsonItem)
{
    if($jsonItem.PSObject.TypeNames -match 'Array') 
    {
        return ParseJsonArray($jsonItem)
    }
    elseif($jsonItem.PSObject.TypeNames -match 'Dictionary') 
    {
        return ParseJsonObject([HashTable]$jsonItem)
    }
    else 
    {
        return $jsonItem
    }
}

function ParseJsonObject($jsonObj) 
{
    $result = New-Object -TypeName PSCustomObject
    foreach ($key in $jsonObj.Keys) 
    {
        $item = $jsonObj[$key]
        if ($item) 
        {
            $parsedItem = ParseItem $item
        }
        else 
        {
            $parsedItem = $null
        }
        $result | Add-Member -MemberType NoteProperty -Name $key -Value $parsedItem
    }
    return $result
}

function ParseJsonArray($jsonArray) 
{
    $result = @()
    $jsonArray | ForEach-Object -Process {
        $result += , (ParseItem $_)
    }
    return $result
}

function ParseJsonString($json) 
{
    $config = $javaScriptSerializer.DeserializeObject($json)
    return ParseJsonObject($config)
}

$content = Get-Content -Path C:\Temp\kvk12345678.json -Raw
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
$result = (New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer -Property @{MaxJsonLength=67108864}).DeserializeObject($content)

$ConfigData = ParseItem $result