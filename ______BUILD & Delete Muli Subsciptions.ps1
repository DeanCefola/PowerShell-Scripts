<#Author       : Dean Cefola
# Creation Date: 08-01-2019
# Usage        : Ignite Prep - 80 subscriptions 

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 08/01/2019                     1.0        Intial Version
# 09/12/2019                     2.0        Prep for 80 Ignite Subscriptions
# 10/15/2019                     3.0        Testing complete (taking too long)
# 10/25/2019                     4.0        Upgrade all processes to PS Jobs 
#
#*********************************************************************************
#
#>


####################################
#    Install PowerShell Modules    #
####################################
Find-Module -Name AzureAD     | Install-Module -Force -AllowClobber -Verbose
Find-Module -Name AZ          | Install-Module -Force -AllowClobber -Verbose
Find-Module -Name AzureRM     | Install-Module -Force -AllowClobber -Verbose
Find-Module -Name MSonline    | Install-Module -Force -AllowClobber -Verbose
Find-Module -Name Az.Blueprint| Install-Module -Force -AllowClobber -Verbose
Find-Module -Name Az.Security | Install-Module -Force -AllowClobber -Verbose


################################
#    Authenticate to Azure     #
################################
$Admin = '<TYPE EMAIL WITH AZURE ACCESS i.e. user1@mydomain.onmicrosoft.com>'
$creds = Get-Credential `
    -UserName $Admin `
    -Message "Enter Password for Azure Credentials"
Login-AzAccount -Credential $creds
Connect-AzureAD -Credential $creds
connect-msolservice -credential $creds


##################################
#    Azure AD Users Variables    #
##################################
$Prefix = 'IgniteUser'
$DomainName = '<TYPE DOMAIN NAME WITHOUT THE .com EXTENSION i.e. IgniteCAFDemo.onmicrosoft>'
$DomainSuffix = 'com'
$FQDN = "$DomainName.$DomainSuffix"
$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = 'Pa$$wd!@#01'
$PasswordProfile.EnforceChangePasswordPolicy = $false
$PasswordProfile.ForceChangePasswordNextLogin = $false


######PREP ENVIRONMENT############PREP ENVIRONMENT############PREP ENVIRONMENT############
######PREP ENVIRONMENT############PREP ENVIRONMENT############PREP ENVIRONMENT############
######PREP ENVIRONMENT############PREP ENVIRONMENT############PREP ENVIRONMENT############
######PREP ENVIRONMENT############PREP ENVIRONMENT############PREP ENVIRONMENT############
######PREP ENVIRONMENT############PREP ENVIRONMENT############PREP ENVIRONMENT############


###############################
#    Create Azure AD Users    #
###############################
$Number = 1..80
ForEach($N in $Number){
 $AzureADUsersList = @(                                 
	,@("$Prefix$N",  "$Prefix$N@$FQDN")
) 
    ForEach($RM in $AzureADUsersList) {  
        $RM_Name =  $RM[0]
        $RM_Email = $RM[1]
        Start-Job `
            -Name "NewUser-$N" `
            -ScriptBlock {
                Connect-AzureAD -Credential $args[5]
                New-AzureADUser `
                    -DisplayName $args[0] `
                    -PasswordProfile $args[1] `
                    -UserPrincipalName $args[2] `
                    -AccountEnabled $args[3] `
                    -MailNickName $args[4] `
                    -Verbose             
            } `
            -ArgumentList $RM_Name, $PasswordProfile, $RM_Email, $true, $RM_Name, $creds  `
            -Verbose 
    }
}


##################################################
#    Assign Subscriptions to ManagementGroups    #
##################################################
$Number = 1..20
$TenantID = (Get-AzSubscription | select -First 1).TenantID     
$MGAll = (Get-AzManagementGroup -GroupName $TenantID -Expand).Children
$MGGroup = $MGAll | Where-Object type -Match managementGroups
$MGSub = $MGAll | Where-Object type -Match subscription
ForEach($N in $Number){
     $IGNITE_Sub = @(  
        ,@("Prod", "$Prefix$N")
    ) 
    ForEach($IS in $IGNITE_Sub) {  
        $MG_Name =  $IS[0]
        $Sub_Name = $IS[1]  
        ForEach($S in $Sub_Name) {
            $Sub = (Get-AzManagementGroup `
                -GroupName $TenantID `
                -Expand).Children | `
                    Where-Object -Property DisplayName -EQ $Sub_Name
            $SubID = $Sub.Id.split('/')[2]            
            Start-Job `
                -Name "MGAssign-$N" `
                -ScriptBlock {
                        New-AzManagementGroupSubscription `
                            -GroupName $args[0] `
                            -SubscriptionId $args[1]    
                    } `
                -ArgumentList $MG_Name, $SubID  `
                -Verbose  
        }
    }
}
$Number = 21..40
ForEach($N in $Number){
     $IGNITE_Sub = @(  
        ,@("Dev", "$Prefix$N")
    ) 
    ForEach($IS in $IGNITE_Sub) {  
        $MG_Name =  $IS[0]
        $Sub_Name = $IS[1]  
        ForEach($S in $Sub_Name) {
            $Sub = (Get-AzManagementGroup `
                -GroupName $TenantID `
                -Expand).Children | `
                    Where-Object -Property DisplayName -EQ $Sub_Name
            $SubID = $Sub.Id.split('/')[2]            
            Start-Job `
                -Name "MGAssign-$N" `
                -ScriptBlock {
                        New-AzManagementGroupSubscription `
                            -GroupName $args[0] `
                            -SubscriptionId $args[1]    
                    } `
                -ArgumentList $MG_Name, $SubID  `
                -Verbose  
        }
    }
}
$Number = 41..60
ForEach($N in $Number){
     $IGNITE_Sub = @(  
        ,@("Sandbox", "$Prefix$N")
    ) 
    ForEach($IS in $IGNITE_Sub) {  
        $MG_Name =  $IS[0]
        $Sub_Name = $IS[1]  
        ForEach($S in $Sub_Name) {
            $Sub = (Get-AzManagementGroup `
                -GroupName $TenantID `
                -Expand).Children | `
                    Where-Object -Property DisplayName -EQ $Sub_Name
            $SubID = $Sub.Id.split('/')[2]            
            Start-Job `
                -Name "MGAssign-$N" `
                -ScriptBlock {
                        New-AzManagementGroupSubscription `
                            -GroupName $args[0] `
                            -SubscriptionId $args[1]    
                    } `
                -ArgumentList $MG_Name, $SubID  `
                -Verbose  
        }
    }
}
$Number = 61..80
ForEach($N in $Number){
     $IGNITE_Sub = @(  
        ,@("UAT", "$Prefix$N")
    ) 
    ForEach($IS in $IGNITE_Sub) {  
        $MG_Name =  $IS[0]
        $Sub_Name = $IS[1]  
        ForEach($S in $Sub_Name) {
            $Sub = (Get-AzManagementGroup `
                -GroupName $TenantID `
                -Expand).Children | `
                    Where-Object -Property DisplayName -EQ $Sub_Name
            $SubID = $Sub.Id.split('/')[2]            
            Start-Job `
                -Name "MGAssign-$N" `
                -ScriptBlock {
                        New-AzManagementGroupSubscription `
                            -GroupName $args[0] `
                            -SubscriptionId $args[1]    
                    } `
                -ArgumentList $MG_Name, $SubID  `
                -Verbose  
        }
    }
}


############################################
#    Assign Users to Subscription Owner    #
############################################
$Number = 1..80
ForEach($N in $Number){
 $AzureADUsersList = @(                                 
	,@("$Prefix$N",  "$Prefix$N@$FQDN")
) 
    ForEach($RM in $AzureADUsersList) {  
        $RM_Name =  $RM[0]
        $RM_Email = $RM[1]
        $SubID = (Get-AzSubscription | Where-Object name -eq $RM_Name).Id        
        Select-AzSubscription $SubID
        New-AzRoleAssignment `
            -Scope "/subscriptions/$SubID" `
            -SignInName $RM_Email `
            -RoleDefinitionName Owner `
            -ErrorAction SilentlyContinue `
            -Verbose
    }
}


#########################################
#    Assign CAF-Foundation Blueprint    #
#########################################
$TenantID = (Get-AzSubscription | select -First 1).TenantID 
$Number = 1..80
ForEach($N in $Number){
 $AzureADUsersList = @(                                 
	,@("$Prefix$N",  "$Prefix$N@$FQDN")
) 
    ForEach($RM in $AzureADUsersList) {  
        $RM_Name =  $RM[0]
        $RM_Email = $RM[1]
        $SubID = (Get-AzSubscription | Where-Object name -eq $RM_Name).Id
        Write $SubID
        $BPOrgName = "Ignite-$N"
        Start-Job `
            -Name "BPAssign-$N" `
            -ScriptBlock {
                $blueprintObject =  Get-AzBlueprint `
                    -ManagementGroupId $args[2] | `
                    Where-Object name -EQ CAF-Foundation               
                New-AzBlueprintAssignment `
                    -Name $args[0] `
                    -Blueprint $blueprintObject `
                    -Location eastus `
                    -SubscriptionId $args[1] `
                    -Parameter @{
                        'Policy_Allowed-StorageAccount-SKUs' = "Premium_LRS","Standard_LRS","Standard_ZRS" ;
                        'Policy_Allowed-VM-SKUs' =  "Standard_B1s","Standard_B2ms" ;
                        'Policy_CostCenter_Tag' = $args[0] ;
                        'Policy_Allowed-Locations' = "australiacentral","australiacentral2",`
                            "australiaeast","australiasoutheast","centralus","eastus","eastus2",`
                            "northcentralus","southcentralus","westcentralus","westus","westus2";
                        'Policy_Resource-Types-DENY' = "", "" ;
                        'Organization_Name' = $args[0] ; 
                        'LogAnalytics_DataRetention' = 30 ;
                        'LogAnalytics_Location' = "East US";
                        'KV-AccessPolicy' = "23b4fb48-4458-4701-9da9-da8363bce1b2" ; 
                        'AzureRegion' = "eastus"
                    }
            } `
            -ArgumentList $BPOrgName, $SubID, $TenantID `
            -Verbose
    }
        
}



######DELETE RESOURCES############DELETE RESOURCES############DELETE RESOURCES############
######DELETE RESOURCES############DELETE RESOURCES############DELETE RESOURCES############
######DELETE RESOURCES############DELETE RESOURCES############DELETE RESOURCES############
######DELETE RESOURCES############DELETE RESOURCES############DELETE RESOURCES############
######DELETE RESOURCES############DELETE RESOURCES############DELETE RESOURCES############


######################################
#    Remove Blueprint Assignments    #
######################################
$Number = 1..80
$TenantID = (Get-AzSubscription | select -First 1).TenantID 
ForEach($N in $Number){
 $AzureADUsersList = @(                                 
	,@("$Prefix$N",  "$Prefix$N@$FQDN")
) 
    ForEach($RM in $AzureADUsersList) {  
        $RM_Name =  $RM[0]
        $RM_Email = $RM[1]
        $SubID = (Get-AzSubscription | Where-Object name -eq $RM_Name).Id
        Select-AzSubscription $SubID
        Get-AzBlueprintAssignment -SubscriptionId $SubID
        $BP = Get-AzBlueprintAssignment
        foreach($Assignment in $BP){
            Remove-AzBlueprintAssignment -Name $Assignment.name -Verbose
        }
    }        
}


#######################################
#    Reset Security Center to Free    #
#######################################
$Number = 1..80
ForEach($N in $Number){
 $AzureADUsersList = @(                                 
	,@("$Prefix$N",  "$Prefix$N@$FQDN")
) 
    ForEach($RM in $AzureADUsersList) {  
        $RM_Name =  $RM[0]
        $RM_Email = $RM[1]
        $SubID = (Get-AzSubscription | Where-Object name -eq $RM_Name).Id
        ForEach ($S in $SubID) {
            Select-AzSubscription $S
            Start-Job `
                -ScriptBlock {
                    $SecurityCenter = Get-AzSecurityPricing
                    foreach ($Sec in $SecurityCenter) {
                        Set-AzSecurityPricing `
                            -Name $sec.name `
                            -PricingTier Free `
                            -Verbose  
                    }
                } `
                -Name "Rem-SecCenter-$N" `
                -Verbose
        }
    }
}


###############################
#    Delete Resource Locks    #
###############################
$Number = 1..80
ForEach($N in $Number){
 $AzureADUsersList = @(                                 
	,@("$Prefix$N",  "$Prefix$N@$FQDN")
) 
    ForEach($RM in $AzureADUsersList) {  
        $RM_Name =  $RM[0]
        $RM_Email = $RM[1]
        $SubID = (Get-AzSubscription | Where-Object name -eq $RM_Name).Id
        ForEach ($S in $SubID) {
            Select-AzSubscription $S
            Start-Job `
                -ScriptBlock {
                    Get-AzResourceLock | Remove-AzResourceLock -Force -Verbose
                    Wait-Event -Timeout 5
                } `
                -Name "Rem-Locks-$N" `
                -Verbose
        }
    }
}


###############################
#    Remove Azure Policies    #
###############################
$Number = 1..80
ForEach($N in $Number){
 $AzureADUsersList = @(                                 
	,@("$Prefix$N",  "$Prefix$N@$FQDN")
) 
    ForEach($RM in $AzureADUsersList) {  
        $RM_Name =  $RM[0]
        $RM_Email = $RM[1]
        $SubID = (Get-AzSubscription | Where-Object name -eq $RM_Name).Id
        ForEach ($S in $SubID){
            Select-AzSubscription $S
            $Policy = Get-AzPolicyAssignment -Scope "/subscriptions/$S" 
            ForEach ($P in $Policy) {
                Start-Job `
                    -ScriptBlock {
                        Remove-AzPolicyAssignment -Id $args[0] -Verbose
                    } `
                    -ArgumentList $P.PolicyAssignmentId `
                    -Name "Rem-Policy-$N" `
                    -Verbose
                Wait-Event -Timeout 5
            }
        }
    }
}


################################
#    Delete Resource Groups    #
################################
$Number = 1..80
ForEach($N in $Number){
 $AzureADUsersList = @(                                 
	,@("$Prefix$N",  "$Prefix$N@$FQDN")
) 
    ForEach($RM in $AzureADUsersList) {  
        $RM_Name =  $RM[0]
        $RM_Email = $RM[1]
        $Sub = (Get-AzSubscription | Where-Object name -eq $RM_Name)
        ForEach ($S in $Sub){ 
            Select-AzSubscription $RM_Name           
            $RG = Get-AzResourceGroup | `
                Where-Object `
                    -Property ResourceGroupName `
                    -NE  cloud-shell-storage-eastus
            ForEach ($R in $RG) {               
                Start-Job `
                    -ScriptBlock {
                    Select-AzSubscription $args[0]
                    Remove-AzResourceGroup -Name $args[1] -Force
                } `
                    -ArgumentList $S.Id, $R.ResourceGroupName `
                    -Name "Rem-RG$N" `
                    -Verbose
                Wait-Event -Timeout 5
            }
        }
    }
}


###############################
#    Remove Azure AD Users    #
###############################
Get-AzureADUser `
    | Where-Object DisplayName `
    -Match IgniteUser `
    | Remove-AzureADUser `
        -Verbose


######################################################
#    Reset Subscriptions to Root Management Group    #   
######################################################
$TenantID = (Get-AzSubscription | select -First 1).TenantID
$Subs = (Get-AzManagementGroup -GroupName dev -Expand).Children.id
foreach($S in $Subs) {     
    $ITEM = $S.split('/')[2]
    Start-Job `
        -Name "RemMGSub$N" `
        -ScriptBlock {
            New-AzManagementGroupSubscription `
                -GroupName $args[0] `
                -SubscriptionId $args[1] `
                -Verbose
        } `
        -ArgumentList $TenantID, $ITEM `
        -Verbose
}
$Subs = (Get-AzManagementGroup -GroupName prod -Expand).Children.id
foreach($S in $Subs) {     
    $ITEM = $S.split('/')[2]
    Start-Job `
        -Name "RemMGSub$N" `
        -ScriptBlock {
            New-AzManagementGroupSubscription `
                -GroupName $args[0] `
                -SubscriptionId $args[1] `
                -Verbose
        } `
        -ArgumentList $TenantID, $ITEM `
        -Verbose
}
$Subs = (Get-AzManagementGroup -GroupName sandbox -Expand).Children.id
foreach($S in $Subs) {     
    $ITEM = $S.split('/')[2]
    Start-Job `
        -Name "RemMGSub$N" `
        -ScriptBlock {
            New-AzManagementGroupSubscription `
                -GroupName $args[0] `
                -SubscriptionId $args[1] `
                -Verbose
        } `
        -ArgumentList $TenantID, $ITEM `
        -Verbose
}
$Subs = (Get-AzManagementGroup -GroupName uat -Expand).Children.id
foreach($S in $Subs) {     
    $ITEM = $S.split('/')[2]
    Start-Job `
        -Name "RemMGSub$N" `
        -ScriptBlock {
            New-AzManagementGroupSubscription `
                -GroupName $args[0] `
                -SubscriptionId $args[1] `
                -Verbose
        } `
        -ArgumentList $TenantID, $ITEM `
        -Verbose
}


