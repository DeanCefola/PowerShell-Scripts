[CmdletBinding()]
param (
  $DomainName,
  $DomainArmUserName,
  $DomainArmPass,
  $OUPath,
  $ResourceGroup,
  $ScaleSetObject
)

Write-Host  "Join the VMSS instances to $DomainName ...";

$domainJoinName = "vmssjoindomain"

# JoinOptions.NETSETUP_JOIN_DOMAIN | JoinOptions.NETSETUP_ACCT_CREATE
$Settings = @{
  "Name"    = $DomainName;
  "User"    = $DomainArmUserName;
  "Restart" = "true";
  "Options" = 3;
  "OUPath"  = $OUPath;
}

$ProtectedSettings = @{
  "Password" = $DomainArmPass
}

try {
  Remove-AzVmssExtension `
    -VirtualMachineScaleSet $ScaleSetObject `
    -Name $domainJoinName `
    -ErrorAction SilentlyContinue | Out-Null
}
catch {
  Write-Host "Remove existing domain join extension failed. Ignore if it is VMSS creation.";
  Write-Host "Error info: $_"
}

Add-AzVmssExtension `
  -VirtualMachineScaleSet $ScaleSetObject `
  -Publisher "Microsoft.Compute" `
  -Type "JsonADDomainExtension"  `
  -TypeHandlerVersion 1.3  `
  -Name $domainJoinName `
  -Setting $Settings `
  -ProtectedSetting $ProtectedSettings `
  -AutoUpgradeMinorVersion $true `
  -Verbose | Out-Null
