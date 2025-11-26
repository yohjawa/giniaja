## On sharepoint server
Add-PSSnapin Microsoft.Sharepoint.PowerShell
Remove-SPWOPIBinding -All
New-SPWOPIBinding -ServerName myofficeserver1.com –AllowHTTP
Get-SPWOPIZone
Set-SPWOPIZone -zone "internal-http"
(Get-SPSecurityTokenServiceConfig).AllowOAuthOverHttp
$config = (Get-SPSecurityTokenServiceConfig)
$config.AllowOAuthOverHttp = $true
$config.Update()
(Get-SPSecurityTokenServiceConfig).AllowOAuthOverHttp
$Farm = Get-SPFarm
$Farm.Properties.Remove("WopiLegacySoapSupport");
$Farm.Properties.Add("WopiLegacySoapSupport", "http://myofficeserver1.com/x/_vti_bin/ExcelServiceInternal.asmx");
$Farm.Update();


## on OWA server
Import-Module OficeWebApps
Remove-OfficeWebAppsMachine
## restart server
Import-Module OfficeWebApps
New-OfficeWebAppsFarm -InternalUrl "http://myofficeserver1.com" -AllowHTTP -EditingEnabled