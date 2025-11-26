$targetWebUrl = "http://mysharepointsite.com/sites/test"
$targetSpGroup  = "SP Group Name"
$userList = "C:\temp\spgroupmember.csv"

Add-Ps
Get-SPUser -Web $targetWebUrl -Group $targetSpGroup

