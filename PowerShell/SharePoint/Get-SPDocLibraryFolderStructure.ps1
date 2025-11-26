
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Function to get all files of a folder
Function GetFiles-ByFolder([Microsoft.SharePoint.SPFolder]$Folder)
{
    write-host -f Yellow "Processing Folder:"$Folder.URL
    Foreach($File in $Folder.Files)
    {
        $Content = $Folder.Name + "," + $Folder.URL +"," + $File.Name
        #Append content to CSV file
        Add-content $OutPutFile $Content
        Write-host $Content
    }
     
    #Call the function for each subfolder - Excluding "Forms"
    $Folder.SubFolders | Where {$_.Name -ne "Forms" } | Foreach-Object {
    GetFiles-ByFolder $_
    }
}
  
#Variables
$SiteURL = "http://mysharepointsite.com"
$ListName ="E-ARCHIVES"
$OutPutFile = "D:\Tmp\LsFolders\eArchive.csv"
 
#Delete the CSV file if exists
If (Test-Path $OutPutFile) { Remove-Item $OutPutFile }
 
#Write CSV headers
Add-Content $OutPutFile "Folder Name, Relative URL, File Name"
 
#Get site and list objects
$Web = Get-SPWeb $SiteURL
$List = $Web.Lists[$ListName]
$Folder = $List.RootFolder
 
#Call the function for Root folder
GetFiles-ByFolder $Folder

