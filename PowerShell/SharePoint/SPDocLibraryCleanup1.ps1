Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# Configuration
$SiteURL = "http://mysharepointsite.com/sites/test/test1"
$LibraryName = "Construction Daily Report"
$DaysToKeep = 365
$LogFile = "E:\temp\SharePointVersionCleanup_Advanced.log"
$WhatIf = $true # Set to $false to actually delete versions

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

try {
    Write-Log "=== SharePoint Version History Cleanup Started ==="
    Write-Log "Site: $SiteURL"
    Write-Log "Library: $LibraryName"
    Write-Log "Removing versions older than $DaysToKeep days (keeping latest version)"
    Write-Log "Mode: $(if ($WhatIf) {'DRY RUN - No versions will be deleted'} else {'LIVE - Versions will be deleted'})"
    
    $Web = Get-SPWeb $SiteURL -ErrorAction Stop
    Write-Log "Successfully connected to site: $($Web.Url)"

    $Library = $Web.Lists[$LibraryName]
        if ($Library -eq $null) {
        throw "Document Library '$LibraryName' not found!"
    }
    Write-Log "Found library: $($Library.Title)"
    Write-Log "Library versioning enabled: $($Library.EnableVersioning)"

    if (-not $Library.EnableVersioning) {
        Write-Log "WARNING: Versioning is not enabled for this library. No versions to clean up."
        exit
    }

    # Calculate the cutoff date
    $CutoffDate = (Get-Date).AddDays(-$DaysToKeep)
    Write-Log "Cutoff Date: $CutoffDate (versions created before this date will be deleted)" 

    # Get all items in batches
    $Query = New-Object Microsoft.SharePoint.SPQuery
    $Query.ViewAttributes = "Scope='Recursive'"
    $Query.RowLimit = 2000
    
    $Items = $Library.GetItems($Query)
    Write-Log "Found $($Items.Count) items in the library"

    $totalFilesProcessed = 0
    $totalVersionsDeleted = 0
    $totalVersionsKept = 0
    $errorCount = 0

    foreach ($Item in $Items) {
        try {
            if ($Item.File -ne $null) {
                $fileName = $Item.File.Name
                $versions = $Item.File.Versions
                $versionCount = $versions.Count
                
                Write-Log "Processing - $fileName ($versionCount versions total)"
                
                if ($versionCount -gt 0) {
                    $fileVersionsDeleted = 0
                    $fileVersionsKept = 0
                    
                    # CORRECTED: Process from oldest (index 0) to newest (highest index)
                    # The versions collection is ordered from oldest to newest
                    for ($i = 0; $i -lt $versionCount; $i++) {
                        $version = $versions[$i]
                        
                        if ($version -ne $null) {
                            $versionLabel = $version.VersionLabel
                            $versionDate = $version.Created
                            
                            # Check if this is the latest version (highest index)
                            $isLatestVersion = ($i -eq ($versionCount - 1))
                            
                            if ($isLatestVersion) {
                                # Always keep the latest version
                                Write-Log "  KEEPING LATEST - v$versionLabel ($versionDate)"
                                $fileVersionsKept++
                                $totalVersionsKept++
                            }
                            else {
                                # Delete versions older than cutoff date (only non-latest versions)
                                if ($versionDate -lt $CutoffDate) {
                                    if ($WhatIf) {
                                        Write-Log "  WOULD DELETE - v$versionLabel ($versionDate)"
                                    }
                                    else {
                                        Write-Log "  DELETING - v$versionLabel ($versionDate)"
                                        $version.Delete()
                                    }
                                    $fileVersionsDeleted++
                                    $totalVersionsDeleted++
                                }
                                else {
                                    Write-Log "  KEEPING - v$versionLabel ($versionDate)"
                                    $fileVersionsKept++
                                    $totalVersionsKept++
                                }
                            }
                        }
                    }
                    
                    Write-Log "  $fileName - Deleted $fileVersionsDeleted versions, kept $fileVersionsKept versions"
                }
                else {
                    Write-Log "  $fileName - No versions found"
                }
                
                $totalFilesProcessed++
            }
        }
        catch {
            $errorCount++
            Write-Log "ERROR processing $fileName - $($_.Exception.Message)"
        }

        # Progress update every 10 items
        if ($totalFilesProcessed % 10 -eq 0) {
            Write-Log "Progress - Processed $totalFilesProcessed files, $totalVersionsDeleted versions marked for deletion"
        }
    }

    Write-Log "=== Summary ==="
    Write-Log "Total files processed: $totalFilesProcessed"
    Write-Log "Total versions deleted: $totalVersionsDeleted"
    Write-Log "Total versions kept: $totalVersionsKept"
    Write-Log "Errors: $errorCount"
    
    if ($WhatIf) {
        Write-Log "NOTE: This was a dry run. No versions were actually deleted."
        Write-Log "Set `$WhatIf = `$false to perform actual version deletion."
    }

     # Dispose of the web object
    $Web.Dispose()

}
catch {
    Write-Log "FATAL ERROR: $($_.Exception.Message)"
    Write-Log "Stack Trace: $($_.Exception.StackTrace)"
}
finally {
    if ($Web -ne $null) { $Web.Dispose() }
    Write-Log "=== Script Completed ==="
}