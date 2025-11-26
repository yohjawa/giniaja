# SharePoint 2016 - Optimized Version Cleanup with CAML Filtering
# Handles large libraries efficiently with CAML queries

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# Configuration
$SiteURL = "http://mysharepointsite.com/sites/test/test1"
$LibraryName = "Construction Daily Report"
$DaysToKeep = 365
$LogFile = "E:\temp\SharePointVersionCleanup_Optimized.log"
$WhatIf = $true
$BatchSize = 500

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    Add-Content -Path $LogFile -Value $logMessage
}

# Helper function to process file versions
function Cleanup-FileVersions {
    param(
        [Microsoft.SharePoint.SPFile]$File,
        [DateTime]$CutoffDate
    )
    
    $fileName = $File.Name
    $versions = $File.Versions
    $versionCount = $versions.Count
    
    Write-Log "Processing - $fileName ($versionCount versions)"
    
    $fileVersionsDeleted = 0
    $fileVersionsKept = 0

    # Use a list to track versions to delete with their original indices
    $versionsToDelete = New-Object System.Collections.Generic.List[object]

    for ($i = 0; $i -lt $versionCount; $i++) {
        $version = $versions[$i]
        if ($version -eq $null) { continue }
        
        $versionLabel = $version.VersionLabel
        $versionDate = $version.Created
        $isLatestVersion = ($i -eq ($versionCount - 1))
        
        if ($isLatestVersion) {
            Write-Log "  KEEP LATEST - v$versionLabel ($versionDate)"
            $fileVersionsKept++
            $script:totalVersionsKept++
        }
        else {
            if ($versionDate -lt $CutoffDate) {
                # Store version info with original index
                $versionsToDelete.Add(@{
                    Version = $version
                    Label = $versionLabel
                    Date = $versionDate
                    OriginalIndex = $i
                })
            }
            else {
                Write-Log "  KEEP - v$versionLabel ($versionDate)"
                $fileVersionsKept++
                $script:totalVersionsKept++
            }
        }
    }

    # Second pass: delete versions from highest index to lowest
    # This prevents index shifting issues during deletion
    $versionsToDelete = $versionsToDelete | Sort-Object OriginalIndex -Descending

    foreach ($versionInfo in $versionsToDelete) {
        if ($script:WhatIf) {
            Write-Log "  WOULD DELETE - v$($versionInfo.Label) ($($versionInfo.Date))"
            $fileVersionsDeleted++
            $script:totalVersionsDeleted++
        }
        else {
            try {
                Write-Log "  DELETING - v$($versionInfo.Label) ($($versionInfo.Date))"
                
                # Double-check that the version still exists before deleting
                $currentVersions = $File.Versions
                $versionStillExists = $false
                
                foreach ($v in $currentVersions) {
                    if ($v.VersionLabel -eq $versionInfo.Label -and $v.Created -eq $versionInfo.Date) {
                        $versionStillExists = $true
                        break
                    }
                }
                
                if ($versionStillExists) {
                    $versionInfo.Version.Delete()
                    $fileVersionsDeleted++
                    $script:totalVersionsDeleted++
                    Write-Log "  SUCCESS - v$($versionInfo.Label) deleted"
                }
                else {
                    Write-Log "  WARNING - v$($versionInfo.Label) no longer exists, skipping"
                }
            }
            catch {
                Write-Log "  ERROR deleting v$($versionInfo.Label) - $($_.Exception.Message)"
                $script:errorCount++
                
                # If it's an index out of range error, skip and continue
                if ($_.Exception.Message -like "*out of the range*") {
                    Write-Log "  SKIPPING - Version may have been already deleted"
                }
            }
        }
    }
    
    Write-Log "  $fileName - Deleted $fileVersionsDeleted, Kept $fileVersionsKept"
}

try {
    Write-Log "=== Version Cleanup with Safe Deletion Started ==="
    
    $Web = Get-SPWeb $SiteURL
    $Library = $Web.Lists[$LibraryName]
    
    if ($Library -eq $null) { throw "Library '$LibraryName' not found!" }
    if (-not $Library.EnableVersioning) {
        Write-Log "Versioning not enabled. Exiting."
        exit
    }

    $CutoffDate = (Get-Date).AddDays(-$DaysToKeep)
    Write-Log "Processing library: $($Library.Title) ($($Library.ItemCount) items)"
    Write-Log "Cutoff Date: $CutoffDate"

    $totalFilesProcessed = 0
    $totalVersionsDeleted = 0
    $totalVersionsKept = 0
    $errorCount = 0
    $position = $null

    # Process in batches using ListItemCollectionPosition
    do {
        $Query = New-Object Microsoft.SharePoint.SPQuery
        $Query.ViewAttributes = "Scope='Recursive'"
        $Query.RowLimit = $BatchSize
        
        if ($position -ne $null) {
            $Query.ListItemCollectionPosition = $position
        }

        $Items = $Library.GetItems($Query)
        $position = $Items.ListItemCollectionPosition
        
        Write-Log "Processing batch of $($Items.Count) items..."

        foreach ($Item in $Items) {
            try {
                if ($Item.File -ne $null -and $Item.File.Versions.Count -gt 0) {
                    Cleanup-FileVersions -File $Item.File -CutoffDate $CutoffDate
                    $totalFilesProcessed++
                }
            }
            catch {
                $errorCount++
                Write-Log "ERROR: $($Item.File.Name) - $($_.Exception.Message)"
            }
        }

        # Memory management - dispose and recreate web object periodically for large libraries
        if ($totalFilesProcessed % 2000 -eq 0 -and $position -ne $null) {
            Write-Log "Memory cleanup - recreating web connection..."
            $Web.Dispose()
            $Web = Get-SPWeb $SiteURL
            $Library = $Web.Lists[$LibraryName]
        }

    } while ($position -ne $null)

    Write-Log "=== Summary ==="
    Write-Log "Total files with versions: $totalFilesProcessed"
    Write-Log "Versions deleted: $totalVersionsDeleted"
    Write-Log "Versions kept: $totalVersionsKept"
    Write-Log "Errors: $errorCount"

}
catch {
    Write-Log "FATAL ERROR: $($_.Exception.Message)"
}
finally {
    if ($Web -ne $null) { $Web.Dispose() }
    Write-Log "=== Script Completed ==="
}

