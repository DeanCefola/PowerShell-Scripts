<#Author   : Dean Cefola
# Creation Date: 8-26-2019
# Usage      : Create OU and AD Users Accounts

#**************************************************************************
# Date                     Version      Changes
#------------------------------------------------------------------------
# 8/26/2019                  1.0       Intial Version
#
#
#***************************************************************************
#>


##################################
#    Azure AD Users Variables    #
##################################
$DomainFQDN = (Get-WmiObject -Class win32_computersystem).Domain
$Domain = $DomainFQDN.Split('.') | SELECT -First 1
$DomainSuffix = $DomainFQDN.Split('.') | SELECT -last 1
$DomainSite = (Get-ADDomainController).site
$DomainController = (Get-ADDomainController).Name
$Password = Read-Host -Prompt "Enter Default User Password" -AsSecureString
$OUName = Read-Host -Prompt "Enter Name for AD Organizational Unit"
$UserPath = "OU=$OUName,DC=$DomainName,DC=$DomainSuffix"
Import-Module -Name activedirectory
cd AD:
cd ".\DC=$Domain,DC=$DomainSuffix"


#############################
#    Create OU Structure    #
#############################
 $CreateADOU = @(
    ,@("$OUName",                "DC=$Domain,DC=$DomainSuffix")        
        ,@("_Delegation",            "OU=$OUName,DC=$Domain,DC=$DomainSuffix")
            ,@("Delegation Permissions", "OU=_Delegation,OU=$OUName,DC=$Domain,DC=$DomainSuffix") 
            ,@("Delegation Roles",       "OU=_Delegation,OU=$OUName,DC=$Domain,DC=$DomainSuffix")        
        ,@("_GPO Exceptions",        "OU=$OUName,DC=$Domain,DC=$DomainSuffix")
            ,@("GPO Groups",             "OU=_GPO Exceptions,OU=$OUName,DC=$Domain,DC=$DomainSuffix")
            ,@("GPO Test",               "OU=_GPO Exceptions,OU=$OUName,DC=$Domain,DC=$DomainSuffix")                
        ,@("RemoteApps",             "OU=$OUName,DC=$Domain,DC=$DomainSuffix")        
        ,@("Azure",                  "OU=$OUName,DC=$Domain,DC=$DomainSuffix")
            ,@("Azure Computers",        "OU=Azure,OU=$OUName,DC=$Domain,DC=$DomainSuffix")
            ,@("Azure Groups",           "OU=Azure,OU=$OUName,DC=$Domain,DC=$DomainSuffix")
            ,@("Azure Users",            "OU=Azure,OU=$OUName,DC=$Domain,DC=$DomainSuffix")
)
foreach ($OU in $CreateADOU) {
    $DC = $DomainController
    $OU_Name = $OU[0]
    $OU_Path = $OU[1]    
    New-ADOrganizationalUnit -Server $DC -Name $OU_Name -Path $OU_Path `
        -ProtectedFromAccidentalDeletion 0
}


###############################
#    Create AD Role Groups    #
###############################
$CreateADGroup = @(
    ,@("GPO-Exception-IE-AutoDetect",                "Disable IE Proxy Auto Detect",     "OU=GPO Groups,OU=_GPO Exceptions")
    ,@("GPO-Exception-WelcomeMessage",               "Disable Windows Welcome Message",  "OU=GPO Groups,OU=_GPO Exceptions")
    ,@("PERM-Act-As-Part-of-the-Operating-System",   "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Adjust-memory-quotas-for-a-process",    "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Create-a-token-object",                 "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Deny-Log-on-Through-Terminal-Services", "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Join-to-Domain",                        "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Logon-As-a-Batch-Service",              "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Manage-Groups",                         "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Manage-OU",                             "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Manage-Reset-Passwords",                "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Manage-Users",                          "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Replace-a-Process-Level-Token",         "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Replicate-Directory-Changes",           "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Restore-Files-and-Directories",         "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("PERM-Manage-RDS",                            "PERM - Security Policy",           "OU=Delegation Permissions,OU=_Delegation")
    ,@("REMOTEAPP-BPCClient",                        "Remote Application",               "OU=RemoteApps")
    ,@("REMOTEAPP-IE",                               "Remote Application",               "OU=RemoteApps")
    ,@("REMOTEAPP-MDM-Console",                      "Remote Application",               "OU=RemoteApps")
    ,@("REMOTEAPP-MDM-Data",                         "Remote Application",               "OU=RemoteApps")
    ,@("REMOTEAPP-MDM-Import",                       "Remote Application",               "OU=RemoteApps")
    ,@("REMOTEAPP-MDM-Publisher",                    "Remote Application",               "OU=RemoteApps")
    ,@("REMOTEAPP-MDM-Syndicator",                   "Remote Application",               "OU=RemoteApps")
    ,@("REMOTEAPP-RDP",                              "Remote Application",               "OU=RemoteApps")
    ,@("REMOTEAPP-SAPGui",                           "Remote Application",               "OU=RemoteApps")
    ,@("REMOTEAPP-SQL",                              "Remote Application",               "OU=RemoteApps")
    ,@("ROLE-FIM-Administration-of-AD",              "ROLE - FIM Admin Rights",          "OU=Delegation Roles,OU=_Delegation")
    ,@("ROLE-SAP-Service-SID-Local-Rights",          "ROLE - SAP Service Rights",        "OU=Delegation Roles,OU=_Delegation")
    ,@("ROLE-SAP-SIDadm-Local-Rights",               "ROLE - SAP Module Admin Rights",   "OU=Delegation Roles,OU=_Delegation")
    ,@("ROLE-SCOM-Admins",                           "ROLE - SCOM Administration",       "OU=Delegation Roles,OU=_Delegation")
    ,@("ROLE-SCOM-Operators",                        "ROLE - SCOM Operators",            "OU=Delegation Roles,OU=_Delegation")
    ,@("ROLE-RDS-Admin",                             "ROLE - RDS Administration",        "OU=Delegation Roles,OU=_Delegation")


)        
foreach ($GP in $CreateADGroup) {
    $Root =     ",OU=$OUName,DC=$Domain,DC=$DomainSuffix"                
    $GP_Name =  $GP[0]
    $GP_Label = $GP[1]
    $GP_Path =  $GP[2] + $Root
    
    Write-Host -ForegroundColor Cyan -BackgroundColor Black `
        (" Create New AD Group " + $GP_Name)
    ""
    ""
    New-ADGroup `
        -Name $GP_Name `
        -Description $GP_Label `
        -DisplayName $GP_Name `
        -Path $GP_Path `
        -SamAccountName $GP_Name `
        -GroupScope Global
        ""
        ""
}


###########################################
#    Add Users to AD Permisions Groups    #
###########################################
$PERM_MiscPerms = @(        
    ,@("PERM-Deny-Log-on-Through-Terminal-Services",  "ROLE-SAP-Service-SID-Local-Rights")
    ,@("PERM-Restore-Files-and-Directories",          "ROLE-SAP-Service-SID-Local-Rights") 
    ,@("PERM-Act-As-Part-of-the-Operating-System",    "ROLE-SAP-SIDadm-Local-Rights")
    ,@("PERM-Adjust-memory-quotas-for-a-process",     "ROLE-SAP-SIDadm-Local-Rights")
    ,@("PERM-Replace-a-Process-Level-Token",          "ROLE-SAP-SIDadm-Local-Rights")
    ,@("PERM-Manage-Reset-Passwords",                 "ROLE-FIM-Administration-of-AD")
    ,@("PERM-Manage-Users",                           "ROLE-FIM-Administration-of-AD")
    ,@("PERM-Manage-Groups",                          "ROLE-FIM-Administration-of-AD")
    ,@("PERM-Manage-OU",                              "ROLE-FIM-Administration-of-AD")
    ,@("PERM-Manage-RDS",                             "ROLE-RDS-Admin")
)
Foreach ($PERM_Misc in $PERM_MiscPerms) {
    $MemberName = $PERM_Misc[0]
    $GroupName  = $PERM_Misc[1]
        
    Write-Host -ForegroundColor Cyan -BackgroundColor Black `
        ("Add AD User " + $MemberName + " to Group " + $GroupName);     
    ""
    ""
    Add-ADGroupMember `
        -Identity $GroupName `
        -Members $MemberName
}


#################################
#    Create AD User Accounts    #
#################################
 $CreateADUsers = @(     
 #Marvel Universe                           
	,@("AdamWarlock",     "AdamWarlock@$DomainFQDN",    "OU=Azure Users,OU=Azure")
	,@("BlackWidow",      "BlackWidow@$DomainFQDN",     "OU=Azure Users,OU=Azure") 
	,@("CaptainAmerica",  "CaptainAmerica@$DomainFQDN", "OU=Azure Users,OU=Azure")
	,@("DrStrange",       "DrStrange@$DomainFQDN",      "OU=Azure Users,OU=Azure")
	,@("Gamora",          "Gamora@$DomainFQDN",         "OU=Azure Users,OU=Azure")
	,@("Hulk",            "Hulk@$DomainFQDN",           "OU=Azure Users,OU=Azure")             
	,@("MariaHill",       "MariaHill@$DomainFQDN",      "OU=Azure Users,OU=Azure")
	,@("NickFury",        "NickFury@$DomainFQDN",       "OU=Azure Users,OU=Azure")
	,@("Nova",            "Nova@$DomainFQDN",           "OU=Azure Users,OU=Azure")
	,@("Rocket",          "Rocket@$DomainFQDN",         "OU=Azure Users,OU=Azure")
    ,@("Spiderman",       "Spiderman@$DomainFQDN",      "OU=Azure Users,OU=Azure")
    ,@("StarLord",        "StarLord@$DomainFQDN",       "OU=Azure Users,OU=Azure")
    ,@("Thor",            "Thor@$DomainFQDN",           "OU=Azure Users,OU=Azure")
#DC Universe      
    ,@("Batman",          "Batman@$DomainFQDN",         "OU=Azure Users,OU=Azure")
    ,@("CatWoman",        "CatWoman@$DomainFQDN",       "OU=Azure Users,OU=Azure")
    ,@("Superman",        "Superman@$DomainFQDN",       "OU=Azure Users,OU=Azure")
    ,@("BlackAdam",       "BlackAdam@$DomainFQDN",      "OU=Azure Users,OU=Azure")
	,@("Joker",           "Joker@$DomainFQDN",          "OU=Azure Users,OU=Azure")
	,@("LexLuthor",       "LexLuthor@$DomainFQDN",      "OU=Azure Users,OU=Azure")
	,@("Robin",           "Robin@$DomainFQDN",          "OU=Azure Users,OU=Azure")
    ,@("WonderWoman",     "WonderWoman@$DomainFQDN",    "OU=Azure Users,OU=Azure")
) 
$SecurePassword = $Password
foreach ($ADUser in $CreateADUsers) {
    $Root =     ",OU=$OUName,DC=$Domain,DC=$DomainSuffix"                
    $User_Name =  $ADUser[0]
    $User_Email = $ADUser[1]
    $User_Path =  $ADUser[2] + $Root
    Write-Host  -ForegroundColor Cyan -BackgroundColor Black  ("Provisioning AD User " + $User_Name); 
    ""
    ""               
    New-ADUser `
        -AccountPassword $SecurePassword `
        -AuthType Negotiate `
        -Company $DomainName `
        -Department "AD Training" `
        -DisplayName $User_Name `
        -Description "AD User" `
        -Enabled 1 `
        -Name $User_Name `
        -Organization "AD Training" `
        -Path $User_Path `
        -PasswordNeverExpires 1 `
        -EmailAddress $User_Email
}


cd c:\

