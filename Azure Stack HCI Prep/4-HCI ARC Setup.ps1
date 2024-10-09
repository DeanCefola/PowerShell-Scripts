
########################
#    Azure ARC Prep    #
########################
Register-PSRepository -Default -InstallationPolicy Trusted

Install-Module AzsHCI.ARCinstaller

Install-Module Az.Accounts -Force
Install-Module Az.ConnectedMachine -Force
Install-Module Az.Resources -Force


##########################
#    Azure ARC Config    #
##########################
$Tenant = "YourTenantID"
$Subscription = "YourSubscriptionID"
$RG = "YourResourceGroupName"
$Region = "eastus"
Connect-AzAccount `
    -SubscriptionId $Subscription `
    -TenantId $Tenant `
    -DeviceCode

$ARMtoken = (Get-AzAccessToken).Token
$id = (Get-AzContext).Account.Id

Invoke-AzStackHciArcInitialization `
    -SubscriptionID $Subscription `
    -ResourceGroup $RG `
    -TenantID $Tenant `
    -Region $Region `
    -Cloud "AzureCloud" `
    -ArmAccessToken $ARMtoken `
    -AccountID $id


