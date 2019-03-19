<#Author       : Dean Cefola
# Creation Date: 10-15-2017
# Usage        : Create Custom RBAC Role

#************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 10/15/2017                     1.0        Intial Version
#
#************************************************************************
#
#>

####################
#    Input Array   #
####################
$role = Get-AzureRmRoleDefinition -Name "Owner"


#################################
#    Create Custom RBAC Role    #
#################################
$role.Id = $null
$role.Name = "Deletion Manager"
$role.Description = "Can Delete Resource Groups."
$role.Actions.RemoveRange(0,$role.Actions.Count)
$role.Actions.Add("Microsoft.Resources/subscriptions/resourceGroups/delete")        
$role.AssignableScopes.Clear()
$role.AssignableScopes.Add("/subscriptions/3a8206a1-e9f3-44a2-84f0-e532b9862258")


###########################
#    Apply Custom Role    #
###########################
New-AzureRmRoleDefinition -Role $role


