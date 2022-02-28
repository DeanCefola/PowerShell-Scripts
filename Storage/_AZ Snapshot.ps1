

[CmdletBinding()]
##############################
#    WVD Script Parameters   #
##############################
Param (        
    [Parameter(Mandatory=$true)]
        [string]$RGName,
    [Parameter(Mandatory=$true)]
        [string]$VMName        
)
 
$a = Get-AzVM -ResourceGroupName $RGName -Name $VMName
$DiskName = $a.storageprofile.osdisk.name
#$DiskSize = $a.storageprofile.osdisk.DiskSizeGB
$SourceDisk = Get-AzDisk `
    -ResourceGroupName $a.ResourceGroupName `
    -DiskName $DiskName
$snapshotconfig = New-AzSnapshotConfig `
    -Location eastus `
    -DiskSizeGB 127 `
    -OsType Windows `
    -CreateOption Empty `
    -EncryptionSettingsEnabled $false `
    -SourceResourceId $SourceDisk.id

$A | New-AzSnapshot -Snapshot $snapshotconfig;

