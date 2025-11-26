Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Get the web and List
$Web = Get-SPWeb "https://mysharepointsite.com/sites/test/"
$SourceList = $web.Lists["Proposals"]
$TargetList = $Web.Lists["Proposal Archive 2009"]
 
#Get all Files Created in 2009
 $Query = '<Where>
		<And>
			<Geq>
				<FieldRef Name="Created" />
				<Value IncludeTimeValue="TRUE" Type="DateTime">2009-01-01T00:00:00Z</Value>
			</Geq>
			<Leq>
				<FieldRef Name="Created" />
				<Value IncludeTimeValue="TRUE" Type="DateTime">2009-12-31T23:59:59Z</Value>
			</Leq>
		</And>
	</Where>'
 $SPQuery = new-object Microsoft.SharePoint.SPQuery
 #$SPQuery.ViewAttributes = "Scope='Recursive'" #To include Sub-folders in the library
 $SPQuery.Query = $Query
 $SourceFilesCollection =$SourceList.GetItems($SPQuery)
 
Write-host "Total number of files found: "$SourceFilesCollection.count
 
#Move each file to the destination folder
foreach($item in $SourceFilesCollection)
{
  #Get the Source File
  $file = $Web.GetFile($item.File.URL)
 
  #Get the Month value from the File created date
  $MonthValue = $item.File.TimeCreated.ToString('MMMM')
   
  # Try to Get the Sub-Folder in the Library!
  $TargetFolder = $TargetList.ParentWeb.GetFolder($TargetList.RootFolder.Url + "/" +$MonthValue);
   
  #If the folder doesn't exist, Create!
  if ($TargetFolder.Exists -eq $false)
   {
     $TargetFolder = $TargetList.Folders.Add([string]::Empty, [Microsoft.SharePoint.SPFileSystemObjectType]::Folder, $MonthValue)
     $TargetFolder.Update() 
   }
 
   #Move the File
   $file.MoveTo($TargetFolder.Url + "/" + $File.name)  
}