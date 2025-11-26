Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
  
#Variables
$SiteUrl="http://mysharepointsite.com/"
$ListName="VBOX"
$OutPutFile = "D:\temp\vbox.csv"
  
#Get Web and List
$web = Get-SPWeb $SiteUrl
$List = $Web.Lists[$ListName]
Write-host "Total Number of Items Found:"$List.Itemcount
 
#Array to Hold Result - PSObjects
$ListItemCollection = @()
   
 #Get All List items 
 $List.Items | ForEach {
 write-host "Processing Item ID:"$_["ID"]
  
   $ExportItem = New-Object PSObject 
   #Get Each field
   foreach($Field in $_.Fields)
    {
        $ExportItem | Add-Member -MemberType NoteProperty -name $Field.InternalName -value $_[$Field.InternalName]  
    }
    #Add the object with property to an Array
    $ListItemCollection += $ExportItem
 
}  
#Export the result Array to CSV file
$ListItemCollection | Export-CSV $OutPutFile -NoTypeInformation
Write-host -f Green "List '$ListName' Exported to $($OutputFile) for site $($SiteURL)"
