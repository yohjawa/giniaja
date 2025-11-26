Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# Input Variables
$SiteURL="http://mysharepointsite.com/"
$grpFile = Import-Csv "D:\Tmp\SPGroups.csv"

$web = Get-SPWeb $siteUrl

ForEach ($grp in $grpFile) {
    $oldGroupName = $grp.OldGroupName
    $newGroupName = $grp.NewGroupName

    $group = $web.SiteGroups[$oldGroupName]
    $group.Name = $newGroupName
    $group.Update()
}

try {
    # Get the site object
    $web = Get-SPWeb $siteUrl

    # Get the existing group
    $group = $web.SiteGroups[$oldGroupName]

    if ($group -ne $null) {
        Write-Host "Renaming group '$oldGroupName' to '$newGroupName'..." -ForegroundColor Cyan

        # Rename the group
        $group.Name = $newGroupName
        $group.Update()

        Write-Host "Group renamed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Group '$oldGroupName' not found." -ForegroundColor Red
    }

    # Dispose of the web object
    $web.Dispose()
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
