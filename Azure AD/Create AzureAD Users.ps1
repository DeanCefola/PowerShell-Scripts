<#Author       : Dean Cefola
# Creation Date: 08-01-2019
# Usage        : Create Azure AD Users

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 08/01/2019                     1.0        Intial Version
#
#
#*********************************************************************************
#
#>


##################################
#    Azure AD Users Variables    #
##################################
$DomainName = 'MSAzureAcademy'
$DomainSuffix = 'com'
$FQDN = "$DomainName.$DomainSuffix"
$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = Read-Host -Prompt "Enter Default Password" -AsSecureString
$PasswordProfile.EnforceChangePasswordPolicy = $false
$PasswordProfile.ForceChangePasswordNextLogin = $false


###############################
#    Create Azure AD Users    #
###############################
 $AzureADUsersList = @(                                 
	,@("AdamWarlock",     "AdamWarlock@$FQDN")
	,@("Batman",          "Batman@$FQDN") 
	,@("BlackWidow",      "BlackWidow@$FQDN") 
	,@("CaptainAmerica",  "CaptainAmerica@$FQDN") 
	,@("DrStrange",       "DrStrange@$FQDN") 
	,@("Gamora",          "Gamora@$FQDN  ") 
	,@("Hulk",            "Hulk@$FQDN")             
	,@("MariaHill",       "MariaHill@$FQDN") 
	,@("NickFury",        "NickFury@$FQDN") 
	,@("Nova",            "Nova@$FQDN") 
	,@("Rocket",          "Rocket@$FQDN") 
    ,@("Spiderman",       "Spiderman@$FQDN") 
    ,@("StarLord",        "StarLord@$FQDN") 
    ,@("Superman",        "Superman@$FQDN") 
    ,@("Thor",            "Thor@$FQDN") 
    ,@("WonderWoman",     "WonderWoman@$FQDN") 
) 
ForEach($RM in $AzureADUsersList) {  
    $RM_Name =  $Prefix + $RM[0]
    $RM_Email = $RM[1]
     New-AzureADUser `
        -DisplayName $RM_Name `
        -PasswordProfile $PasswordProfile `
        -UserPrincipalName $RM_Email `
        -AccountEnabled $true `
        -MailNickName $RM_Name `
        -Verbose
}
