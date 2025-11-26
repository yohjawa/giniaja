SELECT 
	mf.name as logical_name,
	dbs.name as database_name,
	CASE mf.type
		WHEN 0 THEN 'Data File'
		WHEN 1 THEN 'Log File'
	END AS file_type,
	mf.physical_name as physical_location,
	(mf.size*8)/1024 AS allocated_size_mb
FROM sys.master_files mf
JOIN sys.databases dbs ON dbs.database_id = mf.database_id
WHERE dbs.database_id > 4
ORDER BY dbs.name


select
	db.name as database_name,
	CASE mf.type
		WHEN 0 THEN 'Data File'
		WHEN 1 THEN 'Log File'
	END AS file_type,
	sum((mf.size*8)/1024) as allocated_sie
from sys.master_files mf
	join sys.databases db on db.database_id = mf.database_id
where db.database_id > 4
group by db.name, mf.type
order by db.name