<#Author       : Dean Cefola
# Creation Date: 08-15-2018
# Usage        : Download from Azure Blob FUNCTION

#************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 08/15/2018                     1.0        Intial Version
#
#************************************************************************
#
#>

Function Download-BlobFile {
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
     
 .Parameter LiteralDestinationPath
    Path the local folder to download the Blob

        

 .Example
 # Download Blob File
Download-BlobFile `
    -RGName Group1 `
    -STName stname132352 `
    -Container app1 `
    -LiteralDestinationPath c:\temp\file.txt

#>
[Cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
        [string]$RGName,
    [Parameter(Mandatory=$true)]
        [string]$STName,      
    [Parameter(Mandatory=$true)]
        [string]$Container,
    [Parameter(Mandatory=$true)]
        [string]$LiteralDestinationPath
)

Begin {        
    $RGName    = $RGName.ToLower()
    $STName    = $STName.ToLower()
    $Container = $Container.ToLower()
    $split     = $DestinationPath.split('\')
    foreach ($a in $split) {
        $FileName = $a
    }
    write "Starting download of file - $Filename"
}

Process {       
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
    Wait-Event -Timeout 2
    Invoke-WebRequest -Uri $SecureUri -OutFile $LocalPath
}

End {
    Clear-History
}

}


#########################################
#    Example how to run the Function    #
#########################################
Download-BlobFile `
    -RGName $RGName `
    -STName $STName `
    -Container $Container `
    -LiteralDestinationPath c:\temp\LinuxCommands.txt `
    -Verbose
