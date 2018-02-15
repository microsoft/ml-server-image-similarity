
BEGIN

	DECLARE 
		@DbName VARCHAR(400) = N'$(dbName)',
		@Qry varchar(Max),
		@ServerName varchar(100) = (SELECT CAST(SERVERPROPERTY('ServerName') as Varchar)),
		@InstanceName varchar(100) = (SELECT CAST(SERVERPROPERTY('InstanceName') as Varchar)),
		@UI varchar(100)

		----Create Needed SQLRUsergroup Name , 
		----if Default Instance UI = {ServerName}\SQLRUserGroup 
		----if Named Instance {ServerName}\SQLRUserGroup{InstanceName} 
		
	If @InstanceName is null 
		BEGIN 
		SET @UI = @ServerName + '\SQLRUserGroup' 
		END 

	If @InstanceName is Not null 
		BEGIN 
		SET @UI = @ServerName + '\SQLRUserGroup' + @InstanceName
		END 


	SET @Qry = 
		(' 
		EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N''<DBName>''
		USE [master]
		ALTER DATABASE <DB> SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
		USE [master]
		DROP DATABASE <DB>
		')


	--If DB Already Exists , Drop it and recreate it 
	IF EXISTS(select * from sys.databases where name = @DbName)
	
	BEGIN 
		SET @Qry = (REPLACE(@Qry,'<DB>',@DbName) )
		EXEC (@Qry) 
	END 

	BEGIN
		SET @Qry = 'CREATE DATABASE <db> WITH FILESTREAM ( NON_TRANSACTED_ACCESS = FULL, DIRECTORY_NAME = N''FileTableData'' )'
		SET @Qry = (REPLACE(@Qry,'<DB>',@DbName) )
		EXEC (@Qry)
	END

-- Configure existing database
	BEGIN
	SET @Qry = 'ALTER DATABASE <DB> SET FILESTREAM ( NON_TRANSACTED_ACCESS = FULL, DIRECTORY_NAME = N''FileTableData'' )'
		SET @Qry = (REPLACE(@Qry,'<DB>',@DbName) )
		EXEC (@Qry)
	END
--EXEC sys.sp_configure N'filestream access level', N'2'

--RECONFIGURE WITH Override


	BEGIN
		SET @Qry = 'ALTER DATABASE <DB> ADD FILEGROUP [FileStreamFileGroup] CONTAINS FILESTREAM'
		SET @Qry = (REPLACE(@Qry,'<DB>',@DbName) )
		EXEC (@Qry)
	END

	BEGIN
	SET @Qry = 'IF NOT EXISTS (SELECT name FROM <DB>.sys.filegroups WHERE is_default=1 AND name = N''FileStreamFileGroup'') ALTER DATABASE <DB> MODIFY FILEGROUP [FileStreamFileGroup] DEFAULT'
		SET @Qry = (REPLACE(@Qry,'<DB>',@DbName) )
		EXEC (@Qry)
	END

	BEGIN
	SET @Qry = 'ALTER DATABASE <DB> ADD FILE ( NAME = N''FileStreamDBFile'', FILENAME = N''C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\FileStreamDBFile'' ) TO FILEGROUP [FileStreamFileGroup]'
		SET @Qry = (REPLACE(@Qry,'<DB>',@DbName) )
		EXEC (@Qry)
	END 

		SET @Qry = 
	'
	IF NOT EXISTS (SELECT name FROM master.sys.server_principals where name = ''<ui>'')
	BEGIN CREATE LOGIN [<ui>] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english] END
	'
	SET @Qry = REPLACE(@qry,'<ui>', @ui)
	
	EXEC (@Qry)
	--SELECT @Qry


	----Give SQLRUserGroup Rights To Database(s)
	SET @Qry = 
	'
	USE [<db>]
	CREATE USER [<ui>] FOR LOGIN [<ui>]

	ALTER USER [<ui>] WITH DEFAULT_SCHEMA=NULL

	ALTER AUTHORIZATION ON SCHEMA::[db_datareader] TO [<ui>]

	ALTER AUTHORIZATION ON SCHEMA::[db_datawriter] TO [<ui>]

	ALTER AUTHORIZATION ON SCHEMA::[db_ddladmin] TO [<ui>]

	ALTER ROLE [db_datareader] ADD MEMBER [<ui>]

	ALTER ROLE [db_datawriter] ADD MEMBER [<ui>]

	ALTER ROLE [db_ddladmin] ADD MEMBER [<ui>]
	'
	SET @Qry = REPLACE(REPLACE(@qry,'<ui>', @ui),'<db>',@DbName) 
	
	EXEC (@Qry)


END