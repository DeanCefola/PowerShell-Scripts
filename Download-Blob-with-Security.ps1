<#Author       : Dean Cefola
# Creation Date: 08-15-2018
# Usage        : download a file from Azure Blob storage with Security

#************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 08/15/2018                     1.0        Intial Version
#
#************************************************************************
#
#>

#    READ ME    #
<# 
 .Synopsis
    download file from Azure Blob Storage with security:
    
 .Description
    Script to download blob from Azure storage with access keys
     
 .Parameter RGName
    Name of the Resource Group the Storage Account is in 

 .Parameter STName
    Name of the Storage Account

 .Parameter Container
    Name of the Storage Account Blob Container
     
 .Parameter FileName
    Name of the File to Download
    
 .Parameter LocalPath
    Path the local folder to download the Blob

        

 .Example
 # Download Blob File
Download-BlobFile `
    -RGName $RGName `
    -STName $STName `
    -Container $Container `
    -LocalPath $LocalPath
    -FileName $FileName

#>


#########################
#    Input Variables    #
#########################
$RGName    = 'con-ue2-pd1-shared-rg-01'
$STName    = 'msdean'
$Container = 'test'
$FileName  = 'LinuxCommands.txt'
$LocalPath = "C:\temp\$FileName"


#################################
#    Set Variables lowercase    #
#################################
$RGName    = $RGName.ToLower()
$STName    = $STName.ToLower()
$Container = $Container.ToLower()


#####################################
#    Get Storage Account Context    #
#####################################
$stokey = (Get-AzureRmStorageAccountKey -ResourceGroupName $RGName -Name $STName).Value[0]    
$StorageContext = New-AzureStorageContext `
    -StorageAccountName $STName `
    -StorageAccountKey $stokey  


############################
#    Download Blob File    #
############################
$Uri = "https://$STName.blob.core.windows.net/$Container/$FileName"
$StartTime = Get-Date    
$EndTime = $startTime.AddMinutes(5.0)
$SAS = New-AzureStorageBlobSASToken `
    -Context $StorageContext `
    -Container $Container `
    -Blob $FileName `
    -Permission rwd `
    -StartTime $StartTime `
    -ExpiryTime $EndTime
$SecureUri = "$uri$SAS"
$LocalPath = "C:\temp\$FileName"   
Wait-Event -Timeout 2 
Invoke-WebRequest -Uri $SecureUri -OutFile $LocalPath
