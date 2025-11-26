$siteUrl = "http://mysharepointsite.com"
$docPath = "/Test/test.docx"
$pdfPath = "/Test/Testoutputtoday.pdf"

$site = Get-SPSite $siteUrl
$job = New-Object Microsoft.Office.Word.Server.Conversions.ConversionJob("Word Automation Services")
$job.UserToken = $site.RootWeb.CurrentUser.UserToken
$job.Settings.OutputFormat = "PDF"
$job.AddFile($siteUrl + $docPath, $siteUrl + $pdfPath)
$job.Start() 