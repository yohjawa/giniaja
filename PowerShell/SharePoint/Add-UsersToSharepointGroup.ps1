$targetWebUrl = "http://phmsp-edms.pertamina.com/sites/prj"
$targetSpGroup  = "PRJ Collaboration Workspace Members"
$userList = "C:\DRV\DBA\Scripts\PowerShell\rsdev.csv"

Add-Ps
Get-SPUser -Web $targetWebUrl -Group $targetSpGroup

