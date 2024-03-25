
Set-VMProcessor -VMName <VMName> -ExposeVirtualizationExtensions $true


###############################
#    Nested Virtualization    #
###############################
$Nodes = (get-VM).name
foreach ($Node in $Nodes) { 
    Set-VMProcessor `
        -VMName $Node `
        -ExposeVirtualizationExtensions $true
}


######################
#    NAT V-Switch    #
######################
$switchName = "InternalNAT"

New-VMSwitch 
    -Name $switchName `
    -SwitchType Internal

New-NetNat `
`–Name $switchName `
–InternalIPInterfaceAddressPrefix “192.168.0.0/24”

$ifIndex = (Get-NetAdapter | ? {$_.name -like "*$switchName)"}).ifIndex

New-NetIPAddress `
-IPAddress 192.168.0.1 `
-InterfaceIndex $ifIndex `
-PrefixLength 24
