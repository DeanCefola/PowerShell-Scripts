<#Author       : Dean Cefola
# Creation Date: 08-15-2024
# Usage        : Create Global Virtual Networks
#************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 08/15/2024                     1.0        Intial Version
#
#************************************************************************
#
#>


########################
#    RGs Input Array   #
########################
$RGs = @(
    @{Name="Expert-vnets-eus2";Location='uksouth'}
    @{Name="Expert-vnets-uks";Location='uksouth'}
    @{Name="Expert-vnets-JPE";Location='JapanEast'}
)


###################
#    Build RGs    #
###################
foreach ($RG in $RGs) {        
    $RGName = $RG.Name
    If (!(Get-AzResourceGroup -name $RGName -ErrorAction SilentlyContinue)) {
        Write-Host -ForegroundColor Red -BackgroundColor Black "Creating Resource Group"
        New-AzResourceGroup -Name $RG.Name -Location $RG.Location
    }
    else {
        Write-Host -ForegroundColor Cyan -BackgroundColor Black "Resource Group $RGName already exists"
    }
        
}


#########################
#    hub Input Array    #
#########################
$HubNETs = @(
    @{Name="Expert-Hub-eus2";Location='eastus2';AddressPrefix='10.0.0.0/16';RGName='Expert-vnets-eus2';IdentitySubnet='10.0.1.0/24';DNS=@('10.0.1.4','172.18.1.5','192.168.1.5');BastionSubnet='10.0.2.0/26';FirewallSubnet='10.0.3.0/26';FirewallMgtSubnet='10.0.3.64/26'}
    @{Name="Expert-Hub-uks";Location='uksouth';AddressPrefix='172.18.0.0/16';RGName='Expert-vnets-uks';IdentitySubnet='172.18.1.0/24';DNS=@('10.0.1.4','172.18.1.5','192.168.1.5');BastionSubnet='172.18.2.0/26';FirewallSubnet='172.18.3.0/26';FirewallMgtSubnet='172.18.3.64/26'}
    @{Name="Expert-Hub-jpe";Location='japaneast';AddressPrefix='192.168.0.0/16';RGName='Expert-vnets-jpe';IdentitySubnet='192.168.1.0/24';DNS=@('10.0.1.4','172.18.1.5','192.168.1.5');BastionSubnet='192.168.2.0/26';FirewallSubnet='192.168.3.0/26';FirewallMgtSubnet='192.168.3.64/26'}
)


#####################
#    Build Hubs     #
#####################
foreach ($hub in $HubNETs) {
    $IdentitySubnet = New-AzVirtualNetworkSubnetConfig -Name 'Identity' -AddressPrefix $hub.IdentitySubnet
    $BastionSubnet = New-AzVirtualNetworkSubnetConfig -Name 'AzureBastionSubnet' -AddressPrefix $hub.BastionSubnet
    $FirewallSubnet = New-AzVirtualNetworkSubnetConfig -Name 'AzureFirewallSubnet' -AddressPrefix $hub.FirewallSubnet
    $FirewallMgtSubnet = New-AzVirtualNetworkSubnetConfig -Name 'AzureFirewallManagementSubnet' -AddressPrefix $hub.FirewallMgtSubnet
    
    # Deploy Hub network
    $vnet = New-AzVirtualNetwork `
        -Name $hub.Name `
        -ResourceGroupName $hub.RGName `
        -Location $hub.Location `
        -AddressPrefix $hub.AddressPrefix `
        -Subnet $IdentitySubnet, $BastionSubnet, $FirewallSubnet, $FirewallMgtSubnet `
        -DnsServer $hub.DNS

    # Create Public IP for Azure Bastion
    $bastionPIP = New-AzPublicIpAddress `
        -Name "$($hub.Name)-Bastion-PIP" `
        -ResourceGroupName $hub.RGName `
        -Location $hub.Location `
        -AllocationMethod Static `
        -Sku Standard `
        -Tier Regional `
        -IpAddressVersion IPv4 `
        -Zone @('1', '2', '3')

    # Create Public IP for Azure Firewall
    $firewallPIP = New-AzPublicIpAddress `
        -ResourceGroupName $hub.RGName `
        -Name "$($hub.Name)-Firewall-PIP" `
        -Location $hub.Location `
        -AllocationMethod Static `
        -Sku Standard `
        -Tier Regional `
        -IpAddressVersion IPv4 `
        -Zone @('1', '2', '3')
    
    # Create Public IP for Azure Firewall Management
    $firewallMgrPIP = New-AzPublicIpAddress `
        -ResourceGroupName $hub.RGName `
        -Name "$($hub.Name)-Firewall-MGR-PIP" `
        -Location $hub.Location `
        -AllocationMethod Static `
        -Sku Standard `
        -Tier Regional `
        -IpAddressVersion IPv4 `
        -Zone @('1', '2', '3')
    
    #Deploy Azure Bastion
    $HubVNET = Get-AzVirtualNetwork -Name $hub.name -ResourceGroupName $hub.RGName
    New-AzBastion `
        -ResourceGroupName $hub.RGName `
        -Name "$($hub.Name)-Bastion" `
        -VirtualNetwork $HubVNET `
        -PublicIpAddress $bastionPIP
    
    # Deploy Azure Firewall    
    New-AzFirewall `
        -ResourceGroupName $hub.RGName `
        -Name "$($hub.Name)-Firewall" `
        -Location $hub.Location `
        -VirtualNetwork $HubVNET `
        -PublicIpAddress $firewallPIP `
        -ManagementPublicIpAddress $firewallMgrPIP `
        -Zone @('1', '2', '3') `
        -SkuTier Basic
}


#########################
#    vnet Input Array   #
#########################
$vNETs = @(
    @{Name="Expert-Spoke-eu2-AVD";Location='eastus2';AddressPrefix='10.1.0.0/24';RGName='Expert-vnets-eus2'}
    @{Name="Expert-Spoke-eu2-SAP";Location='eastus2';AddressPrefix='10.2.0.0/24';RGName='Expert-vnets-eus2'}
    @{Name="Expert-Spoke-eu2-EMS";Location='eastus2';AddressPrefix='10.3.0.0/16';RGName='Expert-vnets-eus2'}
    @{Name="Expert-Spoke-eu2-VMs";Location='eastus2';AddressPrefix='10.4.0.0/16';RGName='Expert-vnets-eus2'}
    @{Name="Expert-Spoke-uks-AVD";Location='uksouth';AddressPrefix='172.18.1.0/24';RGName='Expert-vnets-uks'}
    @{Name="Expert-Spoke-uks-SAP";Location='uksouth';AddressPrefix='172.18.2.0/24';RGName='Expert-vnets-uks'}
    @{Name="Expert-Spoke-uks-EMS";Location='uksouth';AddressPrefix='172.18.3.0/24';RGName='Expert-vnets-uks'}
    @{Name="Expert-Spoke-uks-VMs";Location='uksouth';AddressPrefix='172.18.4.0/24';RGName='Expert-vnets-uks'}    
    @{Name="Expert-Spoke-jpe-AVD";Location='japaneast';AddressPrefix='192.168.1.0/24';RGName='Expert-vnets-jpe'}
    @{Name="Expert-Spoke-jpe-SAP";Location='japaneast';AddressPrefix='192.168.2.0/24';RGName='Expert-vnets-jpe'}
    @{Name="Expert-Spoke-jpe-EMS";Location='japaneast';AddressPrefix='192.168.3.0/24';RGName='Expert-vnets-jpe'}
    @{Name="Expert-Spoke-jpe-VMs";Location='japaneast';AddressPrefix='192.168.4.0/24';RGName='Expert-vnets-jpe'}
)


#####################
#    Build vNETs    #
#####################
foreach ($vNET in $vNETs) {
    $Subnet = New-AzVirtualNetworkSubnetConfig -Name Subnet -AddressPrefix $vNET.AddressPrefix
    New-AzVirtualNetwork `
        -Name $vnet.Name `
        -ResourceGroupName $vNET.RGName `
        -Location $vNET.Location `
        -AddressPrefix $vNET.AddressPrefix `
        -Subnet $Subnet
}


