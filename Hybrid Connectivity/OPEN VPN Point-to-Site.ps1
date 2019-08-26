  <#Author   : Dean Cefola
# Creation Date: 10-17-2017
# Usage      : AZURE - Create ExpressRoute

#**************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 10/17/2017                     1.0        Intial Version
# 08/20/2019                     2.0        Add OpenVPN  
#***************************************************************************
#
#>

###################
#    Variables    #
###################
$CertLocation = 'C:\temp\VPN'
$Cert = 'AAClient.pfx'
$CertName = "$CertLocation$Cert"


###############################################
#    Create a self-signed root certificate    #
###############################################
if((Test-Path -Path $CertLocation -ErrorAction SilentlyContinue) -eq $false){
    mkdir $CertLocation
    cd $CertLocation
}
else {
    cd $CertLocation
}
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
    -Subject "CN=AARoot" `
    -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 `
    -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyUsageProperty Sign -KeyUsage CertSign


#######################################
#    Generate a client certificate    #
#######################################
New-SelfSignedCertificate `
    -Type Custom `
    -DnsName P2SChildCert `
    -KeySpec Signature `
    -Subject "CN=AAClient" `
    -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 `
    -KeyLength 2048 `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -Signer $cert `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
    

#############################
#    Export Certificates    #
#############################
$RootCert = (Get-ChildItem `
    -Path "Cert:\CurrentUser\My\"`
    | Where-Object `
    -Property subject `
    -Match AARoot)
$ClientCert = (Get-ChildItem `
    -Path "Cert:\CurrentUser\My\"`
    | Where-Object `
    -Property subject `
    -Match AAClient)
Export-Certificate `
    -Type CERT `
    -Cert $RootCert `
    -FilePath "$CertLocation\AARootTemp.cer"
Export-Certificate `
    -Type CERT `
    -Cert $ClientCert `
    -FilePath "$CertLocation\AAClient.cer"
C:\windows\system32\certutil.exe -encode "$CertLocation\AARootTemp.cer" 'AARoot.cer'
Get-Content $CertLocation\AARoot.cer
$SecurePassword = Read-Host `
    -Prompt "Enter Password to Export Cert with Private Key" `
    -AsSecureString
$ThumbPrint = $ClientCert.Thumbprint
$ExportPrivateCertPath = "Cert:\CurrentUser\My\$ThumbPrint"
Export-PfxCertificate `
    -FilePath "C:\temp\VPN\AAClient.pfx" `
    -Password $SecurePassword `
    -Cert $ExportPrivateCertPath
    

#####################################
#    Add OpenSSL to  System Path    #
#####################################
if (-not (Test-Path $profile)) {
    New-Item -Path $profile -ItemType File -Force
}
'$env:path = "C:\ProgramData\chocolatey\bin;C:\Windows\System32;C:\Windows\System32\WindowsPowerShell\;c:\windows;c:\windows\system32\wbem;c:\windows\system32\openssh;c:\program files\git\cmd;C:\Users\DrCef\AppData\Local\Microsoft\WindowsApps;C:\Program Files\Microsoft VS Code Insiders\bin;C:\Users\DrCef\AppData\Local\GitHubDesktop\bin;C:\Users\DrCef\AppData\Local\Microsoft\WindowsApps;C:\Program Files (x86)\Microsoft Visual Studio"' | Out-File $profile -Append
'$env:path = "C:\Program Files\OpenSSL\bin"' | Out-File $profile -Append
'$env:OPENSSL_CONF = "C:\temp\VPN\openssl.cnf"' | out-file $profile -Append
. $profile


############################
#    Install Chocolatey    #
############################
Set-ExecutionPolicy Bypass `
    -Scope Process `
    -Force; `
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
        'https://chocolatey.org/install.ps1'
        )
    )


##########################
#    Download OpenSSL    #
##########################
choco install OpenSSL.Light -y --force
Invoke-WebRequest `
    -Uri 'http://web.mit.edu/crypto/openssl.cnf' `
    -OutFile "$CertLocation\openssl.cnf"


##########################
#    Download OpenVPN    #
##########################
Invoke-WebRequest `
    -Uri 'https://swupdate.openvpn.org/community/releases/openvpn-install-2.4.7-I607-Win10.exe' `
    -OutFile "$CertLocation\openvpn-install-2.4.7-I607-Win10.exe"


#############################
#    Extract Private Key    #
#############################
. $profile
$OpenSSLArgs = "pkcs12 -in C:\temp\vpn\AAClient.pfx -nodes -out c:\temp\vpn\profileinfo.txt"
Start-Process openssl $OpenSSLArgs


#########################
#    Install OpenVPN    #
#########################
Start-Process "$CertLocation\openvpn-install-2.4.7-I607-Win10.exe" /S


