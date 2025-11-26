Add-Type -Path "./Libraries/Microsoft.SharePoint.Client.dll"
Add-Type -Path "./Libraries/Microsoft.SharePoint.Client.Runtime.dll"


Function New-Context([String]$WebUrl) {
    $context = New-Object Microsoft.SharePoint.Client.ClientContext($WebUrl)
    $context.Credentials = [System.Net.CredentialCache]::DefaultNetwOrkCredentials
    $context
}

Function Get-List([Microsoft.SharePoint.Client.ClientContext]$Context, [String]$ListTitle) {
    $list = $context.Web.Lists.GetByTitle($ListTitle)
    $context.Load($list)
    $context.ExecuteQuery()
    $list 
}

# Function to copy an item to another list
Function Move-FileToLibrary([Microsoft.SharePoint.Client.ListItem]$SourceItem, [Microsoft.SharePoint.Client.ClientContext]$Context) {
    
    $fileName = $SourceItem["FileLeafRef"]

    $file = $SourceItem.File
    $Context.Load($file)
    $Context.ExecuteQuery()

    $destinationPath = "/Archived Email/$fileName"

    $file.MoveTo($destinationPath, [Microsoft.SharePoint.Client.MoveOperations]::Overwrite)
    $Context.ExecuteQuery()
}

$LogFolder = "C:/temp/test/Logs"
$Timestamp = (Get-Date).ToString("dd-MMM-yyyy HH-mm")
if (-not (Test-Path $LogFolder)) {
    New-Item -Path $LogFolder -ItemType Directory
}


$context = New-Context -WebUrl "http://mysharepointsite.com/"

# Record the start time
$StartTime = Get-Date

$lists = $Context.web.Lists 
$IncomingList = $lists.GetByTitle("Incoming E-mail")  

# Define start and end dates
$YearAgo = (Get-Date).AddYears(-1).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Initialize variables

$AllItemsCount = 0
$BatchCount = 1
$context.RequestTimeout = 600000 
$ErrorCount = 0
$MaxErrorRetries = 3
$ItemPerBatch = 1000

# Create CAML query to filter list items

$Query = New-Object Microsoft.SharePoint.Client.CamlQuery
$Query.ViewXml = @"
<View>
    <Query>
        <Where>
		    <Leq>
                <FieldRef Name='EmDate' />
                <Value Type='DateTime'>$YearAgo</Value>
            </Leq>
        </Where>
    </Query>
    <RowLimit>$ItemPerBatch</RowLimit>
</View>
"@
$Query.ListItemCollectionPosition = $null

do {
    $LogFile = Join-Path $LogFolder "$Timestamp Batch $BatchCount.log"
    # Stop after exceeding maximum retries
    if ($ErrorCount -ge $MaxErrorRetries) {
        Write-Error "Exceeded maximum retry attempts. Exiting..."
        break
    }

    Write-Host "Retrieving batch $BatchCount..."

    # Retrieve list items for the current batch
    $listItems = $IncomingList.GetItems($Query)
    $context.Load($listItems)

    try {
        $context.ExecuteQuery()
    } catch {
        Write-Error "Failed to execute query: $_"
        $ErrorCount++
        continue
    }

    $no = 1

    foreach ($item in $listItems) {
        try {
            Move-FileToLibrary -SourceItem $item -Context $context
            $batchLog = ("{0,-5} of {1,-5} {2}" -f $no, $ItemPerBatch, $item["FileLeafRef"])
            Write-Host $batchLog
            Add-Content -Path $LogFile -Value $batchLog
        } catch {
            $batchLog = "Failed to process item ID $($item.Id): $_"
            Write-Error $batchLog
            Add-Content -Path $LogFile -Value $batchLog
        }
        $no++
    }

    # Reset error count after a successful batch retrieval
    $ErrorCount = 0

    $AllItemsCount += $listItems.Count

    # Update query position for the next batch
    $Query.ListItemCollectionPosition = $listItems.ListItemCollectionPosition
    $BatchCount++
} while ($BatchCount -le 35)
	#($Query.ListItemCollectionPosition -ne $null)



# Output the results
$BatchCount--
Write-Host "Retrieved $($AllItemsCount) items across $BatchCount batch(es)."

# Record the end time
$EndTime = Get-Date

# Calculate and display total processing time
$TotalTime = $EndTime - $StartTime
Write-Host "Processing completed in $($TotalTime.Hours) hours, $($TotalTime.Minutes) minutes, $($TotalTime.Seconds) seconds."

#  Write summary to log file
$LogFile = Join-Path $LogFolder "$Timestamp.txt"
Add-Content -Path $LogFile -Value "Retrieved $($AllItemsCount) items across $BatchCount batch(es)."
Add-Content -Path $LogFile -Value "Processing completed in $($TotalTime.Hours) hours, $($TotalTime.Minutes) minutes, $($TotalTime.Seconds) seconds."