Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Custom Function to Copy Files from Source Folder to Target
Function Copy-Files($SourceFolder, $TargetFolder)
{
    write-host "Copying Files from:$($SourceFolder.URL) to $($TargetFolder.URL)"
    #Get Each File from the Source
    $SourceFilesColl = $SourceFolder.Files
 
    #Iterate through each item from the source
    Foreach($SourceFile in $SourceFilesColl)
    {
        #Copy File from the Source
        $NewFile = $TargetFolder.Files.Add($SourceFile.Name, $SourceFile.OpenBinary(),$True)
  
        #Copy Meta-Data from Source
        Foreach($Field in $SourceFile.Item.Fields)
        {
            If(!$Field.ReadOnlyField)
            {
                if($NewFile.Item.Fields.ContainsField($Field.InternalName))
                {
                    $NewFile.Item[$Field.InternalName] = $SourceFile.Item[$Field.InternalName]
                }
            }
        }
        #Update
        $NewFile.Item.UpdateOverwriteVersion()
     
        Write-host "Copied File:"$SourceFile.Name
    }
     
    #Process SubFolders
    Foreach($SubFolder in $SourceFolder.SubFolders)
    {
        if($SubFolder.Name -ne "Forms")
        {
            #Check if Sub-Folder exists in the Target Library!
            $NewTargetFolder = $TargetFolder.ParentWeb.GetFolder($SubFolder.Name)
  
            if ($NewTargetFolder.Exists -eq $false)
            {
                #Create a Folder
                $NewTargetFolder = $TargetFolder.SubFolders.Add($SubFolder.Name)
            }
            #Call the function recursively
            Copy-Files $SubFolder $NewTargetFolder
        }
    }
}
 
#Variables for Processing
$sWebURL="http://mysharepointsite.com/sites/test1"
$SourceLibrary ="ShareDrive/Jodo"

$tWebUrl = "http://mysharepointsite.com/sites/test2/"
$TargetLibrary = "Shared Documents"
 
#Get Objects
$sWeb = Get-SPWeb $sWebURL
$dWeb = Get-SPWeb $tWebURL

$SourceFolder = $sWeb.GetFolder($SourceLibrary)
$TargetFolder = $dWeb.GetFolder($TargetLibrary)
 
#Call the Function to Copy All Files
Copy-Files $SourceFolder $TargetFolder


