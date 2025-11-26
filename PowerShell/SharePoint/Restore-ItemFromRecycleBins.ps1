##### Restore from recycle bin using PowerShell

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Configuration variables
$SiteURL="https://mysharepointsite.com/sites/test/"
$ItemName="Classifieds.xlsx" #Can be a List Name, File Name or ID of an Item
 
#Get Objects
$site = Get-SPSite $SiteURL
$RecycleBin = $site.RecycleBin
 
#Get the Item from Recycle bin
$Item = $RecycleBin | Where-Object{$_.Title -eq $ItemName}
 
if($null -ne $Item)
{
 $Item.Restore()
 Write-Host "Item Restored from Recycle Bin!" -f DarkGreen
}
else
{
 Write-Host "No Item Found with the given name!" -ForegroundColor RED
}


## restore particular object when deleted more than once
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
  
#Configuration variables
$SiteURL="https://mysharepointsite.com"
$ItemName="Juneau.docx"
 
#Get necessary objects
$Site = Get-SPSite $SiteURL
$Web = Get-SPWeb $SiteURL
$RecycleBin = $Site.RecycleBin
  
#Get the latest Item deleted from Recycle bin
$DeletedItem = $RecycleBin | Where-Object {$_.Title -eq $ItemName} | Sort-Object DeletedDate -Descending | Select-Object -First 1
 
If($Null -ne $DeletedItem)
{
    #Get the Original location of the deleted file
    $OriginalLocation = $DeletedItem.DirName+"/"+$DeletedItem.LeafName
 
    #Check if file exists
    If(!$Web.GetFile($OriginalLocation).Exists)
    {
        $DeletedItem.Restore()
        Write-Host "Deleted File restored Successfully!" -f Green
    }
    else
    {
        Write-Host "There is another item with the same name!" -f Yellow
    }
}
Else
{
    Write-Host "No Item Found with the given name!" -f Yellow
}



## Restore based on object type
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Configuration variables
$SiteURL="https://mysharepointsite.coms"
 
#Get Objects
$site = Get-SPSite $SiteURL
$RecycleBin = $site.RecycleBin
 
#Get All deleted Lists from Recycle bin
$DeletedItems = $RecycleBin | Where-Object{ $_.ItemType -eq "List"}
if($DeletedItems)
{
 Foreach($Item in $DeletedItems)
 {
  $Item.Restore()
  Write-Host "'$($Item.Title)' Restored from Recycle Bin!" -f DarkGreen
 }
}



## restore all items from recycle bin
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
$SiteURL="https://portal.crescent.com/sites/operations"
$Site = Get-SPSite $SiteURL
 
#Get All Recycle bin items
$DeletedItems = $Site.RecycleBin
 
If($DeletedItems)
{
    ForEach($Item in $DeletedItems)
    {
         $Site.RecycleBin.restore($Item.ID)
        Write-Host "Item restored:"$Item.Title
     }
}


## Restore all files from recyclebin, skip existing file name
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
  
#Parameter
$SiteURL="https://sharepoint.crescent.com"
 
#Get necessary objects
$Site = Get-SPSite $SiteURL
$Web = Get-SPWeb $SiteURL
$RecycleBin = $Site.RecycleBin
  
#Get deleted Items from Recycle bin - sorted by deleted date in Descending order
$DeletedItems = $RecycleBin | Where-Object {$_.ItemType -eq "File"} | Sort-Object DeletedDate -Descending
 
$DeletedItems | ForEach-Object {
    #Get the Original location of the deleted file
    $OriginalLocation = $_.DirName+"/"+$_.LeafName
 
    #Check if file exists
    If(!$Web.GetFile($OriginalLocation).Exists)
    {
        $_.Restore()
        Write-Host "$($_.LeafName) restored Successfully!" -f Green
    }
    Else
    {
        Write-Host "There is another file with the same name.. Skipping $($_.LeafName)" -f Yellow
    }
}


