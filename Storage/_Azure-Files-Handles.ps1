<#Author   : Dean Cefola
# Creation Date: 04-08-2020
# Usage      : AZURE - File Storage Handles

#**************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 04/08/2020                       1.0       Intial Version
#
#***************************************************************************
#
#>



######################
#    Set Variables   #
######################
$rgname = 'ADAuth-FSLogix-WVD'
$StorageAccountName = 'adauthfslogixwvd000'
$shareName = 'fslogix'


##################################
#    Set Storage Environment     #
##################################
$stname = Get-AzStorageAccount `
    -ResourceGroupName $rgname `
    -Name $StorageAccountName 
$key = Get-AzStorageAccountKey `
    -ResourceGroupName $rgname `
    -Name $stname.StorageAccountName | select -First 1
$storageContext = New-AzStorageContext `
    -StorageAccountName $stname.StorageAccountName `
    -StorageAccountKey $key.value
$share = Get-AzStorageShare -Name $shareName `
-Context $storageContext


#####################################
#    Check for open file handles    #
#####################################
Get-AzStorageFileHandle `
    -Context $storageContext `
    -ShareName $shareName `
    -Recursive `
    | Format-Table -AutoSize


#################################
#    Close open file handles    #
#################################
Close-AzStorageFileHandle `
    -Context $storageContext `
    -ShareName "fslogix" `
    -Recursive `
    -CloseAll `
    -Verbose

       