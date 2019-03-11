  <#Author   : Dean Cefola
# Creation Date: 10-17-2017
# Usage      : AZURE - Create Site-to-Site VPN 

#**************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 10/17/2017                       1.0       Intial Version
# 10/04/2018                       1.1       update $PublicIP to be dynamic
#
#***************************************************************************
#
#>
# !!! Admin priveleges are required in order to run this script  !!! #

#######################
#    Set Variables    #
#######################
$AzureConnectionName = Read-Host -Prompt "Enter Name of the Connection to Azure"
$AzureGatewayIP = Read-Host -Prompt "Enter Azure vNET Gateway's Public IP Address"
$SharedKey = Read-Host -Prompt "Enter Azure vNET Connection Shared Key"
$PublicIP = Invoke-WebRequest -Uri ifconfig.me/all.json
$PublicIP = ($PublicIP.Content | ConvertFrom-Json | select ip_addr).ip_addr
$IPAddressRange = $PublicIP +':100'
Function Invoke-WindowsApi {
<# 
 .Synopsis
    This Function will discover all the Deployments for your Resource Group
    After discovery it will enumerate the resources in that deployment

 .Description
    Discover resources in azure deployments

 .Parameter RGName
    ResourceGroup Name to discover deployments

 .Example
    Get-AzureResourceFromDeployments -RGName AzureRGName

   
#>
[Cmdletbinding()]
Param ( 
    [string] $dllName,  
    [Type] $returnType,  
    [string] $methodName, 
    [Type[]] $parameterTypes, 
    [Object[]] $parameters 
)
Begin {
    ## Begin to build the dynamic assembly 
    $domain = [AppDomain]::CurrentDomain 
    $name = New-Object Reflection.AssemblyName 'PInvokeAssembly' 
    $assembly = $domain.DefineDynamicAssembly($name, 'Run') 
    $module = $assembly.DefineDynamicModule('PInvokeModule') 
    $type = $module.DefineType('PInvokeType', "Public,BeforeFieldInit") 
    $inputParameters = @() 
}
Process {
    for($counter = 1; $counter -le $parameterTypes.Length; $counter++) { 
        $inputParameters += $parameters[$counter - 1] 
    } 
    $method = $type.DefineMethod($methodName, 'Public,HideBySig,Static,PinvokeImpl',$returnType, $parameterTypes) 
    ## Apply the P/Invoke constructor 
    $ctor = [Runtime.InteropServices.DllImportAttribute].GetConstructor([string]) 
    $attr = New-Object Reflection.Emit.CustomAttributeBuilder $ctor, $dllName 
    $method.SetCustomAttribute($attr) 
    ## Create the temporary type, and invoke the method. 
    $realType = $type.CreateType() 
    $ret = $realType.InvokeMember($methodName, 'Public,Static,InvokeMethod', $null, $null, $inputParameters) 
    return $ret
}
End {

}
}
Function Set-PrivateProfileString {
Param ( 
    $file, 
    $category, 
    $key, 
    $value
) 

Begin {
  ## Prepare the parameter types and parameter values for the Invoke-WindowsApi script 
  $parameterTypes = [string], [string], [string], [string] 
  $parameters = [string] $category, [string] $key, [string] $value, [string] $file 

  ## Invoke the API 
  [void] (Invoke-WindowsApi "kernel32.dll" ([UInt32]) "WritePrivateProfileString" $parameterTypes $parameters)
}

}


##################################
#    Install RRAS Server Role    #
##################################
Import-Module ServerManager
Install-WindowsFeature RemoteAccess -IncludeManagementTools
Add-WindowsFeature -name Routing -IncludeManagementTools


#########################
#    Install S2S VPN    #
#########################
Import-Module RemoteAccess
if ((Get-RemoteAccess).VpnS2SStatus -ne "Installed") {
    Install-RemoteAccess -VpnType VpnS2S
}


###############################
#    Add S2S VPN interface    #
###############################
Add-VpnS2SInterface `
    -Protocol IKEv2 `
    -AuthenticationMethod PSKOnly `
    -NumberOfTries 3 `
    -ResponderAuthenticationMethod PSKOnly `
    -Name $AzureConnectionName `
    -Destination $AzureGatewayIP `
    -IPv4Subnet @("$IPAddressRamge") `
    -SharedSecret $SharedKey


#####################################
#    Configure S2S VPN interface    #
#####################################
Set-VpnServerIPsecConfiguration `
    -EncryptionType MaximumEncryption
Set-VpnS2Sinterface `
    -Name $AzureConnectionName `
    -InitiateConfigPayload $false `
    -Persistent `
    -AutoConnectEnabled `
    -Force


#############################################
#    S2S VPN connection to be persistent    #
#############################################
Set-PrivateProfileString `
    -file $env:windir\System32\ras\router.pbk `
    -category IdleDisconnectSeconds `
    -key $AzureConnectionName `
    -value 0
Set-PrivateProfileString `
    -file $env:windir\System32\ras\router.pbk `
    -category RedialOnLinkFailure `
    -key $AzureConnectionName `
    -value 1

##################################
#    Restart the RRAS service    #
##################################
Restart-Service RemoteAccess


##################################
#    Connect to Azure gateway    #
##################################
Connect-VpnS2SInterface -Name $AzureConnectionName


########################
#    Get VPN Status    #
########################
Get-VpnS2SInterface -Name $AzureConnectionName
