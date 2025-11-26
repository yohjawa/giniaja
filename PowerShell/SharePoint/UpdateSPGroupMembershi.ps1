# Load SharePoint Server Object Model
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# Parameters
$SiteUrl = "https://mysharepointsite.com/sites/test1"
$CSVPath = "C:\temp\spgroupmembers.csv"

# Connect to the site collection
$site = Get-SPSite $SiteUrl
$web = $site.OpenWeb()

# Import CSV
$csvData = Import-Csv -Path $CSVPath

# Get unique group names
# $groups = $csvData.GroupName | Sort-Object -Unique
$groupName = "Zona 10 PKB Visitors"
$group = $web.SiteGroups[$groupName]

if ($group) {
    Write-Host "Processing group: $GroupName"
    
    # Remove all current members from the group
    foreach ($user in $group.Users) {
        Write-Host " - Removing: $($user.LoginName)"
        $group.RemoveUser($user)
    }
    $web.Update()

    # Add new users from CSV
    foreach ($userEntry in $csvData) {
        $email = $userEntry.Email
        $user = $web.EnsureUser($email)
        Write-Host " + Adding: $email"
        $group.AddUser($user)
    }
    $web.Update()

    Write-Host "Group '$GroupName' updated successfully.`n"
} else {
    Write-Host "Group '$GroupName' not found. Skipping.`n"
}

Write-Host "All done!"

<#
foreach ($groupName in $groups) {
    Write-Host "Processing group: $groupName"

    # Get the SharePoint group
    $group = $web.SiteGroups[$groupName]
    
    if ($group) {
        # Remove all current members
        foreach ($user in $group.Users) {
            Write-Host " - Removing: $($user.LoginName)"
            $group.RemoveUser($user)
        }
        $web.Update()

        # Add new users from CSV
        $usersToAdd = $csvData | Where-Object { $_.GroupName -eq $groupName }

        foreach ($userEntry in $usersToAdd) {
            Write-Host " + Adding: $($userEntry.LoginName)"
            $web.SiteUsers.Add("i:0#.f|membership|$($userEntry.LoginName)")
        }

        $web.Update()
        Write-Host "Group '$groupName' updated successfully.`n"
    } else {
        Write-Host "Group '$groupName' not found. Skipping.`n"
    }
}

Write-Host "All groups processed."
#>
