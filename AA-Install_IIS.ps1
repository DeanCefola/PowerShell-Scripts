install-windowsfeature -name Web-Server -IncludeManagementTools
Set-Location -Path c:\inetpub\wwwroot
Add-Content iisstart.htm "<H1><center>WELCOME to my Web Server $env:COMPUTERNAME, Azure Academy Rocks!</center></H1>"
Invoke-command -ScriptBlock{iisreset}