
Function New-AzureVMEncryptPrep {
<# 
 .Synopsis
    Create a new resource group or use existing Resource Group
    Script will create the following resources    
        1.  Resource Group if does not exist
        2.  Azure AD Application 
        3.  Azure KeyVault
            i.  Secrets
                1.  Disk Encryption Secret
            ii. Assign Azure AD Application KeyVault Permissions
            
 .Description
    Azure Disk Encryption Preperation
     
 .Parameter Prefix
    This code for will be used as a prefix for all resources deployed to keep them unique
 
 .Parameter ResourceGroupName
    This code for will be used as a prefix for all resources deployed to keep them unique
 
 .Parameter Location
    primary Azure region used in this deployment 

 .Parameter KeyVaultAdmin
    Email address that will administer KeyVault secrets 
    
 .Example
 # Create new Azure Deployment
New-AzureVMEncryptPrep `
    -Prefix zx9 `
    -ResourceGroupName zx9-RG-security `
    -Location southcentralus `
    -KeyVaultAdmin KeyVaultAdmin@Contoso.com

#>
[Cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
        [string]$Prefix,
    [Parameter(Mandatory=$true)]
        [string]$ResourceGroupName,    
    [Parameter(Mandatory=$true)]
        [validateset('australiaeast','australiasoutheast','brazilsouth','canadacentral', `
        'canadaeast','centralindia','centralus','eastasia','eastus','eastus2','japaneast', `
        'japanwest','koreacentral','koreasouth','northcentralus','northeurope','southcentralus', `
        'southeastasia','southindia','uksouth','ukwest','westcentralus','westeurope','westindia', `
        'westus','westus2')]
        [string]$Location,
    [Parameter(Mandatory=$true)]
        [string]$KeyVaultAdmin,
    [Parameter(Mandatory=$false)]
        [bool]$GenerateKeyCert=$false

)

Begin {    
    cls
    $Prefix = $Prefix.ToLower()
    $RGName = $ResourceGroupName
    $KVName = $Prefix+"-KeyVault01"        
    $AADDisplayName = $Prefix+"AzureDiskEncryptApp"
    $SecretName = 'AzureDiskEncryption'
    $AADClientSecret = $Prefix+"disksecret"
}

Process {   
    ################################
    #    Create Resource Groups    #
    ################################    
    if ((Get-AzureRmResourceGroup -Name $RGName -ErrorAction SilentlyContinue) -eq $null) {
        Write-Host `
            -ForegroundColor Green `
            -BackgroundColor Black `
            "Creating New Azure Resource Group $RGName"
        ""
        New-AzureRmResourceGroup `
            -Name $RGName `
            -Location $Location
        wait-event -Timeout 5
    }        
    Else {
        Write-Host `
            -ForegroundColor Yellow `
            -BackgroundColor Black `
            "ResourceGroup $RGName already exists"
        ""
        wait-event -Timeout 2
    }      
    ################################
    #    Create Azure Key Vault    #
    ################################    
    if ((Get-AzureRmKeyVault -ResourceGroupName $RGName -VaultName $KVName -ErrorAction SilentlyContinue) -eq $null) {
        Write-Host `
            -ForegroundColor Green `
            -BackgroundColor Black `
            "Creating New Azure KeyVault"
        ""
        New-AzureRmKeyVault `
            -VaultName $KVName `
            -ResourceGroupName $RGName `
            -Location $Location `
            -EnabledForDeployment `
            -EnabledForTemplateDeployment `
            -EnabledForDiskEncryption `
            -Sku Premium `
            -DefaultProfile (Get-AzureRmContext)
        wait-event -timeout 5
        ''
        Write-Host `
            -ForegroundColor green `
            -BackgroundColor Black `
            "Setting VaultAdmin permissions"
        ""
        $ID = (Get-AzureRmADUser -UserPrincipalName $KeyVaultAdmin).id.guid
        Set-AzureRmKeyVaultAccessPolicy `
            -VaultName $KVName  `
            -ResourceGroupName $RGName `
            -ObjectId $ID `
            -PermissionsToSecrets get, list, set, delete, backup, restore, recover, purge `
            -Verbose
    }
    Else {
        Write-Host `
            -ForegroundColor Yellow `
            -BackgroundColor Black `
            "KeyVault $KVName already exists"
        ""
        wait-event -Timeout 2
    } 
    If (((get-azurermkeyvault -ResourceGroupName $RGName -VaultName $KVName -ErrorAction SilentlyContinue).EnabledForDiskEncryption) -eq $false){
        Write-Host `
            -ForegroundColor Green `
            -BackgroundColor Black `
            "Enabling Disk Encryption"
        Set-AzureRmKeyVaultAccessPolicy `
            -ResourceGroupName $RGName `
            -VaultName $KVName `
            -EnabledForDiskEncryption 
        ""
    }
    Else {
        Write-Host `
            -ForegroundColor Yellow `
            -BackgroundColor Black `
            "Disk Encryption is already Enabled"
        ""
    }
    #####################################################
    #           Create Azure Key Vault Secrets          #
    #####################################################
    if ((Get-AzureKeyVaultSecret -VaultName $KVName -Name $SecretName -ErrorAction SilentlyContinue) -eq $null) {
        Write-Host `
            -ForegroundColor Green `
            -BackgroundColor Black `
            "Creating New Local Admin Secret"
        ""
        $AADSecret = ConvertTo-SecureString `
            -String $AADClientSecret `
            -AsPlainText `
            -Force
        Set-AzureKeyVaultSecret `
            -VaultName $KVName `
            -Name $secretName `
            -SecretValue $AADSecret    
        }
    Else {
        Write-Host `
            -ForegroundColor Yellow `
            -BackgroundColor Black `
            "Disk Encryption Secret already exists"
        ""
    }
    #####################################################
    #    Create Azure AD Application for Encryption     #
    #####################################################    
    If ((Get-AzureRmADApplication -DisplayNameStartWith $AADDisplayName -ErrorAction SilentlyContinue) -eq $null) {
        Write-Host `
            -ForegroundColor Green `
            -BackgroundColor Black `
            "Creating Disk Encryption Application"
        ""
        $AAD_App = New-AzureRmADApplication `
            -DisplayName $AADDisplayName `
            -HomePage "http://homepage$AADDisplayName" `
            -IdentifierUris "http://$AADDisplayName" `
            -Password $AADSecret            
        $AAD_ID = $AAD_App.ApplicationId.Guid
        ""
        New-AzureRmADServicePrincipal -ApplicationId $AAD_ID
        ""
        $AAD_SPN = (Get-AzureRmADServicePrincipal -SearchString $AADDisplayName).Id.Guid
        Set-AzureRmKeyVaultAccessPolicy `
            -VaultName $KVName  `
            -ResourceGroupName $RGName `
            -ServicePrincipalName $AAD_ID  `
            -PermissionsToKeys wrapKey  `
            -PermissionsToSecrets set 
    }
    Else {
        Write-Host `
            -ForegroundColor Yellow `
            -BackgroundColor Black `
            "Azure AD App already exists"
        ""      
        $AAD_ID = (Get-AzureRmADApplication -DisplayNameStartWith $AADDisplayName).ApplicationId.Guid
        $AAD_SPN = (Get-AzureRmADServicePrincipal -SearchString $AADDisplayName).Id.Guid
        Set-AzureRmKeyVaultAccessPolicy `
            -VaultName $KVName  `
            -ResourceGroupName $RGName `
            -ServicePrincipalName $AAD_ID  `
            -PermissionsToKeys wrapKey `
            -PermissionsToSecrets set
    }
    <##############################################
    #    Generate Cert for Key Encryption Key    #
    ##############################################
    If(($GenerateKeyCert -eq $true)){
         Write-Host `
            -ForegroundColor Magenta `
            -BackgroundColor Black `
            "New Certificate for Key Encryption Key (KEK) Requested..."
        ""         
        $exportPath = 'C:\temp\'
        $exportFile = 'C:\temp\Diskencrypt.pfx'
        #########################
        #    Create New Cert    #
        #########################
        If((Get-ChildItem Cert:\Localmachine\my | ? -Property subject -eq 'CN=DiskEncryptionCert' -ErrorAction SilentlyContinue) -eq $null) {
            Write-Host `
                -ForegroundColor Green `
                -BackgroundColor Black `
                "Creating New Cert for Key Encryption Key (KEK)"
            $Cert = New-SelfSignedCertificate `
                -Subject "CN=DiskEncryptionCert" `
                -CertStoreLocation "cert:\LocalMachine\My" `
                -FriendlyName "DiskEncryptionCert" `
                -NotAfter (Get-Date).AddMonths(60) `
                -KeyAlgorithm RSA `
                -KeyLength 2048 `
                -Type Custom            
        }
        Else {
           Wait-Event -Timeout 2
           Write-Host `
            -ForegroundColor Yellow `
            -BackgroundColor Black `
            "Cert Already Exists, Verifying Export..."
        }
        ##############################
        #    Create Export Folder    #
        ##############################
        if((Test-Path -LiteralPath $exportPath -ErrorAction SilentlyContinue)-eq $false){
            Write-Host `
                -ForegroundColor Green `
                -BackgroundColor Black `
                "Creating Cert Export Folder"
            New-Item -Path $exportPath -ItemType Directory -Force
        }
        Else {
            Write-Host `
                -ForegroundColor Yellow `
                -BackgroundColor Black `
                "Export Folder Exists Already...Checking for Certificate"                
        }
        ###############################
        #    Export Cert to Folder    #
        ###############################
        if((Test-Path -LiteralPath $exportFile -ErrorAction SilentlyContinue) -eq $false) {
            Export-PfxCertificate `
                -Cert $Cert `
                -Password (ConvertTo-SecureString "$AADClientSecret" -AsPlainText -Force) `
                -FilePath Diskencrypt.pfx `
                -Force
            Write-Host `
                -ForegroundColor Cyan `
                -BackgroundColor Black `
                "Certificate is located at $exportFile" 

        }
        Else {
            Write-Host `
                -ForegroundColor Magenta `
                -BackgroundColor Black `
                "Certificate is available - $exportFile" 
        }
    }
    Else {
        Write-Host `
            -ForegroundColor Yellow `
            -BackgroundColor Black `
            "No Cert Requested"
    }
    ##############################
    #    Upload Cert to Azure    #
    ##############################
    if((Get-AzureKeyVaultCertificate -VaultName $KVName -Name Diskencrypt -ErrorAction SilentlyContinue) -eq $null){
        Write-Host `
            -ForegroundColor Green `
            -BackgroundColor Black `
            "Importing Cert into KeyVault"
        
        $KVCert = Get-AzureKeyVaultCertificate -VaultName $KVName -Name Diskencrypt
        $KVCert.SecretId
    }
    Else {
        Write-Host `
            -ForegroundColor Yellow `
            -BackgroundColor Black `
            "Cert Already Imported to KeyVault"
        $KVCert = Get-AzureKeyVaultCertificate -VaultName $KVName -Name Diskencrypt
        $KVCert.SecretId
    }
    #>
    ##################################
    #    Prepare Output Variables    #
    ##################################
    $KV = Get-AzureRmKeyVault -VaultName $KVName -ResourceGroupName $RGName
    $KVuri = $KV.VaultUri
}

End {        
    Write-host `
        -ForegroundColor Red `
        "    ########################
    #    Script Outputs    #
    ########################
    " 
        
    Write-host "Azure AD App name                 = $AADDisplayName"
    Write-host "Azure AD Client ID for Encryption = $AAD_ID"
    Write-host "Azure AD Client Secret to Encrypt = $AADClientSecret"
    ""    
    Write-host "Key Vault Name   = $KVName"
    Write-host "KeyVault RGName  = $RGName"
    Write-host "Key Vault URL    = $KVuri"    
    
    Clear-History
}

}

New-AzureVMEncryptPrep `
    -Prefix AA `
    -ResourceGroupName AzureAcademy `
    -Location eastus `
    -KeyVaultAdmin deacef@microsoft.com
