$web = Get-SPWeb "http://mysharepointsite.com/sites/test/test1"

# Grab the folder by server-relative url
$folder = $web.GetFileOrFolderObject("/sites/test/test1/Shared Documents/folder1/folder2")

# Destination folder must not exist because MoveTo will create it
$folder.MoveTo("/sites/test/test1/Shared Documents/folder1")
$web.Dispose()