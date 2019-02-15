<#Author   : Dean Cefola
# Creation Date: 01-08-2014
# Usage      : Disable IPv6
#
#***********************************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 01-08-2014                       1.0       Intial Version
#
#************************************************************************************************
#>


#------------------------------Disable IPv6------------------------------#
Netsh int teredo set state disabled
Netsh int isatap set state disabled
Netsh int 6to4 set state disabled undoonstop=disabled
Write-Host -ForegroundColor Green "IPv6 Disabled on" 
Write-Host -ForegroundColor Yellow -BackgroundColor Black $env:COMPUTERNAME


#------------------------------Change Registry Settings------------------------------#
Push-Location 
Set-Location HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters 
New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters -Name "DisabledComponents" -PropertyType "DWord" -Value 4294967295

Pop-Location
