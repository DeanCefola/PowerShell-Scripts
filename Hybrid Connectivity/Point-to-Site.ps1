  <#Author   : Dean Cefola
# Creation Date: 10-17-2017
# Usage      : AZURE - Create ExpressRoute

#**************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 10/17/2017                       1.0       Intial Version
# 
#***************************************************************************
#
#>

###############################################
#    Create a self-signed root certificate    #
###############################################
if((Test-Path -Path c:\temp -ErrorAction SilentlyContinue) -eq $false){
    mkdir C:\temp
    cd 'C:\temp'
}
else {
    cd 'C:\temp'
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
    -FilePath 'C:\temp\AARootTemp.cer' `
    -Force
Export-Certificate `
    -Type CERT `
    -Cert $ClientCert `
    -FilePath 'C:\temp\AAClient.cer' `
    -Force
certutil -encode 'C:\temp\AARootTemp.cer' 'AARoot.cer'
Get-Content C:\temp\AARoot.cer
cd c:\
