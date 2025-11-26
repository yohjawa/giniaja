Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
  
#Set config variables
$WebURL="http://mysharepointsite.com/"
$ListName ="VBOX"
$OutPutFile = "D:\Tmp\vbox.csv"
 
#Delete the Output File if exists
If (Test-Path $OutPutFile) { Remove-Item $OutPutFile }
  
#Get Web and List Objects
$Web = Get-SPWeb $WebURL
$List = $Web.Lists[$ListName]
Write-host "Total Number of Items Found:"$List.Itemcount  -f Green
   
#Define the CAML Query
$BatchSize = 500
$Query = New-Object Microsoft.SharePoint.SPQuery
$Query.ViewXml = @"
    <View Scope='Recursive'>
        <Query>
            <OrderBy><FieldRef Name='ID' Ascending='TRUE'/></OrderBy>
        </Query>
        <RowLimit Paged='TRUE'>$BatchSize</RowLimit>
    </View>
"@
 
$Counter = 0
#Process items in batch
Do
{
    #Get List Items
    $ListItems = $List.GetItems($Query)
    $Counter =  $Counter+$ListItems.Count
    Write-Progress -PercentComplete ($Counter / ($List.ItemCount) * 100) -Activity "Exporting List Items of '$($List.Title)'" -Status "Processing Items $Counter of $($List.ItemCount)"
 
    #Array to Hold Result - PSObjects
    $ListItemCollection = @()
    
    #Get All List items
    $ListItems | ForEach {
        #write-host "Processing Item ID:"$_["ID"]
   
        $ExportItem = New-Object PSObject
        $ExportItem | Add-Member -MemberType NoteProperty -name "Name" -value $_["Title"]
        $ExportItem | Add-Member -MemberType NoteProperty -Name "Description" -value $_["VBOX Description"]
        $ExportItem | Add-Member -MemberType NoteProperty -name "EP Code" -value $_["EP Code"]
        $ExportItem | Add-Member -MemberType NoteProperty -name "IT Clasification" -value $_["IT Classification"]
        $ExportItem | Add-Member -MemberType NoteProperty -name "Account Division" -value $_["Account Division"]
        $ExportItem | Add-Member -MemberType NoteProperty -name "Account Department" -value $_["Account Department"]
        $ExportItem | Add-Member -MemberType NoteProperty -name "Created Date" -value $_["Created"]
        $ExportItem | Add-Member -MemberType NoteProperty -name "Created By" -value $_["Created By"]
        $ExportItem | Add-Member -MemberType NoteProperty -name "Modified Date" -value $_["Modified"]
        #Add the object with property to an Array
        $ListItemCollection += $ExportItem
    }
    #Export the result Array to CSV file
    $ListItemCollection | Export-CSV $OutPutFile -NoTypeInformation -append
 
    $Query.ListItemCollectionPosition = $ListItems.ListItemCollectionPosition
}
While($Query.ListItemCollectionPosition -ne $null)
 
Write-host "List data exported to CSV Successfully!" -f Green
