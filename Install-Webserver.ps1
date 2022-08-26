# Title : Installing Windows Feature - IIS (WebServer) using PowerShell
#                                                        
$IsInstalled = ((Get-WindowsFeature -Name Web-Server).installed)
if ($isinstalled -eq $false){
    Install-WindowsFeature Web-Server -IncludeManagementTools -IncludeAllSubFeature -Confirm:$false
    Write-Output "Installation Complete"
}
else{
    Write-output "IIS Server (WebServer) is already installed"
}
Start-Sleep -Seconds 60
Import-Module "WebAdministration"
Remove-IISSite -Name "Default Web Site" -confirm:$false
Remove-WebAppPool -Name "DefaultAppPool" -confirm:$false
Remove-WebAppPool -Name "DemoAppPool" -confirm:$false
Remove-Item IIS:\Sites\DemoSite -Recurse -Force -confirm:$false
Remove-Item C:\DemoSite -Recurse -Force -confirm:$false
New-Item C:\DemoSite -type Directory
Copy-Item -Path "C:\sc\*" -Destination "C:\DemoSite" -Recurse
New-Item IIS:\AppPools\DemoAppPool
New-Item IIS:\Sites\DemoSite -physicalPath C:\DemoSite -bindings @{protocol="http";bindingInformation=":80:"}
Set-ItemProperty IIS:\Sites\DemoSite -name applicationPool -value DemoAppPool
