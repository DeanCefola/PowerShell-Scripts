<#Author   : Dean Cefola
# Creation Date: 8-26-2019
# Usage      : Build Domain Controller

#**************************************************************************
# Date                     Version      Changes
#------------------------------------------------------------------------
# 8/26/2019                  1.0       Intial Version
#
#
#***************************************************************************
#>


############################
#    DC Build Variables    #
############################
$DomainAdmin      =  $env:USERNAME
$DomainPassword   =  Read-Host -Prompt "Enter Domain Admin Password" -AsSecureString
$DomainFQDN       =  Read-Host -Prompt "Enter Fully Qualified Domain Name" 
$DomainNetBios    =  $DomainFQDN.Split('.') | SELECT -First 1
$DomainSuffix     =  $DomainFQDN.Split('.') | SELECT -last 1
$admin            =  $DomainAdmin
$DomainUser       =  $admin + "@" + $domainFQDN
$DomainCredential =  New-Object System.Management.Automation.PSCredential (
    $DomainUser, $DomainPassword)


######################
#    DC Build Out    #
######################
Install-WindowsFeature `
    -Name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment
Install-ADDSForest `
    -DomainName $DomainFQDN `
    -DomainNetbiosName $DomainNetBios `
    -DatabasePath "C:\NTDS" `
    -LogPath "C:\NTDS" `
    -SysvolPath "C:\SYSVOL" `
    -DomainMode "WinThreshold" `
    -ForestMode "WinThreshold" `
    -CreateDNSDelegation:$false `
    -InstallDns:$true `
    -NoRebootOnCompletion:$true `
    -Force:$true `
    -SafeModeAdministratorPassword $DomainPassword
;
Restart-Computer -Force


