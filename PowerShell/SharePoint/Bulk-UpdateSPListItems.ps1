Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# Configuration
$SiteUrl = "http://mysharepointsite.com"
$LibraryName = "Test"
$StatusFieldInternalName = "Approval_x0020_Status"
$DraftValue = "Draft"
$ApprovedValue = "Approved"

try {
    # Get SharePoint objects
    $Web = Get-SPWeb $SiteUrl
    $List = $Web.Lists[$LibraryName]
    $StatusField = $List.Fields[$StatusFieldInternalName]

    # Get all PDF files with Draft status
    $PDFItems = $List.Items | Where-Object {
        ($_["FileLeafRef"] -like "*.pdf") -and
        ($_[$StatusFieldInternalName] -eq $DraftValue)
    }

    Write-Host "Found $($PDFItems.Count) PDF document(s) with Draft status"

    foreach ($PDFItem in $PDFItems) {
        # Get base name without extension
        $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($PDFItem.Name)
        
        # Find matching DOCX document
        $DocxItem = $List.Items | Where-Object {
            ($_["FileLeafRef"] -like "*.docx") -and
            ($_["FileLeafRef"] -like "$BaseName*") -and
            ([System.IO.Path]::GetFileNameWithoutExtension($_["FileLeafRef"]) -eq $BaseName)
        } | Select-Object -First 1

        #$PDFItem[$StatusFieldInternalName]
        #$DocxItem[$StatusFieldInternalName]
        # Update PDF document
        $PDFItem[$StatusFieldInternalName] = $ApprovedValue
        $PDFItem.Update()
        Write-Host "Updated PDF: $($PDFItem.Name)"
#
        ## Update matching DOCX if found
        if ($DocxItem) {
            $DocxItem[$StatusFieldInternalName] = $ApprovedValue
            $DocxItem.Update()
            Write-Host "Updated DOCX: $($DocxItem.Name)"
        }
    }
    
    Write-Host "Operation completed successfully"
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if ($Web) { $Web.Dispose() }
}