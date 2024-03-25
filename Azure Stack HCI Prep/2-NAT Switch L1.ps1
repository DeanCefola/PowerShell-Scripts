######################
#    NAT V-Switch    #
######################
$switchName = "VmNAT"

New-VMSwitch `
    -Name $switchName `
    -SwitchType Internal

Wait-Event -Timeout 2

New-NetNat `
    –Name LocalNAT `
    –InternalIPInterfaceAddressPrefix “192.168.0.0/24”

Wait-Event -Timeout 2

$ifIndex = (Get-NetAdapter | ? {$_.name -like "*$switchName)"}).ifIndex

New-NetIPAddress `
    -IPAddress 192.168.0.1 `
    -InterfaceIndex $ifIndex `
    -PrefixLength 24


#####################
#    DHCP Server    #
#####################
Install-WindowsFeature -Name DHCP –IncludeManagementTools

Add-DhcpServerV4Scope `
    -Name "DHCP-$switchName" `
    -StartRange 192.168.0.50 `
    -EndRange 192.168.0.100 `
    -SubnetMask 255.255.255.0

Set-DhcpServerV4OptionValue `
    -Router 192.168.0.1 `
    -DnsServer 168.63.129.16

Restart-service dhcpserver
