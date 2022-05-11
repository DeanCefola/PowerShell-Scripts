<#Author   : Dean Cefola
# Creation Date: 04-29-2020
# Usage      : AZURE VM ScaleSet Applications
#**************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 04/29/2020                       1.0       Intial Version
#
#***************************************************************************
#
#>
###################
#    Setup Lab    #
###################
#Build VM Scale Set
New-AzVmss `
  -ResourceGroupName "myResourceGroup" `
  -VMScaleSetName "myScaleSet" `
  -Location "EastUS" `
  -VirtualNetworkName "myVnet" `
  -SubnetName "mySubnet" `
  -PublicIpAddressName "myPublicIPAddress" `
  -LoadBalancerName "myLoadBalancer" `
  -UpgradePolicyMode "Automatic"

#Custom Script Extenction to install Web Server
  $customConfig = @{
    "fileUris" = (,"https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate-iis.ps1");
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File automate-iis.ps1"
  }

# Get information about the scale set
$vmss = Get-AzVmss `
    -ResourceGroupName "myResourceGroup" `
    -VMScaleSetName "myScaleSet"

#Create a rule to allow traffic over port 80
$nsgFrontendRule = New-AzNetworkSecurityRuleConfig `
  -Name myFrontendNSGRule `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 200 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow

#Create a network security group and associate it with the rule
$nsgFrontend = New-AzNetworkSecurityGroup `
    -ResourceGroupName  "myResourceGroup" `
    -Location EastUS `
    -Name myFrontendNSG `
    -SecurityRules $nsgFrontendRule
$vnet = Get-AzVirtualNetwork `
    -ResourceGroupName  "myResourceGroup" `
    -Name myVnet
$frontendSubnet = $vnet.Subnets[0]
$frontendSubnetConfig = Set-AzVirtualNetworkSubnetConfig `
  -VirtualNetwork $vnet `
  -Name mySubnet `
  -AddressPrefix $frontendSubnet.AddressPrefix `
  -NetworkSecurityGroup $nsgFrontend
Set-AzVirtualNetwork `
    -VirtualNetwork $vnet
Get-AzPublicIpAddress `
    -ResourceGroupName "myResourceGroup" `
    | Select IpAddress


########################
#    Install App v1    #
########################
# Add the Custom Script Extension to install IIS and configure basic website
$vmss = Add-AzVmssExtension `
    -VirtualMachineScaleSet $vmss `
    -Name "customScript" `
    -Publisher "Microsoft.Compute" `
    -Type "CustomScriptExtension" `
    -TypeHandlerVersion 1.9 `
    -Setting $customConfig

# Update the scale set and apply the Custom Script Extension to the VM instances
Update-AzVmss `
-ResourceGroupName "myResourceGroup" `
-Name "myScaleSet" `
-VirtualMachineScaleSet $vmss


########################
#    Install App v2    #
########################
$customConfigv2 = @{
    "fileUris" = (,"https://raw.githubusercontent.com/Azure-Samples/compute-automation-configurations/master/automate-iis-v2.ps1");
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File automate-iis-v2.ps1"
  }
$vmss = Get-AzVmss `
        -ResourceGroupName "myResourceGroup" `
        -VMScaleSetName "myScaleSet" 
$vmss.VirtualMachineProfile.ExtensionProfile[0].Extensions[0].Settings = $customConfigv2 
Update-AzVmss `
  -ResourceGroupName "myResourceGroup" `
  -Name "myScaleSet" `
  -VirtualMachineScaleSet $vmss


######################
#    Clean Up Lab    #
######################
Remove-AzResourceGroup -Name "myResourceGroup" -Force -AsJob


