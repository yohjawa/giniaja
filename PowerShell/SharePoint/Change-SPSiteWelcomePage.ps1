$site = Get-SPSite "http://yourserver/sites/yoursite"
$web = $site.RootWeb
  (or $web = $site.OpenWeb("yoursubsite")
$folder = $web.RootFolder
$folder.WelcomePage = "SitePages/home.aspx"
  (or  $folder.WelcomePage = "default.aspx")
  (or  $folder.WelcomePage = "Shared%20Documents/mycustomwebpartpage.aspx")
$folder.update()
$web.Dispose()
$site.Dispose()