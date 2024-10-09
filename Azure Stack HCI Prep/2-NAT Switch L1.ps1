######################
#    NAT V-Switch    #
######################
$switchName = "VmNAT"

New-VMSwitch `
    -Name $switchName `
    -SwitchType Internal

Wait-Event -Timeout 2

New-NetNat -Name "LocalNat" `
    -InternalIPInterfaceAddressPrefix "192.168.100.0/24" `
    -Verbose

Wait-Event -Timeout 2

$ifIndex = (Get-NetAdapter | ? {$_.name -like "*$switchName)"}).ifIndex

New-NetIPAddress `
    -IPAddress 192.168.100.1 `
    -InterfaceIndex $ifIndex `
    -AddressFamily IPv4 `
    -PrefixLength 24


#####################
#    DHCP Server    #
#####################
Install-WindowsFeature -Name DHCP –IncludeManagementTools

Add-DhcpServerV4Scope `
    -Name "DHCP-$switchName" `
    -StartRange 192.168.100.1 `
    -EndRange 192.168.100.254 `
    -SubnetMask 255.255.255.0

Set-DhcpServerV4OptionValue `
    -Router 192.168.100.1 `
    -DnsServer 20.0.4.4,168.63.129.16

Restart-service dhcpserver
