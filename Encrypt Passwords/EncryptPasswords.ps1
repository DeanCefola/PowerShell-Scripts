
# Path to the script to be created:  
#$path = "O:\OneDrive\Powershell\Secure Password"
$path = "C:\Users\deacef\OneDrive\Powershell\Secure Password"
$TemplatePath = "$Path\template.ps1"

if ((Test-Path -LiteralPath $Path) -ne $True) {
        Write-Host `
            -ForegroundColor Cyan `
            -BackgroundColor Black `
            "Creating Temp Folder for Import"
        New-Item -ItemType Directory 'C:\temp'
        }        
  
# Create empty template script:  
New-Item -ItemType File $TemplatePath -Force -ErrorAction SilentlyContinue  
  
$pwd = Read-Host 'Enter Password' -AsSecureString  
$user = Read-Host 'Enter Username'  
$key = 1..32 | ForEach-Object { Get-Random -Maximum 256 }  
$pwdencrypted = $pwd | ConvertFrom-SecureString -Key $key  
  
$private:ofs = ' '  
('$password = "{0}"' -f $pwdencrypted) | Out-File $TemplatePath   
('$key = "{0}"' -f "$key") | Out-File $TemplatePath  -Append  
  
'$passwordSecure = ConvertTo-SecureString -String $password -Key ([Byte[]]$key.Split(" "))' |   
    Out-File $TemplatePath  -Append  
('$cred = New-Object system.Management.Automation.PSCredential("{0}", $passwordSecure)' -f $user) |  
    Out-File $TemplatePath  -Append  
'$cred' | Out-File $TemplatePath  -Append  
  
ise $TemplatePath 


#----------------Decrypt Secure Password----------------#
<#


        $BSTR = `
             [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
        $passwordSecure = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR) 
        $passwordSecure


#>

