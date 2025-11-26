# Import required modules
Add-Type -Path "C:\DBA\Test\Libraries\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\DBA\Test\Libraries\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\DBA\Test\Libraries\Microsoft.SharePoint.Client.UserProfiles.dll"

# Configuration variables
$siteUrl = "http://mysharepointsite.com/sites/test/test1" # Replace with your site URL
$listName = "DB Infra" # Replace with your list name
$excelPath = "C:\temp\test\excelfile.xlsx" # Replace with your Excel file path
$username = "DOMAIN\username" # Replace with your username
$password = Read-Host -Prompt "Enter password" -AsSecureString

# Function to connect to SharePoint
$context = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
$context.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $password)


# Load Excel data
$excel = New-Object -ComObject Excel.Application
$workbook = $excel.Workbooks.Open($excelPath)
$worksheet = $workbook.Sheets.Item(1)
$range = $worksheet.UsedRange
$rows = $range.Rows.Count
$columns = $range.Columns.Count

# Get headers
$headers = @()
for ($col = 1; $col -le $columns; $col++) {
    $headers += $worksheet.Cells.Item(1, $col).Text
}

# Connect to SharePoint
$ctx = Get-SPContext -url $siteUrl -cred $credentials
$list = $ctx.Web.Lists.GetByTitle($listName)
$ctx.Load($list)
$ctx.Load($list.Fields)
$ctx.ExecuteQuery()

# Process each row (starting from row 2 to skip headers)
for ($row = 2; $row -le $rows; $row++) {
    # Get the ID or unique identifier from Excel
    $itemId = $worksheet.Cells.Item($row, 1).Text # Assuming ID is in first column
    
    try {
        $item = $list.GetItemById($itemId)
        $ctx.Load($item)
        $ctx.ExecuteQuery()
        
        # Update fields (skip ID column)
        for ($col = 2; $col -le $columns; $col++) {
            $fieldName = $headers[$col-1]
            $fieldValue = $worksheet.Cells.Item($row, $col).Text
            
            # Only update if the field exists in the list
            $field = $list.Fields | Where-Object { $_.InternalName -eq $fieldName }
            if ($field) {
                $item[$fieldName] = $fieldValue
            }
        }
        
        $item.Update()
        $ctx.ExecuteQuery()
        Write-Host "Updated item ID: $itemId"
    }
    catch {
        Write-Warning "Error updating item ID $itemId : $_"
    }
}

# Clean up
$workbook.Close($false)
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
Remove-Variable excel

Write-Host "Update process completed!"