<#Author       : Dean Cefola
# Creation Date: 08-15-2021
# Usage        : Create Multiple Virtual Networks
#************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 08/15/2021                     1.0        Intial Version
#
#************************************************************************
#
#>


##################
#    Check RG    #
##################
$RGName = 'vnetMgr'
If (!(Get-AzResourceGroup -name $RGName -ErrorAction SilentlyContinue)) {
    Write-Host -ForegroundColor Red -BackgroundColor Black "Creating Resource Group"
    New-AzResourceGroup -Name $RGName -Location 'eastus'
}
else {
    Write-Host -ForegroundColor Cyan -BackgroundColor Black "Resource Group $RGName already exists"
}


####################
#    Input Array   #
####################
$vNETs = @(
    @{Name="vNETMgr-0-Prod";Location='northcentralus';AddressPrefix='192.168.0.0/24'}
    @{Name="vNETMgr-0-Dev";Location='northcentralus';AddressPrefix='192.168.1.0/24'}
    @{Name="vNETMgr-1-Prod";Location='westus';AddressPrefix='192.168.2.0/24'}
    @{Name="vNETMgr-1-Dev";Location='westus';AddressPrefix='192.168.3.0/24'}
    @{Name="vNETMgr-2-Prod";Location='eastus';AddressPrefix='192.168.4.0/24'}
    @{Name="vNETMgr-2-Dev";Location='eastus';AddressPrefix='192.168.5.0/24'}
    @{Name="vNETMgr-3-Prod";Location='eastus2';AddressPrefix='192.168.6.0/24'}
    @{Name="vNETMgr-3-Dev";Location='eastus2';AddressPrefix='192.168.7.0/24'}
    @{Name="vNETMgr-4-Prod";Location='westus2';AddressPrefix='192.168.8.0/24'}
    @{Name="vNETMgr-4-Dev";Location='westus2';AddressPrefix='192.168.9.0/24'}
    @{Name="vNETMgr-5-Prod";Location='NorthEurope';AddressPrefix='192.168.10.0/24'}
    @{Name="vNETMgr-5-Dev";Location='NorthEurope';AddressPrefix='192.168.11.0/24'}
    @{Name="vNETMgr-6-Prod";Location='WestEurope';AddressPrefix='192.168.12.0/24'}
    @{Name="vNETMgr-6-Dev";Location='WestEurope';AddressPrefix='192.168.13.0/24'}
    @{Name="vNETMgr-7-Prod";Location='franceCentral';AddressPrefix='192.168.14.0/24'}
    @{Name="vNETMgr-7-Dev";Location='franceCentral';AddressPrefix='192.168.15.0/24'}
    @{Name="vNETMgr-0-Lab";Location='eastus';AddressPrefix='172.18.0.0/24'}
    @{Name="vNETMgr-1-Lab";Location='eastus';AddressPrefix='172.18.1.0/24'}
    @{Name="vNETMgr-2-Lab";Location='eastus';AddressPrefix='172.18.2.0/24'}
    @{Name="vNETMgr-3-Lab";Location='eastus';AddressPrefix='172.18.3.0/24'}    
)


#####################
#    Build vNETs    #
#####################
foreach ($vNET in $vNETs) {
    $Subnet = New-AzVirtualNetworkSubnetConfig -Name Subnet -AddressPrefix $vNET.AddressPrefix        
    New-AzVirtualNetwork `
        -Name $vnet.Name `
        -ResourceGroupName $RGName `
        -Location $vNET.Location `
        -AddressPrefix $vNET.AddressPrefix `
        -Subnet $Subnet
}


