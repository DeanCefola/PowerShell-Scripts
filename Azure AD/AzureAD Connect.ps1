<#Author       : Dean Cefola
# Creation Date: 08-01-2019
# Usage        : Azure AD Connect

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 08/01/2019                     1.0        Intial Version
#
#
#*********************************************************************************
#
#>


####################################
#    Install PowerShell Modules    #
####################################
Find-Module -Name AzureAD | Install-Module -Force -AllowClobber -Verbose
Find-Module -Name AZ | Install-Module -Force -AllowClobber -Verbose
Find-Module -Name AzureRM | Install-Module -Force -AllowClobber -Verbose
Find-Module -Name MSonline | Install-Module -Force -AllowClobber -Verbose



################################
#    Authenticate to Azure     #
################################
$Admin = 'WVD@MSAzureAcademy.com'
$creds = Get-Credential `
    -UserName $Admin `
    -Message "Enter Password for Azure Credentials"

Login-AzAccount -Credential $creds
#Login-AzureRmAccount -Credential $creds
Connect-AzureAD -Credential $creds
connect-msolservice -credential $creds


###################################
#    Azure AD Connect Commands    #
###################################
Import-Module ADSync
Start-ADSyncSyncCycle -PolicyType Initial
Start-ADSyncSyncCycle -PolicyType Delta


