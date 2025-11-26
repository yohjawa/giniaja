#Configuration variables
$srcWeb = "http://mysharepointsite.com/sites/test1"
$dstWeb = "http://mysharepointsite.com/sites/test2"
$ListName = "List Name"

#Get Objects
$sweb = Get-SPWeb $srcWeb
$dweb = Get-SPWeb $dstWeb

$SourceList = $sweb.Lists[$ListName]
$TargetList = $dweb.Lists[$ListName]
 
#Get all source items
$SourceColumns = $sourceList.Fields
$SourceItems = $SourceList.GetItems();

#Iterate through each item and add to target list
Foreach($SourceItem in $SourceItems)
{
    $TargetItem = $TargetList.AddItem()
    Foreach($column in $SourceColumns) 
    {
        if($column.ReadOnlyField -eq $False -and $column.InternalName -ne "Attachments")
        {
             $TargetItem[$($column.InternalName)] = $sourceItem[$($column.InternalName)];
        }
    }
    $TargetItem.Update()
 
    #Copy Attachments
    Foreach($Attachment in $SourceItem.Attachments)
    {
        $spFile = $SourceList.ParentWeb.GetFile($SourceItem.Attachments.UrlPrefix + $Attachment)
        $TargetItem.Attachments.Add($Attachment, $spFile.OpenBinary())
    }
}
