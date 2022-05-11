
$UDRTable = @(
    @{AddressPrefix='10.10.0.0/16';RTName="rt-10.12.108.0-cus-prod-001";RouteName='rt-10.10.0.0-16';RGName='rg-hub-prod-cus-001';Subnet='10.12.108.0/24';Hub='10.10.0.0/16';NextHopType='VirtualAppliance';NextHop='10.10.201.4'}
    @{AddressPrefix='10.11.0.0/16';RTName="rt-10.12.109.0-cus-prod-001";RouteName='rt-10.11.0.0-16';RGName='rg-hub-prod-cus-002';Subnet='10.12.109.0/24';Hub='10.10.0.0/16';NextHopType='VirtualAppliance';NextHop='10.10.201.4'}
)
ForEach($Job in $UDRTable) {
    Get-AzRouteTable `
        -ResourceGroupName $UDRTable.RGName `
        -Name $UDRTable.RTName | `
    Add-AzRouteConfig `
        -Name $UDRTable.RouteName `
        -AddressPrefix $UDRTable.AddressPrefix `
        -NextHopType $UDRTable.NextHopType `
        -NextHopIpAddress $UDRTable.NextHop | `
    Set-AzRouteTable
}


$UDRTable = @(    
    @{AddressPrefix='10.10.0.0/16';RTName="rt-10.12.108.0-cus-prod-001";RouteName='rt-subnetspecific';RGName='rg-hub-prod-cus-001';Subnet='10.12.108.0/24';Hub='10.10.0.0/16';NextHopType='VirtualNetwork';NextHop=''}
    @{AddressPrefix='10.11.0.0/16';RTName="rt-10.12.109.0-cus-prod-001";RouteName='rt-subnetspecific';RGName='rg-hub-prod-cus-002';Subnet='10.12.109.0/24';Hub='10.10.0.0/16';NextHopType='VirtualNetwork';NextHop=''}
)
ForEach($Job in $UDRTable) {
    Get-AzRouteTable `
        -ResourceGroupName $UDRTable.RGName `
        -Name $UDRTable.RTName | `
    Add-AzRouteConfig `
        -Name $UDRTable.RouteName `
        -AddressPrefix $UDRTable.Subnet `
        -NextHopType $UDRTable.NextHopType `
    Set-AzRouteTable
}
