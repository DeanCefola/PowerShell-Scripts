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
    –InternalIPInterfaceAddressPrefix “172.18.2.0/24”

Wait-Event -Timeout 2

$ifIndex = (Get-NetAdapter | ? {$_.name -like "*$switchName)"}).ifIndex

New-NetIPAddress `
    -IPAddress 172.18.2.1 `
    -InterfaceIndex $ifIndex `
    -PrefixLength 24


#####################
#    DHCP Server    #
#####################
Install-WindowsFeature -Name DHCP –IncludeManagementTools

Add-DhcpServerV4Scope `
    -Name "DHCP-$switchName" `
    -StartRange 172.18.2.50 `
    -EndRange 172.18.2.100 `
    -SubnetMask 255.255.255.0

Set-DhcpServerV4OptionValue `
    -Router 172.18.2.1 `
    -DnsServer 168.63.129.16

Restart-service dhcpserver
