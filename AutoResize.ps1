<#Author       : Dean Cefola
# Creation Date: 08-01-2022
# Usage        : Auto Resize Script / Azure RunBook
#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 08/01/2022                     1.0        Intial Version
#
#*********************************************************************************
#
#>
##############################
#    AutoResize Parameters   #
##############################
Param (        
    [CmdletBinding()]
    [Parameter(Mandatory=$true)]
        [string]$LAWorkspaceName,
    [Parameter(Mandatory=$true)]
        [string]$Region,        
    [Parameter(Mandatory=$true)]
        [string]$VMName,
    [Parameter(Mandatory=$true)]
        [string]$RGName
)
#$LAWorkspaceName = 'MSAA-LogAnalytics-r345xqot624z2'

##################
#   Variables    #
##################
$LAWorkspace = (Get-AzOperationalInsightsWorkspace `
    | Where-Object `
    -Property name `
    -eq $LAWorkspaceName).CustomerId.GUID


###################
#   Resize VMs    #
###################
if($RGName -eq $null) {
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black "Resize VM"
    Wait-Event -Timeout 2
     set-vmRightSize `
        -targetVMName $VMName `
        -workspaceId $LAWorkspace `
        -region $Region `
        -verbose `
        -WhatIf
}
Else {
    Write-Host `
        -ForegroundColor yellow `
        -BackgroundColor Black "Resize Resource Group"
    Wait-Event -Timeout 2   
    set-rsgRightSize `
        -targetRSG $RGName `
        -workspaceId $LAWorkspace `
        -region $Region ` `
        -measurePeriodHours 24 `
        -WhatIf `
        -Verbose
}


