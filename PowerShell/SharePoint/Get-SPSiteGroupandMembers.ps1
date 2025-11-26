Add-PSSnapin Microsoft.SharePoint.PowerShell

$siteUrl = "http://mysharepointsite.com"
$webApp = Get-SPWeb -Identity $siteUrl

$scGroups = $webApp.SiteGroups | Where-Object{$_.Name -like "Disused*"}

$outputDir = "D:\temp\PETS\"

foreach ($scg in $scGroups.Name) {
    $outputFile = $outputDir + $scg + ".csv"
    $sgMember = Get-SPUser -Web $siteUrl -Group $scg | Select UserLogin,DisplayName
    $sgMember | Export-Csv -Path $outputFile -NoTypeInformation
}

