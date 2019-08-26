  <#Author   : Dean Cefola
# Creation Date: 06-17-2019
# Usage      : Take & Replicate VM Disk Snapshot to another Azure Region

#******************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------------
# 06/17/2019                       1.0       Intial Version
#
#******************************************************************************
#
#>


##########################
#    Get Required Info   #
##########################
$SubscriptionName = 'Azure CXP FTA Internal Subscription DEACEF-2'
$ResourceGroupName = 'Mautic'
$VMName = 'Mautic'
$Destination = 'westus'


#############################
#    Get System Variables   #
#############################
$Month        = (Get-Date).Month
$Day          = (Get-Date).day
$Year         = (Get-Date).year
$snapshotName = "Cycle-$Month-$Day-$Year"
$VM           = Get-AzureRmVM | ? Name -Match $VMName
$VMLocation   = $VM.Location
$VMDiskName   = $VM.StorageProfile.OsDisk.Name
$VMDiskSize   = $VM.StorageProfile.OsDisk.DiskSizeGB
$VMDiskID     = $VM.StorageProfile.OsDisk.ManagedDisk.Id
$RepDiskName  = "$VMName-DataDisk-$snapshotName"


##############################
#    Take VM Disk SnapShot   #
##############################
$snapshotconfig = New-AzureRmSnapshotConfig -Location $VMLocation -CreateOption copy -SourceUri $VMDiskID
New-AzureRmSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName -Snapshot $snapshotconfig -verbose
$snapshot       = Get-AzureRmSnapshot -ResourceGroupName $ResourceGroupName -SnapshotName $snapshotName


########################################
#    Replicate SnapShot to DR Region   #
########################################
$Disk       = Get-AzureRmDisk -ResourceGroupName $ResourceGroupName -DiskName $VMDiskName
$DiskConfig = New-AzureRmDiskConfig -AccountType $disk.Sku.Name  -Location $VMLocation -SourceResourceId $snapshot.Id -CreateOption Copy
$NewDisk    = New-AzureRmDisk -Disk $DiskConfig -ResourceGroupName $ResourceGroupName -DiskName "$RepDiskName"


Move-AzureRmResource -ResourceId '/subscriptions/25603d65-4ffd-4496-815d-417e73e71da3/resourceGroups/Mautic/providers/Microsoft.Compute/disks/Mautic-DataDisk-Cycle-6-18-2019' -DestinationResourceGroupName asdasdad -Force

