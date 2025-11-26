Add-PSSnapin Microsoft.SharePoint.PowerShell

## Create new web application if not exist yet
$ap = New-SPAuthenticationProvider
$appName = "App Name"
$appPort = 80
$appPool = "ApplicationPoolName"
$poolUsr = "DOMAIN\username"
$dbServer = "DBSERVER\DBINSTANCE"
$dbName = "ContentDB"
$vDir = "C:\SPVirtualDir\80"



New-SPWebApplication `
    -Name $appName `
    -Port $appPort `
    -ApplicationPool $appPool `
    -ApplicationPoolAccount (Get-SPManagedAccount $poolUsr) `
    -AuthenticationProvider $ap `
    -DatabaseServer $dbServer `
    -DatabaseName $dbName `
    -Path $vDir

## Unmount content database from web application

Get-SPContentDatabase -WebApplication "http://mysharepointsite.com/" | Dismount-SPContentDatabase

## Backup content database from old server
## Restore to new server replace the previous unmounted content database
## mount the content database back

Mount-SPContentDatabase "ContentDB" -DatabaseServer "DBSERVER\DBINSTANCE" -WebApplication "http://mysharepointsite.com/" -AssignNewDatabaseId
Test-SPContentDatabase "ContentDB"
Upgrade-SPContentDatabase "ContentDB"

## migrate sharepoint farm solutions
## backup wsp sharepoint solution
$FolderPath = "D:\WSP\Backup"
foreach ($solution in Get-SPSolution)
{
$id = $Solution.SolutionID
$title = $Solution.Name
$filename = $Solution.SolutionFile.Name
$solution.SolutionFile.SaveAs("$FolderPath\$filename")
}

## copy all wsp files to destination farm then run the following
Add-SPSolution -LiteralPath "D:\WSP\Backup\plumsail.crosssitelookup.wsp"
Add-SPSolution -LiteralPath "D:\WSP\Backup\plumsail.dashboarddesigner.wsp"
Add-SPSolution -LiteralPath "D:\WSP\Backup\plumsail.formsdesigner2013.wsp"
Add-SPSolution -LiteralPath "D:\WSP\Backup\plumsail.helpdesk.sp2013.wsp"
Add-SPSolution -LiteralPath "D:\WSP\Backup\plumsail.orgchart.wsp"
Add-SPSolution -LiteralPath "D:\WSP\Backup\plumsail.wfscheduler.wsp"

## to remove a web application
Remove-SPWebApplication http://mysharepointsite.com:5240/ -RemoveContentDatabases -DeleteIISSite