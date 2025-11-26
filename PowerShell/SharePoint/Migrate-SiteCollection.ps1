$sSite = "https://mysharepointsite.com/sites/test1"
$dSite = "http://mysharepointsite.com/sites/test/test2"
$webApp = "http://mysharepointsite.com"
$bPath = "\\sf01\backup\path\sitebackup.bak"

$DbServer = "DBSERVER\DBINSTANCE"
$ContentDb = "ContentDB"

#$SiteCollURL = $dSite
#$SiteName = "SiteName"
#$SiteOwner = "DOMAIN\username"
#$SiteTemplate = "STS#0"
#$SiteDescription = "Site Description"

## Create new Content Database


#New-SPSite -URL $SiteCollURL -OwnerAlias $SiteOwner -Template $SiteTemplate -Name $SiteName -ContentDatabase $ContentDatabase -Description $SiteDescription

Backup-SPSite $sSite -Path $bPath
New-SPContentDatabase -Name $ContentDb -DatabaseServer $DbServer -WebApplication $webApp
Restore-SPSite $dSite -Path $bPath -DatabaseServer $DbServer -DatabaseName $ContentDb -Force

##
## Remove-SPContentDatabase WSS_Content -Confirm:$false -Force
##


#### Migrate site collection with removed contents/items

$srcSite = "http://mysharepointsite.com/sites/test1"
$dstSite = "http://mysharepointsite2.com/sites/test2"
$dbServer = "DBSERVER\DBINSTANCE"
$contentDB = "ContentDB"
$backupPath = "\\sf01\backup\path\sitebackup.bak"
Backup-SPSite -Identity $srcSite -Path $backupPath

## Restore to staging environment
Restore-SPSite $dstSite -Path $backupPath -DatabaseServer $dbServer -DatabaseName $contentDB -Force


## Cleanup contents on staging environment
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# Set your site collection URL
$siteUrl = $dstSite

# Libraries you do NOT want to delete (system/default libraries)
$excludedLibraries = @("Style Library", "Site Assets", "Site Pages", "Form Templates","Content and Structure Reports","Pages","Reusable Content")

$site = Get-SPSite $siteUrl

foreach ($web in $site.AllWebs) {
    Write-Host "Processing site: $($web.Url)" -ForegroundColor Cyan

    $lists = @($web.Lists)
    foreach ($list in $lists) {
        if (!$list.Hidden -and !$list.IsApplicationList -and !$excludedLibraries.Contains($list.Title)) {
            Write-Host "  -> Deleting items from list/library: $($list.Title)" -ForegroundColor Yellow

            $items = @($list.Items)  
            foreach ($item in $items) {
                try {
                    $item.Delete()
                }
                catch {
                    Write-Host "!! Error deleting item: $_" -ForegroundColor DarkRed
                }
            }
        }
    }
    $web.Dispose()
}

$site.Dispose()

Write-Host "`nAll eligible lists/libraries and their items have been removed." -ForegroundColor Green
