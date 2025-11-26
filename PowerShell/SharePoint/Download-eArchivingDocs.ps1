Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# Configuration parameters
$SiteURL = "http://mysharepointsite.com"
$LibraryName = "E-ARCHIVES"
$DownloadPath = "D:\temp\DL"
$ClassificationCriteria = "Public" # Change this to your desired classification

# Choose ONE of the following date criteria options:
# Option 1: Specific cutoff date
$DisposedDateBefore = "2025-01-01" # Format: YYYY-MM-DD

# Option 2: Older than X years (alternative to specific date)
# $DisposedDateOlderThanYears = 1 # Uncomment and use this if you prefer age-based criteria

$DeleteAfterDownload = $false # Set to $false if you don't want to delete after download
$DryRun = $true # Set to $false to actually perform download and delete operations

# Logging configuration
$LogPath = "D:\temp\Logs"
$LogFileName = "SharePointDownload_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$LogFile = Join-Path $LogPath $LogFileName

# Function to write log messages
Function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    
    # Write to console with color
    Write-Host -ForegroundColor $Color $logEntry
    
    # Write to log file
    try {
        if (!(Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
        }
        Add-Content -Path $LogFile -Value $logEntry -ErrorAction Stop
    }
    catch {
        Write-Host -ForegroundColor Red "Failed to write to log file: $($_.Exception.Message)"
    }
}

# Function to get the cutoff date based on configuration
Function Get-CutoffDate {
    if ($DisposedDateBefore) {
        try {
            $cutoffDate = [DateTime]::Parse($DisposedDateBefore)
            Write-Log -Message "Using specific cutoff date: $($cutoffDate.ToString('yyyy-MM-dd'))" -Level "INFO" -Color "Cyan"
            return $cutoffDate
        }
        catch {
            Write-Log -Message "Error parsing DisposedDateBefore '$DisposedDateBefore'. Please use YYYY-MM-DD format." -Level "ERROR" -Color "Red"
            throw
        }
    }
    elseif ($DisposedDateOlderThanYears) {
        $cutoffDate = (Get-Date).AddYears(-$DisposedDateOlderThanYears)
        Write-Log -Message "Using age-based cutoff date: $($cutoffDate.ToString('yyyy-MM-dd')) (older than $DisposedDateOlderThanYears year(s))" -Level "INFO" -Color "Cyan"
        return $cutoffDate
    }
    else {
        Write-Log -Message "No date criteria specified. Please set either DisposedDateBefore or DisposedDateOlderThanYears." -Level "ERROR" -Color "Red"
        throw "Date criteria required"
    }
}

# Function to check if folder meets criteria
Function Test-SPFolderCriteria($Folder, $CutoffDate)
{
    $meetsCriteria = $true
    
    try {
        # Try to get the folder as a list item to access custom fields
        $folderItem = $Folder.Item
        
        if ($folderItem -ne $null) {
            # Check classification criteria if specified
            if ($ClassificationCriteria) {
                $classificationValue = $folderItem["Data Classification"]
                if ($classificationValue -ne $ClassificationCriteria) {
                    return @{
                        MeetsCriteria = $false
                        Reason = "Classification mismatch: '$classificationValue' != '$ClassificationCriteria'"
                    }
                }
            }
            
            # Check disposal date criteria
            $disposedDate = $folderItem["Dispose Date"]
            if ($disposedDate -ne $null) {
                if ($disposedDate -ge $CutoffDate) {
                    return @{
                        MeetsCriteria = $false
                        Reason = "Dispose Date too recent: $($disposedDate.ToString('yyyy-MM-dd')) >= $($CutoffDate.ToString('yyyy-MM-dd'))"
                    }
                }
            }
            else {
                return @{
                    MeetsCriteria = $false
                    Reason = "No DisposedDate value"
                }
            }
        }
        else {
            return @{
                MeetsCriteria = $false
                Reason = "Not a list item (no custom fields)"
            }
        }
    }
    catch {
        return @{
            MeetsCriteria = $false
            Reason = "Error checking criteria: $($_.Exception.Message)"
        }
    }
    
    return @{
        MeetsCriteria = $true
        Reason = "Meets all criteria"
    }
}

# Function to process folders for dry run (just reporting)
Function Process-FoldersDryRun($SPFolder, $CutoffDate, $IndentLevel = 0)
{
    Try {
        $indent = "  " * $IndentLevel
        $folderResult = Test-SPFolderCriteria -Folder $SPFolder -CutoffDate $CutoffDate
        
        if ($folderResult.MeetsCriteria) {
            $logMessage = "$indent✓ FOLDER: $($SPFolder.ServerRelativeURL)"
            Write-Log -Message $logMessage -Level "SUCCESS" -Color "Green"
            Write-Log -Message "$indent  Reason: $($folderResult.Reason)" -Level "INFO" -Color "Gray"
            
            # Count files in this folder
            $fileCount = $SPFolder.Files.Count
            Write-Log -Message "$indent  Files: $fileCount file(s) would be downloaded" -Level "INFO" -Color "Cyan"
            
            if ($DeleteAfterDownload) {
                Write-Log -Message "$indent  Action: Would download and DELETE $fileCount file(s)" -Level "WARNING" -Color "Yellow"
            }
            else {
                Write-Log -Message "$indent  Action: Would download $fileCount file(s) (no deletion)" -Level "INFO" -Color "Cyan"
            }
        }
        else {
            $logMessage = "$indent✗ FOLDER: $($SPFolder.ServerRelativeURL)"
            Write-Log -Message $logMessage -Level "SKIPPED" -Color "Red"
            Write-Log -Message "$indent  Reason: $($folderResult.Reason)" -Level "INFO" -Color "Gray"
            Write-Log -Message "$indent  Action: Skipped (no files would be processed)" -Level "INFO" -Color "DarkGray"
        }
        
        Write-Log -Message "" -Level "INFO" -Color "White" # Empty line for readability
  
        # Process the Sub Folders recursively
        ForEach ($SubFolder in $SPFolder.SubFolders)
        {
            If($SubFolder.Name -ne "Forms") # Leave "Forms" Folder
            {
                Process-FoldersDryRun -SPFolder $SubFolder -CutoffDate $CutoffDate -IndentLevel ($IndentLevel + 1)
            }
        }
    }
    Catch {
        Write-Log -Message "$indentError processing folder: $($_.Exception.Message)" -Level "ERROR" -Color "Red"
    } 
}

# Function to Download Files from a SharePoint Folder (actual operations)
Function Download-SPFolder($SPFolder, $DownloadPath, $CutoffDate)
{
    Try {
        $DownloadPath = Join-Path $DownloadPath $SPFolder.Name
        
        # Ensure the destination local folder exists
        If (!(Test-Path -path $DownloadPath)) {   
            $LocalFolder = New-Item $DownloadPath -type directory -Force
            Write-Log -Message "Created local folder: $DownloadPath" -Level "INFO" -Color "Cyan"
        }
  
        # Loop through each file in the folder
        ForEach ($File in $SPFolder.Files)
        {
            # Download the file without checking file-level criteria
            try {
                if (-not $DryRun) {
                    $Data = $File.OpenBinary()
                    $FilePath = Join-Path $DownloadPath $File.Name
                    [System.IO.File]::WriteAllBytes($FilePath, $data)
                    Write-Log -Message "Downloaded the File: $($File.ServerRelativeURL)" -Level "SUCCESS" -Color "Green"
                    
                    # Delete the file after successful download if enabled
                    if ($DeleteAfterDownload) {
                        try {
                            $File.Delete()
                            Write-Log -Message "Deleted the File: $($File.ServerRelativeURL)" -Level "WARNING" -Color "Yellow"
                        }
                        catch {
                            Write-Log -Message "Error deleting file: $($_.Exception.Message)" -Level "ERROR" -Color "Red"
                        }
                    }
                }
            }
            catch {
                Write-Log -Message "Error downloading file: $($_.Exception.Message)" -Level "ERROR" -Color "Red"
            }
        }
  
        # Process the Sub Folders recursively with criteria checking
        ForEach ($SubFolder in $SPFolder.SubFolders)
        {
            If($SubFolder.Name -ne "Forms") # Leave "Forms" Folder
            {
                # Check if the folder meets criteria
                $folderResult = Test-SPFolderCriteria -Folder $SubFolder -CutoffDate $CutoffDate
                if ($folderResult.MeetsCriteria) {
                    Write-Log -Message "Processing qualified folder: $($SubFolder.ServerRelativeURL)" -Level "INFO" -Color "Magenta"
                    # Call the function recursively
                    Download-SPFolder -SPFolder $SubFolder -DownloadPath $DownloadPath -CutoffDate $CutoffDate
                }
                else {
                    Write-Log -Message "Skipping folder (doesn't meet criteria): $($SubFolder.ServerRelativeURL)" -Level "INFO" -Color "Gray"
                }
            }
        }
    }
    Catch {
        Write-Log -Message "Error processing folder: $($_.Exception.Message)" -Level "ERROR" -Color "Red"
    } 
}

# Main Function
Function Download-SPDocumentLibrary($SiteURL, $LibraryName, $DownloadPath)
{
    Write-Log -Message "Starting SharePoint Document Library Download Process" -Level "INFO" -Color "Magenta"
    Write-Log -Message "Log file: $LogFile" -Level "INFO" -Color "Cyan"
    
    Try {
        # Get the cutoff date
        $CutoffDate = Get-CutoffDate
        
        # Get the Web
        $Web = Get-SPWeb $SiteURL
 
        # Get the document Library
        $Library = $Web.Lists[$LibraryName]
        Write-Log -Message "Processing Document Library: $($Library.Title)" -Level "INFO" -Color "Magenta"
        Write-Log -Message "Criteria: Classification='$ClassificationCriteria', DisposedDate before $($CutoffDate.ToString('yyyy-MM-dd'))" -Level "INFO" -Color "Cyan"
        Write-Log -Message "Dry Run: $DryRun" -Level "INFO" -Color "Yellow"
        Write-Log -Message "Delete After Download: $DeleteAfterDownload" -Level "INFO" -Color "Yellow"
        Write-Log -Message "=" * 80 -Level "INFO" -Color "White"
        
        if ($DryRun) {
            Write-Log -Message "DRY RUN MODE - No files will be downloaded or deleted" -Level "WARNING" -Color "Yellow"
            Write-Log -Message "Legend: ✓ = Meets criteria, ✗ = Doesn't meet criteria" -Level "INFO" -Color "Yellow"
            Write-Log -Message "=" * 80 -Level "INFO" -Color "White"
            
            # Process root folder for dry run
            Process-FoldersDryRun -SPFolder $Library.RootFolder -CutoffDate $CutoffDate
            
            Write-Log -Message "=" * 80 -Level "INFO" -Color "White"
            Write-Log -Message "Dry run completed. Review the results above." -Level "SUCCESS" -Color "Green"
            Write-Log -Message "Set `$DryRun = `$false to perform actual operations." -Level "INFO" -Color "Yellow"
        }
        else {
            # Delete any existing files and folders in the download location
            If (Test-Path $DownloadPath) {
                Remove-Item -Path $DownloadPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-Log -Message "Cleaned existing download directory: $DownloadPath" -Level "INFO" -Color "Cyan"
            }
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
            Write-Log -Message "Created download directory: $DownloadPath" -Level "INFO" -Color "Cyan"
            
            # Check if root folder meets criteria
            $rootFolderResult = Test-SPFolderCriteria -Folder $Library.RootFolder -CutoffDate $CutoffDate
            
            if ($rootFolderResult.MeetsCriteria) {
                Write-Log -Message "Root folder meets criteria, processing all content..." -Level "SUCCESS" -Color "Green"
                Download-SPFolder -SPFolder $Library.RootFolder -DownloadPath $DownloadPath -CutoffDate $CutoffDate
            }
            else {
                Write-Log -Message "Root folder doesn't meet criteria, processing subfolders only..." -Level "INFO" -Color "Magenta"
                # Process only subfolders that meet criteria
                ForEach ($SubFolder in $Library.RootFolder.SubFolders)
                {
                    If($SubFolder.Name -ne "Forms") # Leave "Forms" Folder
                    {
                        $folderResult = Test-SPFolderCriteria -Folder $SubFolder -CutoffDate $CutoffDate
                        if ($folderResult.MeetsCriteria) {
                            Write-Log -Message "Processing qualified folder: $($SubFolder.ServerRelativeURL)" -Level "INFO" -Color "Magenta"
                            Download-SPFolder -SPFolder $SubFolder -DownloadPath $DownloadPath -CutoffDate $CutoffDate
                        }
                        else {
                            Write-Log -Message "Skipping folder (doesn't meet criteria): $($SubFolder.ServerRelativeURL)" -Level "INFO" -Color "Gray"
                        }
                    }
                }
            }
 
            Write-Log -Message "*** Download Completed ***" -Level "SUCCESS" -Color "Green"
            
            # Show summary
            if ($DeleteAfterDownload) {
                Write-Log -Message "*** Files have been deleted from SharePoint after successful download ***" -Level "WARNING" -Color "Yellow"
            }
            else {
                Write-Log -Message "*** Files remain in SharePoint (delete after download is disabled) ***" -Level "INFO" -Color "Yellow"
            }
        }
    }
    Catch {
        Write-Log -Message "Error Processing Document Library: $($_.Exception.Message)" -Level "ERROR" -Color "Red"
    }
    Finally {
        if ($Web -ne $null) {
            $Web.Dispose()
            Write-Log -Message "Disposed SharePoint web object" -Level "INFO" -Color "Gray"
        }
        Write-Log -Message "Process completed. Log saved to: $LogFile" -Level "INFO" -Color "Cyan"
    }
}

# Execute the main function
Write-Log -Message "Script execution started" -Level "INFO" -Color "White"
Download-SPDocumentLibrary $SiteURL $LibraryName $DownloadPath
Write-Log -Message "Script execution finished" -Level "INFO" -Color "White"