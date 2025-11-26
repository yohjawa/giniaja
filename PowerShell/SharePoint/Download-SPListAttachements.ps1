#Site URL and List Name variables
$WebURL = "http://mysharepointsite.com/sites/test/test1"
$LibraryName = "PM Task List"  
 
#Local folder to which attachments to be downloaded
$DownloadPath = "\\sf01\download\path"    
 
#Get the web
$Web = Get-SPWeb $WebURL
#Get the Library
$List = $Web.Lists[$LibraryName]    
 
#Loop through each List item
foreach ($ListItem in $List.Items)
{
    #Set path to save attachment
    $DestinationFolder = $DownloadPath + "\" + $ListItem.ID
 
    #Check if folder exists already. If not, create the folder
    if (!(Test-Path -path $DestinationFolder))
    {
        New-Item $DestinationFolder -type directory
    }

    #Get all attachments
    $AttachmentsColl = $ListItem.Attachments
 
    #Loop through each attachment
    foreach ($Attachment in $AttachmentsColl)
    {
        #Get the attachment File
        $file = $web.GetFile($listItem.Attachments.UrlPrefix + $Attachment)
        $bytes = $file.OpenBinary()
 
        #Save the attachment as a file
        $FilePath = $DestinationFolder + "\" + $Attachment
        $fs = new-object System.IO.FileStream($FilePath, "OpenOrCreate")
        $fs.Write($bytes, 0 , $bytes.Length)
        $fs.Close()
    }
}