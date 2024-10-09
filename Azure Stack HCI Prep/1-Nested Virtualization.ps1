
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


