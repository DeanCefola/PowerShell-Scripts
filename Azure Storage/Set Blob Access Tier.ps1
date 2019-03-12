<#Author   : Dean Cefola
# Creation Date: 1-12-2019
# Usage      : Set Blob Storage Access Tier

#**************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 1/12/2019                       1.0       Intial Version
#
#
#***************************************************************************
#>

$RGName = 'CON-UE2-PD1-Shared-RG-01'
$STName = 'msdean'
$Container = 'sap'
$StorageTier = "Cool"
$Key = (Get-AzureRmStorageAccountKey -ResourceGroupName $RGName -Name $STName | select -First 1).Value
$Context = New-AzureStorageContext -StorageAccountName $STName -StorageAccountKey $Key
$Blob = Get-AzureStorageBlob -Container $Container -Context $Context

$Blob.icloudblob.setstandardblobtier($StorageTier)


