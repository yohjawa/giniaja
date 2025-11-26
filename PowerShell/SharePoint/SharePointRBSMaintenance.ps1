USE [ConentDatabase]
GO
exec mssqlrbs.rbs_sp_set_config_value 'garbage_collection_time_window', 'time 00:00:00';
exec mssqlrbs.rbs_sp_set_config_value 'delete_scan_period', 'time 00:00:00';
exec mssqlrbs.rbs_sp_set_config_value 'orphan_scan_period', 'time 00:00:00';
GO

## C:\Program Files\Microsoft SQL Remote Blob Storage 13.0\Maintainer\Microsoft.Data.SqlRemoteBlobs.Maintainer.exe
Microsoft.Data.SqlRemoteBlobs.Maintainer.exe -connectionstringname RBSMaintainerConnection -operation GarbageCollection ConsistencyCheck ConsistencyCheckForStores -GarbageCollectionPhases rdo -ConsistencyCheckMode r -TimeLimit 120


USE [ConentDatabase]
GO
CHECKPOINT;
GO
EXEC sp_filestream_force_garbage_collection @dbname = N'Content Database';
GO
