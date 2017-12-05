/*
THIS SAMPLE SCRIPT IS USED TO GET IMAGES' PATH FROM FILETABLE, AND MAPPING A LABEL TO EACH IMAGE BASED ON THE CATEGORY INFORMATION. THEN FEATURIZED IMAGES USING PRE-TRAINED DNN
MODEL, SUCH AS RESNET18 AND RESNET50. FINALLY, SAVE THE IMAGES PATH, LABELS DNN FEATURES INTO SQL TABLE
*/
/*
PARAMETERS: 
@image_table: FILETABLE WHICH STORES THE IMAGES, WE ASSUME THE IMAGES ARE ALREADY IN THE FILETABLE BEFORE WE RUN THIS STORED PROCEDURE
@feature_table: SQL TABLE WHICH IS USED TO SAVE IMAGES PATH, LABELS AND DNN FEATURES
@dbName: database name
USERS DO NOT NEED TO DEFINE AND CREATE THESE TWO TABLES, JUST GIVE A NAME YOU WANT FOR EACH TABLE, THE PROGRAM WILL CREATE THESE TWO TABLE AUTOMATICALLY
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[FeaturizeImages];
GO

--EXEC [dbo].[FeaturizeImages] 'ImageStore', 'features'
CREATE OR ALTER PROCEDURE [dbo].[FeaturizeImages]
(
	@image_table nvarchar(20), --FileTable
	@feature_table nvarchar(20)
)	
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @server_name varchar(max) = @@servername;
	DECLARE @database_name varchar(max) = db_name();
	DECLARE @root nvarchar(max) = FileTableRootPath();
	DECLARE @batchImagesPath nvarchar(max)  --get the path of all the images in FileTable
	SET @batchImagesPath = 
		CONCAT(N'SELECT (''' + @root + ''' + [file_stream].GetFileNamespacePath()) as image FROM ', @image_table, ' WHERE [is_directory] = 0');
		
	DECLARE @PythonSQLScript NVARCHAR(MAX) = CONCAT(N'

from image_similarity.image_similarity_utils import get_image_path, map_category_to_label, get_image_label, compute_features

print("---------------------------------------------------------------------------")
print("Featurize images using pre-trained DNN model...")
conn_str = "DRIVER={SQL Server};SERVER=', @server_name, ';PORT=1433;DATABASE=', @database_name, ';TRUSTED_CONNECTION=True"
# get the input data set which contains the path of all the images
imageData = InputDataSet
#get the distinct category of all the images, and them map them to factor labels
lutLabel2Id = map_category_to_label("', @image_table, '", conn_str)
# map "label" for each image
imageData["Label"] = imageData["image"].map(lambda x: get_image_label(x, lutLabel2Id))
#compute DNN features for all the images, and save into SQL table
compute_features(imageData, "', @feature_table, '", conn_str)
print("DONE.")
print("---------------------------------------------------------------------------")
');
	EXECUTE sp_execute_external_script
		@language = N'python',
		@script = @PythonSQLScript,
		@input_data_1 = @batchImagesPath,
		@params = N'@database_name varchar(max), @server_name varchar(max)',
		@database_name = @database_name,
		@server_name = @server_name;

END
GO