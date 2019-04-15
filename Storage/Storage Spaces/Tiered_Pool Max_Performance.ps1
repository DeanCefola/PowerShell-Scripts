<#Author   : Dean Cefola
# Creation Date: 12-12-2018
# Usage      : Create Tiered Storage Pools, Disks & Volumes

#**************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 12/12/2018                       1.0       Intial Version
#
#
#***************************************************************************
#>

##########################
#    Comments Section    #
##########################
# Assumes physical disks in the default primordial pool 
# Creates Mirrored Tiered virtual disks – need even number of SCM, SSD & HDD available disks
# In this example I have 2x 256GB SCM disks + 2x 512GB SSD disks + 2x 4TB HDD physical disks (not counting boot/system disks of course)
# I’d like to end up with # 3 mirrored and tiered vDisks of equal size using the maximum available space, with 25 GB write-back cache 
# Customize the following settings to meet your specific hardware configuration
##########################
#    Comments Section    #
##########################

$PoolName = “TieredPool”
$WBCache = 25 # GB (Default is 1 GB for Tiered disks – 32 MB for non-tiered)
$TieredMirroredvDisks = @("HyperV") # List names of mirrored-tiered vDisks you like to create
$DriveLetters = @("Z") # List drive letters you like to assign to the new volumes 
$BlockSize = 32 # KB
# End Data Entery section
#
$Loc = Get-Location
$Date = Get-Date -format yyyyMMdd_hhmmsstt
$logfile = $Loc.path + “\CreateSS_” + $Date + “.txt”
function log ($string, $color) {
    if ($Color -eq $null) {$color = “white”}
    write-host $string -foregroundcolor $color 
    $temp = “: ” + $string
    $string = Get-Date -format “yyyy.MM.dd hh:mm:ss tt”
    $string += $temp 
    $string | out-file -Filepath $logfile -append
}


#################################
#    Create new Storage Pool    #
#################################
$StorageSpaces = Get-StorageSubSystem -FriendlyName *windows* 
$PhysicalDisks = Get-PhysicalDisk -CanPool $true | Sort Size | FT DeviceId, FriendlyName, CanPool, Size, HealthStatus, MediaType -AutoSize -ErrorAction SilentlyContinue 
Log “Available physical disks:” green
log ($PhysicalDisks | Out-String) 
if (!$PhysicalDisks) { 
log “Error: no physical disks are available in the primordial pool..stopping” yellow
break
}
get-physicaldisk | ? -Property size -EQ 256GB | Set-PhysicalDisk -MediaType SCMget-physicaldisk | ? -Property size -EQ 512GB | Set-PhysicalDisk -MediaType SSDget-physicaldisk | ? -Property size -EQ 4095GB | Set-PhysicalDisk -MediaType HDD
$PhysicalDisks = Get-PhysicalDisk -CanPool $true -ErrorAction SilentlyContinue | Sort-Object -Property size


###################################################
#    Count SCM, SSD & HDD disks, size & errors    #
###################################################
$SCMBytes=0; $SSDBytes=0; $HDDBytes=0
for ($i=0; $i -le $PhysicalDisks.Count; $i++) {
if ($PhysicalDisks[$i].MediaType -eq “SCM”) {$SCM++; $SCMBytes+=$PhysicalDisks[$i].Size}
if ($PhysicalDisks[$i].MediaType -eq “SSD”) {$SSD++; $SSDBytes+=$PhysicalDisks[$i].Size}
if ($PhysicalDisks[$i].MediaType -eq “HDD”) {$HDD++; $HDDBytes+=$PhysicalDisks[$i].Size}
}
$Disks = $HDD + $SSD + $SCM
if ( $Disks -lt 4) { log “Error: Only $Disks disks are available. Need minimum 4 disks for mirrored-tiered storage spaces..stopping” yellow; break }
if ( $SSD -lt 2) { log “Error: Only $SSD SSD disks are available. Need minimum 2 SSD disks for mirrored-tiered storage spaces..stopping” yellow; break }
if ( $HDD -lt 2) { log “Error: Only $HDD HDD disks are available. Need minimum 2 HDD disks for mirrored-tiered storage spaces..stopping” yellow; break }
if ( $SSD % 2 -eq 0) {} else { log “Error: Found $SSD SSD disk(s). Need even number of SSD disks for mirrored storage spaces..stopping” yellow; break }
if ( $HDD % 2 -eq 0) {} else { log “Error: Found $HDD HDD disk(s). Need even number of HDD disks for mirrored storage spaces..stopping” yellow; break }


#########################
#    Create new pool    #
#########################
log “Creating new Storage Pool ‘$PoolName’:” green
$Status = New-StoragePool -FriendlyName $PoolName -StorageSubSystemFriendlyName $StorageSpaces.FriendlyName -PhysicalDisks $PhysicalDisks -ErrorAction SilentlyContinue 
log ($Status | Out-String) 
if ($Status.OperationalStatus -eq “OK”) {log “Storage Pool creation succeeded” green} else { log “Storage Pool creation failed..stopping” yellow; break }


#######################################
#    Configure resiliency settings    #
#######################################
Get-StoragePool $PoolName |Set-ResiliencySetting -Name Mirror -NumberofColumnsDefault 1 -NumberOfDataCopiesDefault 2


#############################
#    Configure two tiers    #
#############################
Get-StoragePool $PoolName | New-StorageTier –FriendlyName SCMTier –MediaType SCM
Get-StoragePool $PoolName | New-StorageTier –FriendlyName SSDTier –MediaType SSD
Get-StoragePool $PoolName | New-StorageTier –FriendlyName HDDTier –MediaType HDD
$SCMSpace = Get-StorageTier -FriendlyName SCMTier
$SSDSpace = Get-StorageTier -FriendlyName SSDTier
$HDDSpace = Get-StorageTier -FriendlyName HDDTier


#######################################
#    Create tiered/mirrored vDisks    #
#######################################
$BlockSizeKB = $BlockSize * 1024
$WBCacheGB = $WBCache * 1024 * 1024 * 1024 # GB
$SCMDSize = $SCMBytes/($TieredMirroredvDisks.Count*2) – ($WBCacheGB + (2*1024*1024*1024))
$SSDSize = $SSDBytes/($TieredMirroredvDisks.Count*2) – ($WBCacheGB + (2*1024*1024*1024))
$HDDSize = $HDDBytes/($TieredMirroredvDisks.Count*2) – ($WBCacheGB + (2*1024*1024*1024))
$temp = 0
ForEach ($vDisk in $TieredMirroredvDisks) {
    log “Attempting to create vDisk ‘$vDisk’..”
    $Status = Get-StoragePool $PoolName | New-VirtualDisk -FriendlyName $vDisk -ResiliencySettingName Mirror –StorageTiers $SCMSpace, $SSDSpace, $HDDSpace -StorageTierSizes $SCMDSize, $SSDSize,$HDDSize -WriteCacheSize $WBCacheGB
    log ($Status | Out-String) 
    $DriveLetter = $DriveLetters[$temp]
if ($Status.OperationalStatus -eq “OK”) {
    log “vDisk ‘$vDisk’ creation succeeded” green
    log “Initializing disk ‘$vDisk’..” 
    $InitDisk = $Status | Initialize-Disk -PartitionStyle GPT -PassThru # Initialize disk
    log ($InitDisk | Out-String) 
    log “Creating new partition on disk ‘$vDisk’, drive letter ‘$DriveLetter’..” 
    $Partition = $InitDisk | New-Partition -UseMaximumSize -DriveLetter $DriveLetter # Create new partition
    log ($Partition | Out-String) 
    log “Formatting new partition as volume ‘$vDisk’, drive letter ‘$DriveLetter’, NTFS, $BlockSize KB block size..”
    $Format = $Partition | Format-Volume -FileSystem NTFS -NewFileSystemLabel $vDisk -AllocationUnitSize $BlockSizeKB -Confirm:$false # Format new partition
    log ($Format | Out-String) 
} 
else { 
    log “vDisk ‘$vDisk’ creation failed..stopping” yellow; break 
}
$temp++
}

Invoke-Expression “$env:windir\system32\Notepad.exe $logfile”

