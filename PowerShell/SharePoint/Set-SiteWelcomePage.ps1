$SiteUrl = "http://mysharepointsite.com/sites/test"
$Site = Get-SPWeb -Identity $SiteUrl
$RootFolder = $Site.RootFolder
$RootFolder.WelcomePage = "Documents/Forms/AllItems.aspx"
$RootFolder.Update()
$Site.Dispose()