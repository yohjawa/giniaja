Add-PSSnapin Microsoft.SharePoint.PowerShell

New-SPContentDatabase -Name NewContentDB -DatabaseServer DBSERVER\DBINSTANCE -WebApplication "http://mysharepointsite.com"

Move-SPSite "http://mysharepointsite.com/sites/test1" -DestinationDatabase "NewContentDB"
Move-SPSite "http://mysharepointsite.com/sites/test2" -DestinationDatabase "NewContentDB"
Move-SPSite "http://mysharepointsite.com/sites/test3" -DestinationDatabase "NewContentDB"
Move-SPSite "http://mysharepointsite.com/sites/test4" -DestinationDatabase "NewContentDB"
Move-SPSite "http://mysharepointsite.com/sites/test5" -DestinationDatabase "NewContentDB"
