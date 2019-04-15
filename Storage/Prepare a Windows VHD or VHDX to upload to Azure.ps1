<#Author   : Dean Cefola
# Creation Date: 10/16/2018
# Usage      : Prepare a Windows VHD or VHDX to upload to Azure

#**************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 10/16/2018                       1.0       Intial Version
# 03/25/2019                       2.0       Replace with a cleaner version
#***************************************************************************
#>


# Source for settings https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-windows-prepare-for-upload-vhd-image?toc=%2fazure%2fvirtual-machines%2fwindows%2ftoc.json


# Global variables
$Uri = "http://go.microsoft.com/fwlink/?LinkID=394789&clcid=0x409" 
$outfile = "$env:windir\temp\WindowsAzureVmAgent.2.7.1198.788.rd_art_stable.161208-0959.fre.msi"
$loc = "$env:windir\temp\sanpolicy.txt"
$logloc ="$env:windir\temp\sanpolicylogfile.txt"
$santext1 = "san policy=onlineall"
$santext2 = "exit"
$MSILOG ="C:\Windows\MSIInstall.log"
$Wshell = New-Object -Comobject Wscript.Shell

# Verify if Powershell is running under Administrative credentials.
write-host -ForegroundColor Yellow "Validating if the command shell is running under a Administrative context"

if ( -not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator"))
{

    Write-Host -ForegroundColor yellow "This PowerShell prompt is not elevated."
    Write-Host -ForegroundColor yellow "Please open a new PowerShell session using an Administrative token and please try again."
    return
    }
 
# Creating sanpolicy file
$santext1 | Set-Content $loc
$santext2 | Add-Content $loc 

Write-host -ForegroundColor Yellow "Updating the SAN Policy of the C: drive"

# Setting content of file
diskpart /s $loc | Out-file $logloc 

Write-host -ForegroundColor Green "Completed! Please validate the diskpart logs located here: $logloc"

# Allowing PSRemoting on the server
Enable-PSRemoting -Force

# Resetting NetSH Winhttp Proxy Policy
netsh winhttp reset proxy

# Set Coordinated Universal Time (UTC) time for Windows and the startup type of the Windows Time (w32time) service to Automatic

REG ADD HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation /v RealTimeIsUniversal /t REG_DWORD /d 1

# Set services startup to Windows default values

Write-host -ForegroundColor Yellow "Configuring local services start mode"

set-service w32time -startmode Automatic

Set-service bfe -startmode Automatic

Set-service dcomlaunch -startmode Automatic

Set-service dhcp -startmode Automatic

Set-service dnscache -startmode Automatic

Set-service IKEEXT -startmode Automatic

Set-service iphlpsvc -startmode Automatic

Set-service PolicyAgent -startmode Automatic

Set-service LSM -startmode Automatic

Set-service netlogon -startmode Automatic

Set-service netman -startmode Automatic

Set-service NcaSvc -startmode Automatic

Set-service netprofm -startmode Automatic

Set-service NlaSvc -startmode Automatic

Set-service nsi -startmode Automatic

Set-service RpcSs -startmode Automatic

Set-service RpcEptMapper -startmode Automatic

Set-service termService -startmode Automatic

Set-service MpsSvc -startmode Automatic

Set-service WinHttpAutoProxySvc -startmode Automatic

Set-service LanmanWorkstation -startmode Automatic

Set-service RemoteRegistry -startmode Automatic

Set-service wersvc -startmode Automatic

Write-Host -ForegroundColor Green "Completed!"

# Update Remote Desktop registry settings

REG DELETE "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\SSLCertificateSHA1Hash”

# Keep Alives for RDP Service

REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveEnable /t REG_DWORD  /d 1 /f

REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" /v KeepAliveInterval /t REG_DWORD  /d 1 /f

REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp" /v KeepAliveTimeout /t REG_DWORD /d 1 /f

# Configure Authentication mode for RDP

REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD  /d 1 /f

REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v SecurityLayer /t REG_DWORD  /d 1 /f

REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v fAllowSecProtocolNegotiation /t REG_DWORD  /d 1 /f

REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD  /d 0 /f

# Configure Windows Firewall rules for Azure Inbound

Write-host -ForegroundColor Yellow "Starting to input inbound firewall rules"

netsh advfirewall firewall set rule dir=in name="File and Printer Sharing (Echo Request - ICMPv4-In)" new enable=yes

netsh advfirewall firewall set rule dir=in name="Network Discovery (LLMNR-UDP-In)" new enable=yes

netsh advfirewall firewall set rule dir=in name="Network Discovery (NB-Datagram-In)" new enable=yes

netsh advfirewall firewall set rule dir=in name="Network Discovery (NB-Name-In)" new enable=yes

netsh advfirewall firewall set rule dir=in name="Network Discovery (Pub-WSD-In)" new enable=yes

netsh advfirewall firewall set rule dir=in name="Network Discovery (SSDP-In)" new enable=yes

netsh advfirewall firewall set rule dir=in name="Network Discovery (UPnP-In)" new enable=yes

netsh advfirewall firewall set rule dir=in name="Network Discovery (WSD EventsSecure-In)" new enable=yes

netsh advfirewall firewall set rule dir=in name="Windows Remote Management (HTTP-In)" new enable=yes

netsh advfirewall firewall set rule dir=in name="Windows Remote Management (HTTP-In)" new enable=yes

Write-Host -ForegroundColor Green "Completed!"

# Configure Windows Firewall rules for Azure Inbound and Outbound

Write-host -ForegroundColor Yellow "Starting to input inbound and outbound  firewall rules"

netsh advfirewall firewall set rule group="Remote Desktop" new enable=yes

netsh advfirewall firewall set rule group="Core Networking" new enable=yes

Write-host -ForegroundColor Green "Completed!"

# Configure Windows Firewall rules for Azure outbound

Write-host -ForegroundColor Yellow "Starting to configure outbound firewallrules"

netsh advfirewall firewall set rule dir=out name="Network Discovery (LLMNR-UDP-Out)" new enable=yes

netsh advfirewall firewall set rule dir=out name="Network Discovery (NB-Datagram-Out)" new enable=yes

netsh advfirewall firewall set rule dir=out name="Network Discovery (NB-Name-Out)" new enable=yes

netsh advfirewall firewall set rule dir=out name="Network Discovery (Pub-WSD-Out)" new enable=yes

netsh advfirewall firewall set rule dir=out name="Network Discovery (SSDP-Out)" new enable=yes

netsh advfirewall firewall set rule dir=out name="Network Discovery (UPnPHost-Out)" new enable=yes

netsh advfirewall firewall set rule dir=out name="Network Discovery (UPnP-Out)" new enable=yes

netsh advfirewall firewall set rule dir=out name="Network Discovery (WSD Events-Out)" new enable=yes

netsh advfirewall firewall set rule dir=out name="Network Discovery (WSD EventsSecure-Out)" new enable=yes

netsh advfirewall firewall set rule dir=out name="Network Discovery (WSD-Out)" new enable=yes

Write-host -ForegroundColor Green "Completed!"

# The Dump Log configuration

REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v CrashDumpEnabled /t REG_DWORD /d 2 /f

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v DumpFolder /t REG_EXPAND_SZ /d "c:\CrashDumps" /f

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v DumpCount /t REG_DWORD /d 10 /f

REG ADD "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps" /v DumpType /t REG_DWORD /d 2 /f

# Setting Boot Configuration Data (BCD) settings

$Wshell.Run("bcdedit /set {bootmgr} integrityservices enable")
$Wshell.Run("bcdedit /set {default} device partition=C:")
$Wshell.Run("bcdedit /set {default} integrityservices enable")
$Wshell.Run("bcdedit /set {default} recoveryenabled Off")
$Wshell.Run("bcdedit /set {default} osdevice partition=C:")
$Wshell.Run("bcdedit /set {default} bootstatuspolicy IgnoreAllFailures")

# Make sure to download and install the following agent for Azure
# Source: http://go.microsoft.com/fwlink/?LinkID=394789&clcid=0x409
# Downloading the agent

Write-Host -ForegroundColor Yellow "Starting to download the Microsoft Azure agent!"
Invoke-WebRequest -Uri $Uri -OutFile $outfile;
Unblock-file -path $outfile;

# Validating if the file downloaded PLEASE NOTE THE FILE IS SUBJECT TO CHANGE IN THE FUTURE!!!!!
Test-path -path "$env:windir\temp\WindowsAzureVmAgent.2.7.1198.788.rd_art_stable.161208-0959.fre.msi"
Write-Host -ForegroundColor Yellow "If you saw the word True then the file downloaded from the internet!"

# Installing the Azure agent
Write-Host -ForegroundColor Yellow "Starting sto install the Microsoft Azure Agent"
& msiexec.exe /i $outfile /qn /l* $MSILOG

# Setting sleep for 10 seconds
Start-Sleep -Seconds 30 

# Configuring the system to use D: as the pagefile location
REG ADD "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /t REG_MULTI_SZ /v PagingFiles /d "D:\pagefile.sys 0 0" /f

Write-host -ForegroundColor Yellow "Preparing to start sysprep process and the system will shut off. DO NOT INTERRUPT THE PROCESS!" 

# Setting location to the sysprep directory
Set-Location C:\Windows\system32\Sysprep

& .\sysprep.exe /oobe /generalize /shutdown 
