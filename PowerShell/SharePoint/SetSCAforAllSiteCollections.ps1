Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# Replace with the desired user account (DOMAIN\Username)
$adminUser = "DOMAIN\SecurityGrouporUserName"
$adminUser = (New-SPClaimsPrincipal -Identity $adminUser -IdentityType WindowsSamAccountName).ToEncodedString()
$webApps = "http://mysharepointsite.com"

# Get all site collections
$siteCollections = Get-SPSite  -WebApplication $webApps -Limit All

foreach ($site in $siteCollections) {
    Write-Host "Processing: $($site.Url)" -ForegroundColor Cyan

    try {
        $web = $site.RootWeb
        $user = $web.EnsureUser($adminUser)
        $user.IsSiteAdmin = $true
        $user.Update()

        Write-Host "$adminAccount set as Site Collection Admin on $($site.Url)" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed on $($site.Url): $_"
    }
    finally {
        $web.Dispose()
    }
}

# Clean up
$siteCollections | ForEach-Object { $_.Dispose() }

Write-Host "Done!" -ForegroundColor Yellow