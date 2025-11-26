$Admin = New-Object Microsoft.SharePoint.Administration.SPSiteAdministration('http://mysharepointsite.com/');
$Admin.ClearMaintenanceMode();

$site = Get-SPSite -Identity "http://mysharepointsite.com/" | Select-Object *
$site.MaintanceMode