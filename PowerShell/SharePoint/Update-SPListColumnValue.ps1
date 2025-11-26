Add-PSSnapin Microsoft.SharePoint.PowerShell

# Connect to the site and list
$web = Get-SPWeb "http://mysharepointsite.com/sites/test"
$list = $web.Lists["Risk Reduction Plan"]

# Loop through each item in the list
foreach ($item in $list.Items) {
    # Example condition: only update items where Status is not "Completed"
    if ($item["Status"] -ne "Draft") {
        $item["Status"] = "Waiting PIC Action"
        $item.Update()
    }
}

# Clean up
$web.Dispose()
