<#Author       : Dean Cefola
# Creation Date: 08-15-2018
# Usage        : Download Blob from Azure With Container Access

#************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 01/04/2019                     1.0        Intial Version
#
#************************************************************************
#
#>

####################
#    Input Array   #
####################
$Url = 'https://msdean.blob.core.windows.net/sap/Containers.ps1'
$LocalPath = "C:\temp\Containers.ps1"
#param([string]$url, [string]$path) 
      
if(!(Split-Path -parent $LocalPath) -or !(Test-Path -pathType Container (Split-Path -parent $LocalPath))) { 
    $LocalPath = Join-Path $pwd (Split-Path -leaf $LocalPath) 
} 
      
"Downloading [$url]`nSaving at [$LocalPath]" 
$client = new-object System.Net.WebClient 
$client.DownloadFile($url, $LocalPath) 
