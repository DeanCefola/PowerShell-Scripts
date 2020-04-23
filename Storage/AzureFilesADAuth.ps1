#Change the execution policy to unblock importing AzFilesHybrid.psm1 module
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Currentuser

# Navigate to where AzFilesHybrid is unzipped and stored and run to copy the files into your path
.\CopyToPSPath.ps1 

#Import AzFilesHybrid module
Import-Module -name AzFilesHybrid

#Login with an Azure AD credential that has either storage account owner or contributer RBAC assignment
$creds = Get-Credential -Message "Enter Creds"
Connect-AzAccount -Credential $creds

#Select the target subscription for the current session
Select-AzSubscription -SubscriptionId "25603d65-4ffd-4496-815d-417e73e71da3"

###################
#    Variables    #
###################
$ResrouceGroupName  = "<RESOURCE GROUP NAME>"
$StorageAccountName = "<STORAGE ACCOUNT NAME>"
$OUName             = "ACTIVE DIRECTORY OU NAME FOR COMPUTER/SERVICE ACCOUNT OBJECT TO BE CREATED"

#Register the target storage account with your active directory environment under the target OU
join-AzStorageAccountForAuth `
    -ResourceGroupName $ResrouceGroupName `
    -Name $StorageAccountName `
    -DomainAccountType ComputerAccount `
    -OrganizationalUnitName $OUName `
    -Domain $env:USERDNSDOMAIN


#Get the target storage account
$storageaccount = Get-AzStorageAccount `
    -ResourceGroupName $ResrouceGroupName `
    -Name $StorageAccountName

#List the directory service of the selected service account
$storageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions

#List the directory domain information if the storage account has enabled AD authentication for file shares
$storageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties
