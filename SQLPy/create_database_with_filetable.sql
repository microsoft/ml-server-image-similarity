-- This sample used to create a database with FILESTREAM enabled
-- You can define DIRECTORY_NAME as any name what you want

-- Conigure new database  
CREATE DATABASE ImageSimilarity
WITH FILESTREAM ( NON_TRANSACTED_ACCESS = FULL, DIRECTORY_NAME = N'FileTableData' )


-- Configure existing database
ALTER DATABASE ImageSimilarity
SET FILESTREAM ( NON_TRANSACTED_ACCESS = FULL, DIRECTORY_NAME = N'FileTableData' )



