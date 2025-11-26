## 1. Configure hostname alias for new instnce
##      - cliconfg.exe
##      - Tab Alias -- Add
##      - TCP
##      - Server Alias : Type the old Instance Name
##      - Server Name : Type the new instance name you want to repoint sharepoint database to
## 2. Point the SharePoint databases to the new SQL alias
##
$SPDBs = Get-SPDatabase  
 ForEach ($DB in $SPDBs)  
 {  
     $DB.ChangeDatabaseInstance('DBSERVER\DBINSTANCE')  
 }
 ## 3. Verify the changes
 Get-SPDatabase | Select-Object Name,Server

 ## 4. Point the default database instance for the web applications to the new SQL Server instance
 $ConfigDB = Get-SPDatabase | Where-Object {$_.Name -eq 'SharePoint_Config'}
 $WebApps = Get-SPWebApplication -IncludeCentralAdministration  
 ForEach ($WebApp in $WebApps)  
 {  
     $WebApp.Parent.DefaultDatabaseInstance = $ConfigDB.ServiceInstance  
     $webapp.Parent.Update()  
     $webapp.Update()  
 }

 ## 5. Verify the changes
 $webapps = Get-SPWebApplication -IncludeCentralAdministration  
 foreach ($webapp in $webapps)  
 {  
     Write-host "WebAppUrl: $($webapp.DisplayName)`tDefaultDatabaseInstance: $($webapp.Parent.DefaultDatabaseInstance.DisplayName)"  
 }

## 6. Change the Distributed Cache cluster configuration
#SELECT [ID],[Properties]  
#FROM [SharePoint_Config].[dbo].[Objects]  
#WITH (NOLOCK)  
#WHERE Properties like '%_cacheConfigStorageLocation%'
## Copy the result
## <object type="Microsoft.SharePoint.DistributedCaching.Utilities.SPDistributedCacheClusterInfo, Microsoft.SharePoint, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"><fld type="Microsoft.SharePoint.DistributedCaching.Utilities.SPDistributedCacheClusterConfigStorageLocation, Microsoft.SharePoint, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" name="_cacheConfigStorageLocation"><object type="Microsoft.SharePoint.DistributedCaching.Utilities.SPDistributedCacheClusterConfigStorageLocation, Microsoft.SharePoint, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"><sFld type="String" name="_provider">SPDistributedCacheClusterProvider</sFld><sFld type="String" name="_connectionString">Data Source=DBSERVER\DBINSTANCE;Initial Catalog=SharePoint_Config;Integrated Security=True;Enlist=False</sFld></object></fld><sFld type="String" name="_clusterSize">medium</sFld><sFld type="Boolean" name="_enableHA">False</sFld><sFld type="Boolean" name="_isInitialized">True</sFld><fld type="System.Collections.Hashtable, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" name="m_UpgradedPersistedFields" /><fld name="m_Properties" type="null" /><sFld type="String" name="m_LastUpdatedUser">DOMAIN\spadmin</sFld><sFld type="String" name="m_LastUpdatedProcess">psconfigui (68)</sFld><sFld type="String" name="m_LastUpdatedMachine">SPSERVER</sFld><sFld type="DateTime" name="m_LastUpdatedTime">2013-08-06T20:48:48</sFld></object>
## Change the following part to new sql server instance
## Data Source=DBSERVER\DBINSTANCE;Initial Catalog=SharePoint_Config;
## Update the record back

#UPDATE dbo.Objects  
#SET Properties = '<object type="Microsoft.SharePoint.DistributedCaching.Utilities.SPDistributedCacheClusterInfo, Microsoft.SharePoint, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"><fld type="Microsoft.SharePoint.DistributedCaching.Utilities.SPDistributedCacheClusterConfigStorageLocation, Microsoft.SharePoint, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c" name="_cacheConfigStorageLocation"><object type="Microsoft.SharePoint.DistributedCaching.Utilities.SPDistributedCacheClusterConfigStorageLocation, Microsoft.SharePoint, Version=15.0.0.0, Culture=neutral, PublicKeyToken=71e9bce111e9429c"><sFld type="String" name="_provider">SPDistributedCacheClusterProvider</sFld><sFld type="String" name="_connectionString">Data Source=DBSERVER\DBINSTANCE;Initial Catalog=SharePoint_Config;Integrated Security=True;Enlist=False</sFld></object></fld><sFld type="String" name="_clusterSize">medium</sFld><sFld type="Boolean" name="_enableHA">False</sFld><sFld type="Boolean" name="_isInitialized">True</sFld><fld type="System.Collections.Hashtable, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089" name="m_UpgradedPersistedFields" /><fld name="m_Properties" type="null" /><sFld type="String" name="m_LastUpdatedUser">DOMAIN\spadmin</sFld><sFld type="String" name="m_LastUpdatedProcess">psconfigui (68)</sFld><sFld type="String" name="m_LastUpdatedMachine">SPSERVER</sFld><sFld type="DateTime" name="m_LastUpdatedTime">2013-08-06T20:48:48</sFld></object>'  
#WHERE ID = '[GUID of the configuration object in the query result]'


## skip the following if distributed cache is disabled
## Reprovision the Distributed Cache service on all Distributed Cache servers
## On one of the Distributed Cache servers, gracefully shut down the service by running the following PowerShell cmdlet in an elevated PowerShell prompt:
Use-CacheCluster  
Stop-CacheHost -Graceful -CachePort 22233 -ComputerName $env:COMPUTERNAME  

## Wait until the service is stopped. You can monitor the status by using the following PowerShell cmdlet:
Get-CacheHost 

## Remove the local server from the Distributed Cache cluster by running the following PowerShell cmdlet:
Remove-SPDistributedCacheServiceInstance  


## Restore the local server to the Distributed Cache cluster by running the following PowerShell cmdlet:
Add-SPDistributedCacheServiceInstance  

## Open Registry Editor, and then verify that the ConnectionString value of the 
## HKLM\SOFTWARE\Microsoft\AppFabric\V1.0\Configuration key is updated.

## Remove reference to the old server
$OldServer = Get-SPServer | Where-Object{$_.Address -eq 'VICOVMS02'}
$OldServer.Delete()

## Verify the changes
Get-SPServer