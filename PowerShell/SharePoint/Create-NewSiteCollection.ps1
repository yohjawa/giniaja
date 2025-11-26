## Create new content database if not using existing database 
$ContentDatabase = "ContentDB"
$WebApplication = "http://mysharepointsite.com"
$DatabaseServer = "DBSERVER\DBINSTANCE"
New-SPContentDatabase -Name $ContentDatabase -WebApplication $WebApplication -DatabaseServer $DatabaseServer

$SiteCollURL = "http://mysharepointsite.com/sites/test1"
$SiteName = "Site Name"
$SiteOwner = "DOMAIN\UserName"
$SiteTemplate = "STS#0"
$SiteDescription = "Site Description"

#Create new Site Collection
New-SPSite -URL $SiteCollURL -OwnerAlias $SiteOwner  -Template $SiteTemplate -Name $SiteName -ContentDatabase $ContentDatabase -Description $SiteDescription