# Parameters
$siteUrl = "http://mysharepointsite.com/sites/test"
$libraryRelativeUrl = "/sites/test/Shared Documents"  # Adjust to your library
$filePath = "C:\temp\test.zip"
$targetFileName = "test.zip"  # Can be different from source

# Read file content
$fileContent = [System.IO.File]::ReadAllBytes($filePath)

# Construct REST API URL
$restUrl = "http://mysharepointsite.com.com/sites/test/_api/web/GetFolderByServerRelativeUrl('$libraryRelativeUrl')/Files/add(url='$targetFileName',overwrite=true)"

# Execute the request with Windows Authentication
try {
    $headers = @{
        "Accept" = "application/json;odata=verbose"
    }
    
    # Get form digest for SharePoint 2016
    $contextInfoUrl = "$siteUrl/_api/contextinfo"
    $contextInfo = Invoke-RestMethod -Uri $contextInfoUrl -Method Post -UseDefaultCredentials -Headers $headers
    $formDigest = $contextInfo.d.GetContextWebInformation.FormDigestValue
    
    $headers.Add("X-RequestDigest", $formDigest)
    
    $result = Invoke-RestMethod -Uri $restUrl -Method Post -UseDefaultCredentials -Headers $headers -Body $fileContent -ContentType "application/octet-stream"
    
    Write-Host "File uploaded successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error uploading file: $_" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
}