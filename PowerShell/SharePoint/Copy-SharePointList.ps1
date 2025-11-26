Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue
 
#Custom PowerShell Function to Export All Lists and Libraries from a SharePoint site
Function Export-AllLists($WebURL, $ExportPath)
{
   #Get the source web
   $web = Get-SPWeb $WebURL
 
   #Check the Local Folder export Lists
     
   #Get all lists - Exclude System lists
   #$ListCollection = $web.lists | Where-Object  { ($_.hidden -eq $false) -and ($_.IsSiteAssetsLibrary -eq $false) -and ($_.Author.LoginName -ne "SHAREPOINT\system") }
   $ListCollection = $web.lists | Where-Object  { ($_.Title -eq "Risk Reduction Plan") }
 
   #Iterate through each list and export
   foreach($list in $ListCollection)
    {
        Write-host "Exporting: " $list.Title
        #Remove : from List title - As we can't name a file with : symbol
        $ListTitle = $list.Title.Replace(":",[string]::Empty)
        Export-SPWeb $WebURL -ItemUrl "/$($list.RootFolder.ServerRelativeUrl)" -IncludeUserSecurity -IncludeVersions All -path ($ExportPath + $ListTitle+ ".cmp") -nologfile
    } 
}
 
#Custom PowerShell Function to Export All Lists and Libraries from a SharePoint site
Function Import-AllLists($WebURL, $ImportPath)
{
   #Get the Target web
   $web = Get-SPWeb $WebURL
 
   #Check the Local Folder export Lists
     
   #Get all File Backups to Import
   $FilesCollection = Get-ChildItem $ImportPath
 
   #Iterate through each file and import
   foreach($File in $FilesCollection)
    {
        Write-host "Importing: " $File.Name
        Import-SPWeb $webURL -path $ImportPath$File -includeusersecurity -UpdateVersions Overwrite -nologfile
    } 
}
 
#Call the function to export
#Export-AllLists "http://mysharepointsite.com/sites/test1" "C:\temp\RRP\"
#To import, Use:
#Import-AllLists "http://mysharepointsite.com/sites/test2" "C:\temp\RRP\"

## Migrate list with lookup column
## 1. Find out the lookup list GUID on source sharepoint site and take a note of it
## 2. Export sharepoint list you want to migrate as template, as well as lookup column list, can exclude list content first
## 3. Upload the template stp file for lookup list to new site and create new application from that template
## 4. Find out the lookup list GUID on destination sharepoint site and take a note of it
## 5. Rename template file extension of the sharepoint list you want to migrate from .stp to .cab then browse the file to edit manifest.xml file in it
## 6. Search for GUID of lookup list you find out on step 1 and replace that GUID with the one you find out on step 4
## 7. Save the manifest.ixmlnf file
## 8. Make that manifest.xml file to CAB file by opening command prompt  and run the following command :
##    makecab manifest.xml templatename.stp
## 9. Import that list template to destination site and create application from it
## 10. continue with copying sharepoint list items from source to destination

$websURL = "http://mysharepointsite.com/sites/test1"
$webdURL = "http://mysharepointsite.com/sites/test2"
$ItemUrl = "/sites/test1/Lists/MD%20%20Facility%20Name"
$web = Get-SPWeb $websURL
$expPath = "C:\temp\RRP\MDFacilityName.cmp"

Export-SPWeb $websURL -ItemUrl $ItemUrl -IncludeUserSecurity -IncludeVersions All -Path $expPath
Import-SPWeb $webdURL -Path $expPath -IncludeUserSecurity -UpdateVersions Overwrite


## Export MD