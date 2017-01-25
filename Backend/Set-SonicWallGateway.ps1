$Gateway = '172.17.3.253'

<#
10-12-2016PK: 
There seems to be no other way to (only) change the DefaultGateway without completally deleting IP config. This does not work:
$CurrentIPConfig = @()
$CurrentIPConfig = Get-NetIPConfiguration
New-NetIPAddress -InterfaceAlias $CurrentIPConfig.InterfaceAlias -IPAddress $CurrentIPConfig.IPv4Address.IPAddress -PrefixLength $CurrentIPConfig.IPv4Address.PrefixLength -DefaultGateway 172.17.3.253
#>
$Adapter = @()
$Adapter = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE
If ($Adapter.Count -gt 1){
    Write-Error -Message "This script does not support multiple Ethernet adapters"
}
$Adapter.SetGateways($Gateway)

#Correct routing
$routes = @()
$routes = @(
@{
    DestionationPrefix = '172.18.0.0/16'
    NextHop = '172.17.3.254'
}
@{
    DestionationPrefix = '172.17.0.0/16'
    NextHop = '172.17.3.254'
}
@{
    DestionationPrefix = '10.0.0.0/8'
    NextHop = '172.17.3.254'
}
@{
    DestionationPrefix = '10.100.100.0/24'
    NextHop = '172.17.3.253'
}
)
Foreach ($route in $routes){
    New-NetRoute -InterfaceAlias Ethernet -DestinationPrefix $route.DestionationPrefix -AddressFamily IPv4 -NextHop $route.NextHop -RouteMetric 1 -Publish Yes
}
