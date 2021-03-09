

#################
#    PreReqs    #
#################
Register-AzProviderFeature `
    -FeatureName VirtualMachineTemplatePreview `
    -ProviderNamespace Microsoft.VirtualMachineImages
Wait-Event -Timeout 20
Get-AzProviderFeature `
    -FeatureName VirtualMachineTemplatePreview `
    -ProviderNamespace Microsoft.VirtualMachineImages
# If they do not saw registered, run the commented out code below.
## Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
## Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
## Register-AzResourceProvider -ProviderNamespace Microsoft.Compute
## Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault


##########################################
#    Set up environment and variables    #
##########################################
$currentAzContext   = Get-AzContext
$imageResourceGroup = 'AIB-Rg'
$location           = 'eastus'
$subscriptionID     = $currentAzContext.Subscription.Id
$imageTemplateName  = 'wvd10ImageTemplate01'
$runOutputName      = 'sigOutput'
$CompanyName        = 'MSAzureAcademy'
Import-Module Az.Accounts
New-AzResourceGroup `
    -Name $imageResourceGroup `
    -Location $location


###########################################################
#    Permissions, create user idenity and role for AIB    #
###########################################################
$timeInt          = $((get-date -UFormat "%s").Split('.')[0])
$imageRoleDefName = "Azure Image Builder Image Def"+$timeInt
$idenityName      = "aibIdentity"+$timeInt
'Az.ImageBuilder', 'Az.ManagedServiceIdentity' | ForEach-Object {
    Install-Module -Name $_ -AllowPrerelease
}
New-AzUserAssignedIdentity `
    -ResourceGroupName $imageResourceGroup `
    -Name $idenityName
$idenityNameResourceId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).Id
$idenityNamePrincipalId=$(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).PrincipalId


##############################################################
#    Assign permissions for identity to distribute images    #
##############################################################
##NOTE:  Sometimes the timing of things in creating the New Role and assigning Permissions 
##           to the managed Identity are off...So you may need to run the command again after a minute or two

$aibRoleImageCreationUrl  = "https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
$aibRoleImageCreationPath = "aibRoleImageCreation.json"
Invoke-WebRequest `
    -Uri $aibRoleImageCreationUrl `
    -OutFile $aibRoleImageCreationPath `
    -UseBasicParsing
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath
New-AzRoleDefinition `
    -InputFile  ./aibRoleImageCreation.json
Wait-Event -Timeout 30
New-AzRoleAssignment `
    -ObjectId $idenityNamePrincipalId `
    -RoleDefinitionName $imageRoleDefName `
    -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"


#########################################
#    Create the Shared Image Gallery    #
#########################################
$sigGalleryName = "myaibsig01"
$imageDefName   = "win10wvd"

# create gallery
New-AzGallery `
    -GalleryName $sigGalleryName `
    -ResourceGroupName $imageResourceGroup  `
    -Location $location

# create gallery definition
New-AzGalleryImageDefinition `
    -GalleryName $sigGalleryName `
    -ResourceGroupName $imageResourceGroup `
    -Location $location `
    -Name $imageDefName `
    -OsState generalized `
    -OsType Windows `
    -Publisher $CompanyName `
    -Offer 'Windows' `
    -Sku '10wvd'


#############################################
#    Download & Configure Image Template    #
#############################################
$templateUrl="https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/14_Building_Images_WVD/armTemplateWVD.json"
$templateFilePath = "armTemplateWVD.json"
Invoke-WebRequest `
    -Uri $templateUrl `
    -OutFile $templateFilePath `
    -UseBasicParsing
((Get-Content -path $templateFilePath -Raw) -replace '<subscriptionID>',$subscriptionID) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<rgName>',$imageResourceGroup) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region>',$location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<runOutputName>',$runOutputName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imageDefName>',$imageDefName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<sharedImageGalName>',$sigGalleryName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region1>',$location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>',$idenityNameResourceId) | Set-Content -Path $templateFilePath


#############################
#    Submit the template    #
#############################
New-AzResourceGroupDeployment `
    -ResourceGroupName $imageResourceGroup `
    -TemplateFile $templateFilePath `
    -api-version "2020-02-14" `
    -imageTemplateName $imageTemplateName `
    -svclocation $location
$getStatus = $(Get-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName)
$getStatus.ProvisioningErrorCode 
$getStatus.ProvisioningErrorMessage


#########################
#    Build the image    #
#########################
Start-AzImageBuilderTemplate `
    -ResourceGroupName $imageResourceGroup `
    -Name $imageTemplateName `
    -NoWait
$getStatus = $(Get-AzImageBuilderTemplate -ResourceGroupName $imageResourceGroup -Name $imageTemplateName)
$getStatus | Format-List -Property *
$getStatus.LastRunStatusRunState 
$getStatus.LastRunStatusMessage
$getStatus.LastRunStatusRunSubState
