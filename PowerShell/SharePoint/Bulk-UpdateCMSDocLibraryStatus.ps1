Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

# CONFIGURATION
$siteUrl = "http://my.sharepointsite.com"
$listName = "SP List Name"
$validcount = 0

# Logging configuration
$logPath = "D:\temp\Logs"
$logFileName = "CMSDocLib_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$logFile = Join-Path -Path $logPath -ChildPath $logFileName

# Create log directory if it doesn't exist
if (!(Test-Path -Path $logPath)) {
    New-Item -ItemType Directory -Path $logPath -Force | Out-Null
}

# Function to write to both console and log file
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Write-Host $logEntry
    Add-Content -Path $logFile -Value $logEntry
}

try {
    Write-Log "Script execution started"
    Write-Log "Site URL: $siteUrl"
    Write-Log "List Name: $listName"
    Write-Log "Log file: $logFile"

    # Connect to site
    Write-Log "Connecting to SharePoint site..."
    $site = Get-SPSite $siteUrl
    $web = $site.RootWeb    

    $list = $web.Lists[$listName]	
    $list2 = $web.Lists[$listName]					
    $ListItems = $List.Items | Where {$_["_ModerationStatus"] -eq 3 -And $_["DocIcon"] -eq "pdf"}

    Write-Log "Total doc of Items: "$ListItems.count

    #Loop through Each Item
    ForEach ($Item in $ListItems) 
    {
        #Do something
        $itemId  = $Item["ID"]
        $docNumber  = $Item["Document Number"]
        $approvalStatus  = $Item["Approval Status"]
        $srcLists = $list2.Items | Where-Object {$_["Document Number"] -eq $val1 -And $_["_ModerationStatus"] -eq 3 -And $_["DocIcon"] -like "doc*"}
        
        Write-Log "[$itemId] - $docNumber : $approvalStatus : " $srcLists.count
        if ($srcLists.count -gt 0){
            try{
                # Update the PDF Items
                $item["_ModerationStatus"] = 0
                $item["Modified By"] = "1000000001;#Riva Fauzie"
                $today = Get-Date -Format "yyyy-MM-dd"
                $item["Modified"] = $today
                $item.Update()
                Write-Log "Successfully updated PDF item ID : $itemId"

                foreach($srcItem in $srcLists) {
                    $srcItmId = $srcItem["ID"]
                    $srcItem["_ModerationStatus"] = 0
                    $srcItem["Modified By"] = "1000000001;#Riva Fauzie"
                    $srcItem["Modified"] = $today
                    $srcItem.Update()
                    Write-Log "Successfully update DOC item ID : $srcItemId for document number : $docNumber"
                }
                $validcount = $validcount + 1
                Write-Log "Completed processing document number: $docNumber - Total processed: $validcount"
            } catch {
                Write-Log "Error updating items for document number: $docNumber - $($_.Exception.Message)" -Level "ERROR"
            }
        } else {
            Write-Log "No matching DOC files found for document number: $docNumber" -Level "WARNING"
        }
    }
    Write-Log "Script execution completed"
    Write-Log "Total documents successfully processed: $validcount"
    Write-Log "Total documents that could not be processed: $($ListItems.count - $validcount)"
} catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" -Level "ERROR"
} finnaly {
    # Cleanup
    if ($web) {
        $web.Dispose()
        Write-Log "Web object disposed"
    }
    if ($site) {
        $site.Dispose()
        Write-Log "Site object disposed"
    }
    Write-Log "Log file saved to: $logFile"
}

		

		

