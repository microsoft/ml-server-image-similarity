SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[CreateTables];
GO

--EXEC [dbo].[CreateTables]
CREATE OR ALTER PROCEDURE [dbo].[CreateTables]
AS
BEGIN
	--create FileTable table
	DROP TABLE IF EXISTS [dbo].[ImageStore]
	CREATE TABLE [dbo].[ImageStore] AS FileTable
	WITH (
		FileTable_Directory = 'ImageStore',
		FileTable_Collate_Filename = database_default
	);
END
GO

