param(
    [string]$SiteURL,
    [string]$LibraryName,
    [string]$ConditionListName, 
    [string]$DownloadPath,
    [string]$LogFilePath,
    [string]$DocumentClassification,
    [datetime]$DisposeDate,
    [switch]$DryRun,
    [switch]$DeleteAfterDownload,
    [switch]$Help,
    [switch]$ListFields
)

if (-not $SiteURL) {$SiteURL = "http://mysharepointsite.com"}
if (-not $LibraryName) {$LibraryName = "E-ARCHIVES"}
if (-not $ConditionListName) {$ConditionListName = "VBOX"}
if (-not $DownloadPath) {$DownloadPath = "D:\temp\DL"}
if (-not $LogFilePath) {$LogFilePath = "D:\temp\Logs\SharePointDownloadLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"}
if (-not $DocumentClassification) {$DocumentClassification = "Public"}
if (-not $DisposeDate) {$DisposeDate = "2016-01-01"}

# Display help if requested
if ($Help) {
    Write-Host @"
SharePoint Document Download Script

This script downloads documents from a SharePoint document library based on conditions from another SharePoint list.

Parameters:
  -SiteURL <url>                 : SharePoint site URL (default: http://mysharepointsite.com)
  -LibraryName <name>            : Document library name (default: E-ARCHIVSE)
  -ConditionListName <name>      : List name for filtering conditions (required)
  -DownloadPath <path>           : Local path to download files (default: D:\temp\archives)
  -LogFilePath <path>            : Path for log file (default: D:\temp\SharePointDownloadLog_<timestamp>.log)
  -DocumentClassification <text> : Document classification to filter by (default: Public)
  -DisposeDate <date>            : Dispose date threshold (default: 2016-01-01)
  -DryRun                        : Preview actions without executing
  -DeleteAfterDownload           : Delete folders after successful download
  -ListFields                    : List available fields in the condition list (for troubleshooting)
  -Help                          : Show this help message

Examples:
  .\Download-eArchiveVbox.ps1 -ConditionListName "DocumentMetadata" -DryRun
  .\Download-eArchiveVbox.ps1 -ConditionListName "DocumentMetadata" -ListFields
  .\Download-eArchiveVbox.ps1 -ConditionListName "DocumentMetadata" -DocumentClassification "Restricted" -DisposeDate "2024-06-30" -DeleteAfterDownload

"@
    exit
}

# Check if required parameter is provided
if (-not $ConditionListName) {
    Write-Host "Error: ConditionListName parameter is required. Use -Help for usage information." -ForegroundColor Red
    exit 1
}


# Function to write log messages
Function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    
    # Write to console
    Write-Host -ForegroundColor $Color $logEntry
    
    # Write to log file
    Add-Content -Path $LogFilePath -Value $logEntry
}

# Function to list all fields in a SharePoint list
Function Get-ListFields($SiteURL, $ListName) {
    Try {
        Write-Log "Listing fields for list: $ListName" -Color "Cyan"
        
        $Web = Get-SPWeb $SiteURL
        $List = $Web.Lists[$ListName]
        
        Write-Log "Available fields in list '$ListName':" -Color "Green"
        Write-Log "======================================" -Color "Green"
        
        foreach ($field in $List.Fields) {
            if (-not $field.Hidden) {
                Write-Log "Field: '$($field.Title)' (InternalName: '$($field.InternalName)', Type: '$($field.TypeAsString)')" -Color "Yellow"
            }
        }
        
        return $true
    }
    Catch {
        Write-Log "Error listing fields: $($_.Exception.Message)" -Level "ERROR" -Color "Red"
        return $false
    }
    Finally {
        if ($Web -ne $null) {
            $Web.Dispose()
        }
    }
}

# Function to get items from SharePoint list that match criteria
Function Get-FilteredListItems($SiteURL, $ListName, $DocumentClassification, $DisposeDate)
{
    Try {
        Write-Log "Retrieving filtered items from list: $ListName" -Color "Cyan"
        Write-Log "Filter criteria: Classification='$DocumentClassification', Dispose Date < '$($DisposeDate.ToString("yyyy-MM-dd"))'" -Color "Cyan"
        
        $Web = Get-SPWeb $SiteURL
        $List = $Web.Lists[$ListName]

         # First, try to get the field internal names
        $classificationField = $null
        $disposeDateField = $null

        foreach ($field in $List.Fields) {
            if ($field.Title -eq "IT Classification" -or $field.InternalName -eq "IT Classification") {
                $classificationField = $field
            }
            if ($field.Title -eq "Dispose Date" -or $field.InternalName -eq "Dispose Date") {
                $disposeDateField = $field
            }
        }
        
        if (-not $classificationField -or -not $disposeDateField) {
            Write-Log "Required fields not found. Available fields:" -Level "WARNING" -Color "Yellow"
            foreach ($field in $List.Fields) {
                if (-not $field.Hidden) {
                    Write-Log "  - $($field.Title) ($($field.InternalName), $($field.TypeAsString))" -Color "Yellow"
                }
            }
            throw "Required fields (IT Classification and/or Dispose Date) not found in the list. Use -ListFields parameter to see available fields."
        }
        
        # Format date for CAML query
        $DisposeDateString = $DisposeDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
        
        # Create query to filter items
        $Query = New-Object Microsoft.SharePoint.SPQuery
        $Query.Query = "<Where>
                          <And>
                            <Eq>
                              <FieldRef Name='$($classificationField.InternalName)'/>
                              <Value Type='$($classificationField.TypeAsString)'>$DocumentClassification</Value>
                            </Eq>
                            <Lt>
                              <FieldRef Name='$($disposeDateField.InternalName)'/>
                              <Value Type='$($disposeDateField.TypeAsString)'>$DisposeDateString</Value>
                            </Lt>
                          </And>
                        </Where>"
        Write-Log "Executing CAML query: $($Query.Query)" -Color "Gray"

        $ListItems = $List.GetItems($Query)
        Write-Log "Found $($ListItems.Count) items matching criteria" -Color "Green"
        return $ListItems
    }
    Catch {
        Write-Log "Error retrieving list items: $($_.Exception.Message)" -Level "ERROR" -Color "Red"

        # Alternative approach: manually filter items if CAML query fails
        Write-Log "Trying alternative filtering method..." -Color "Yellow"
        try {
            $allItems = $List.Items
            $filteredItems = @()
            
            foreach ($item in $allItems) {
                $itemClassification = $item[$classificationField.InternalName]
                $itemDisposeDate = $item[$disposeDateField.InternalName]
                
                if ($itemClassification -eq $DocumentClassification -and $itemDisposeDate -ne $null -and $itemDisposeDate -lt $DisposeDate) {
                    $filteredItems += $item
                }
            }
            
            Write-Log "Found $($filteredItems.Count) items using alternative filtering" -Color "Green"
            return $filteredItems
        }
        catch {
            Write-Log "Alternative filtering also failed: $($_.Exception.Message)" -Level "ERROR" -Color "Red"
            return $null
        }
    }
    Finally {
        if ($Web -ne $null) {
            $Web.Dispose()
        }
    }
}

# Function to Download Specific Folder from SharePoint
Function Download-SPFolder($SPFolderURL, $DownloadPath, $DryRun)
{
    Try {
        # Get the Source SharePoint Folder
        $SPFolder = $web.GetFolder($SPFolderURL)
        $FolderDownloadPath = Join-Path $DownloadPath $SPFolder.Name
        
        if (-not $DryRun) {
            # Ensure the destination local folder exists!
            If (!(Test-Path -path $FolderDownloadPath)) {   
                $LocalFolder = New-Item $FolderDownloadPath -type directory -Force
                Write-Log "Created local directory: $FolderDownloadPath" -Color "Yellow"
            }
    
            # Loop through each file in the folder and download it to Destination
            $fileCount = 0
            ForEach ($File in $SPFolder.Files)
            {
                # Download the file
                $Data = $File.OpenBinary()
                $FilePath = Join-Path $FolderDownloadPath $File.Name
                [System.IO.File]::WriteAllBytes($FilePath, $data)
                $fileCount++
                Write-Log "Downloaded file: $($File.Name)" -Color "Green"
            }
    
            Write-Log "Downloaded $fileCount files from folder: $($SPFolder.Name)" -Color "Green"
    
            # Process the Sub Folders & Recursively call the function
            $subFolderCount = 0
            ForEach ($SubFolder in $SPFolder.SubFolders)
            {
                If($SubFolder.Name -ne "Forms") # Leave "Forms" Folder
                {
                    # Call the function Recursively
                    Download-SPFolder $SubFolder $FolderDownloadPath $DryRun
                    $subFolderCount++
                }
            }
            
            if ($subFolderCount -gt 0) {
                Write-Log "Processed $subFolderCount subfolders in: $($SPFolder.Name)" -Color "Green"
            }
        } else {
            # Dry run - just count files and folders
            $fileCount = $SPFolder.Files.Count
            $subFolderCount = ($SPFolder.SubFolders | Where-Object {$_.Name -ne "Forms"}).Count
            
            Write-Log "DRY RUN: Would download $fileCount files from folder: $($SPFolder.Name)" -Color "Magenta"
            if ($subFolderCount -gt 0) {
                Write-Log "DRY RUN: Would process $subFolderCount subfolders in: $($SPFolder.Name)" -Color "Magenta"
            }
            
            # Process subfolders recursively for dry run
            ForEach ($SubFolder in $SPFolder.SubFolders)
            {
                If($SubFolder.Name -ne "Forms") {
                    Download-SPFolder $SubFolder $FolderDownloadPath $DryRun
                }
            }
        }
        
        return $true
    }
    Catch {
        Write-Log "Error Downloading Folder $SPFolderURL : $($_.Exception.Message)" -Level "ERROR" -Color "Red"
        return $false
    } 
}

# Function to delete SharePoint folder
Function Remove-SPFolder($SPFolderURL, $DryRun)
{
    Try {
        if (-not $DryRun) {
            $folder = $web.GetFolder($SPFolderURL)
            $folder.Delete()
            Write-Log "Deleted folder: $SPFolderURL" -Color "Yellow"
            return $true
        } else {
            Write-Log "DRY RUN: Would delete folder: $SPFolderURL" -Color "Magenta"
            return $true
        }
    }
    Catch {
        Write-Log "Error deleting folder $SPFolderURL : $($_.Exception.Message)" -Level "ERROR" -Color "Red"
        return $false
    }
}

# Main Function
Function Download-SPDocumentLibraryByCondition($SiteURL, $LibraryName, $ConditionListName, $DownloadPath, $DryRun, $DeleteAfterDownload, $DocumentClassification, $DisposeDate)
{
    $successCount = 0
    $failCount = 0
    $deleteSuccessCount = 0
    $deleteFailCount = 0
    
    $exportData = @()

    Try {
        Write-Log "Starting SharePoint Document Library Download Process" -Color "Cyan"
        Write-Log "Site URL: $SiteURL" -Color "Cyan"
        Write-Log "Library Name: $LibraryName" -Color "Cyan"
        Write-Log "Condition List Name: $ConditionListName" -Color "Cyan"
        Write-Log "Download Path: $DownloadPath" -Color "Cyan"
        Write-Log "Document Classification: $DocumentClassification" -Color "Cyan"
        Write-Log "Dispose Date Threshold: $($DisposeDate.ToString("yyyy-MM-dd"))" -Color "Cyan"
        Write-Log "Dry Run: $DryRun" -Color "Cyan"
        Write-Log "Delete After Download: $DeleteAfterDownload" -Color "Cyan"
        Write-Log "Log File: $LogFilePath" -Color "Cyan"

        # Get the web
        $Web = Get-SPWeb $SiteURL
        $global:web = $Web  # Make web available to other functions
 
        # Get filtered items from the condition list
        $FilteredItems = Get-FilteredListItems -SiteURL $SiteURL -ListName $ConditionListName -DocumentClassification $DocumentClassification -DisposeDate $DisposeDate
        
        if ($FilteredItems -eq $null -or $FilteredItems.Count -eq 0) {
            Write-Log "No items found matching the criteria" -Color "Yellow"
            return
        }
        
        # Get the document library
        $Library = $Web.Lists[$LibraryName]
        Write-Log "Processing $($FilteredItems.Count) items matching criteria" -Color "Green"
 
        # Process each filtered item
        foreach ($Item in $FilteredItems) {
            $FolderName = $Item.Title
            Write-Log "Processing item: $FolderName" -Color "Cyan"
            
            # Remove .xml extension from the title to get the folder name
            #if ($FolderName.EndsWith(".xml")) {
            #    $FolderName = $FolderName.Substring(0, $FolderName.Length - 4)
            #    Write-Log "Removed .xml extension, looking for folder: $FolderName" -Color "Yellow"
            #}

            # Remove .xml extension from the title to get the folder name (case-insensitive)
            if ($FolderName -like "*.xml") {
                $FolderName = [System.IO.Path]::GetFileNameWithoutExtension($FolderName)
                Write-Log "Removed .xml extension, looking for folder: $FolderName" -Color "Yellow"
            }

            # Try to find the folder in the document library
            try {
                $Folder = $Library.RootFolder.SubFolders[$FolderName]
                if ($Folder -ne $null) {
                    Write-Log "Found matching folder: $FolderName" -Color "Green"
                    
                    # Download the folder
                    $downloadResult = Download-SPFolder -SPFolderURL $Folder.Url -DownloadPath $DownloadPath -DryRun $DryRun
                    
                    if ($downloadResult) {
                        $successCount++
                        Write-Log "Successfully processed folder: $FolderName" -Color "Green"

                        # Build the full download path
                        $fullDownloadPath = Join-Path $DownloadPath $FolderName
                        
                        # Add to export data
                        $exportItem = [PSCustomObject]@{
                            Name = $FolderName
                            EPCode = $Item["EP_x0020_Code"]
                            VBOXDescription = $Item["VBOX_x0020_Description"]
                            ITClassification = $Item["IT_x0020_Classification"]
                            AccountDepartment = $Item["Account_x0020_Department"]
                            AccountDivision = $Item["Account_x0020_Division"]
                            DisposeDate = $Item["Dispose_x0020_Date"]
                            DownloadedFolder = $fullDownloadPath
                            Status = "Success"
                        }
                        $exportData += $exportItem
                        
                        # Delete the folder if requested and download was successful
                        if ($DeleteAfterDownload -and (-not $DryRun)) {
                            $deleteResult = Remove-SPFolder -SPFolderURL $Folder.Url -DryRun $DryRun
                            if ($deleteResult) {
                                $deleteSuccessCount++
                                Write-Log "Successfully deleted folder: $FolderName" -Color "Yellow"
                                $exportItem.Status = "Success (Deleted)"
                            } else {
                                $deleteFailCount++
                                Write-Log "Failed to delete folder: $FolderName" -Level "ERROR" -Color "Red"
                                $exportItem.Status = "Success (Delete Failed)"
                            }
                        }
                    } else {
                        $failCount++
                        Write-Log "Failed to process folder: $FolderName" -Level "ERROR" -Color "Red"

                        # Add to export data with error status
                        $exportItem = [PSCustomObject]@{
                            Name = $FolderName
                            EPCode = $Item["EP_x0020_Code"]
                            VBOXDescription = $Item["VBOX_x0020_Description"]
                            ITClassification = $Item["IT_x0020_Classification"]
                            AccountDepartment = $Item["Account_x0020_Department"]
                            AccountDivision = $Item["Account_x0020_Division"]
                            DisposeDate = $Item["Dispose_x0020_Date"]
                            DownloadedFolder = ""
                            Status = "Download Failed"
                        }
                        $exportData += $exportItem
                    }
                }
                else {
                    Write-Log "Folder not found in document library: $FolderName" -Color "Yellow"

                    # Add to export data with not found status
                        $exportItem = [PSCustomObject]@{
                            Name = $FolderName
                            EPCode = $Item["EP_x0020_Code"]
                            VBOXDescription = $Item["VBOX_x0020_Description"]
                            ITClassification = $Item["IT_x0020_Classification"]
                            AccountDepartment = $Item["Account_x0020_Department"]
                            AccountDivision = $Item["Account_x0020_Division"]
                            DisposeDate = $Item["Dispose_x0020_Date"]
                            DownloadedFolder = ""
                            Status = "Folder Not Found"
                        }
                        $exportData += $exportItem
                }
            }
            catch {
                Write-Log "Error accessing folder $FolderName : $($_.Exception.Message)" -Level "ERROR" -Color "Red"
                $failCount++

                # Add to export data with error status
                $exportItem = [PSCustomObject]@{
                    Name = $FolderName
                    EPCode = $Item["EP_x0020_Code"]
                    VBOXDescription = $Item["VBOX_x0020_Description"]
                    ITClassification = $Item["IT_x0020_Classification"]
                    AccountDepartment = $Item["Account_x0020_Department"]
                    AccountDivision = $Item["Account_x0020_Division"]
                    DisposeDate = $Item["Dispose_x0020_Date"]
                    DownloadedFolder = ""
                    Status = "Error: $($_.Exception.Message)"
                }
                $exportData += $exportItem
            }
        }

        # Export to CSV file
        if ($exportData.Count -gt 0) {
            $csvFilePath = Join-Path (Split-Path $LogFilePath -Parent) "DownloadReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
            $exportData | Export-Csv -Path $csvFilePath -NoTypeInformation -Encoding UTF8
            Write-Log "Export report saved to: $csvFilePath" -Color "Green"
        }
 
        # Summary report
        Write-Log "=== PROCESS SUMMARY ===" -Color "Cyan"
        Write-Log "Filter Criteria: Classification='$DocumentClassification', DisposeDate < '$($DisposeDate.ToString("yyyy-MM-dd"))'" -Color "Cyan"
        Write-Log "Total items processed: $($FilteredItems.Count)" -Color "Cyan"
        Write-Log "Successfully downloaded: $successCount" -Color "Green"
        Write-Log "Failed to download: $failCount" -Color "Red"
        
        if ($DeleteAfterDownload) {
            Write-Log "Successfully deleted: $deleteSuccessCount" -Color "Green"
            Write-Log "Failed to delete: $deleteFailCount" -Color "Red"
        }
        
        if ($DryRun) {
            Write-Log "*** DRY RUN COMPLETED - No changes were made ***" -Color "Magenta"
        } else {
            Write-Log "*** OPERATION COMPLETED ***" -Color "Green"
        }
    }
    Catch {
        Write-Log "Error in main process: $($_.Exception.Message)" -Level "ERROR" -Color "Red"
    }
    Finally {
        if ($Web -ne $null) {
            $Web.Dispose()
            Remove-Variable web -Scope Global -ErrorAction SilentlyContinue
        }
    }
}

# Main execution
try {
    # List fields if requested
    if ($ListFields) {
        Get-ListFields -SiteURL $SiteURL -ListName $ConditionListName
        exit
    }

    # Execute the download process
    Download-SPDocumentLibraryByCondition -SiteURL $SiteURL -LibraryName $LibraryName -ConditionListName $ConditionListName -DownloadPath $DownloadPath -DryRun $DryRun -DeleteAfterDownload $DeleteAfterDownload -DocumentClassification $DocumentClassification -DisposeDate $DisposeDate

    Write-Log "Log file saved to: $LogFilePath" -Color "Cyan"
}
catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" -Level "ERROR" -Color "Red"
    Write-Log "Stack trace: $($_.Exception.StackTrace)" -Level "ERROR" -Color "Red"
}