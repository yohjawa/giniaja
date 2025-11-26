Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$siteUrl = "http://mysharepointsite.com"
$docPath = "/test/testaja.docx"
$pdfPath = "/test/Testlagi.pdf"

$site = Get-SPSite $siteUrl
$job = New-Object Microsoft.Office.Word.Server.Conversions.ConversionJob("Word Automation Services")
$job.UserToken = $site.RootWeb.CurrentUser.UserToken
$job.Settings.OutputFormat = "PDF"
$job.AddFile($siteUrl + $docPath, $siteUrl + $pdfPath)
$job.Start()

Write-Host "Check library in 5-15 minutes for PDF. If missing, check ULS logs."