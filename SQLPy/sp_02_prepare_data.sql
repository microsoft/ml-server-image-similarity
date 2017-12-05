/*
THIS SAMPLE SCRIPT MAINLY SERVERS TWO PURPOSES:
1. RANDOMLY SELECT TRAINING IMAGES AND TESTING IMAGES FROM THE FEATUE TABLE BASED ON IMAGE'S CATEGORY AND TRAIN/TEST RATIO, AND THEN SAVE THEM INTO TRAINING/TESTING TABLE
2. BASED ON TESTING TABLE, GENERATE EVALUATION SET WHICH CONTAINS QUERY IMAGES AND CANDIDATES FOR EACH QUERY IMAGE BASED ON TWO PARAMETERS (NUMBER OF QUERY IMAGES 
IN EACH CATEGORY, AND THE NUMBER OF NEGATIVE IMAGES FOR EACH QUERY IMAGE), AND THEN SAVE THE EVALUATION SET INTO EVALUATION TABLE
*/
/*
PARAMETERS:
@feature_table:	CREATED IN THE FIRST STEP, CONTAINS IMAGES PATH, LABEL AND DNN FEATURES
@train_table: USED TO SAVE TRAINING IMAGES' PATH
@test_table:  USED TO SAVE TESTING IMAGES' PATH
@evaluation_table: USED TO SAVE EVALUATION IMAGE PAIRS (QUERY IMAGES AND THEIR POSITIVE/NEGATIVE CANDIDATES)
@dbName: DATABASE NAME
@ratioTrainTest: TRAIN/TEST RATIO, USED TO SELECT HOW MANY TRAINING IMAGES AND TESTING IMAGES
@queryImagePerCat: THE NUMBER OF QUERY IMAGES WHICH SHOULD BE SELECTED FROM EACH CATEGORY
@negImgsPerQUeryImg: THE NUMBER OF NEGATIVE CANDIDATES FOR EACH QUERY IMAGE
USERS JUST NEED TO INPUT THE NAME FOR THE TABLES, DO NOT NEED TO CREATE THEM IN ADVANCE
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[PrepareData];
GO

--EXEC [dbo].[PrepareData] 'features', 'training_images', 'testing_images', 'evaluation_images', 0.75, 20, 100
CREATE OR ALTER PROCEDURE [dbo].[PrepareData]
(
	@feature_table nvarchar(20),     --sql table saved images path and DNN features, the name should be same as the one used in step1
	@train_table nvarchar(20),       --sql table used to save training images' path
	@test_table nvarchar(20),        --sql table used to save testing images' path
	@evaluation_table nvarchar(20),  --sql table used to save evaluation image pairs
	@ratioTrainTest float,           --train/test ratio
	@queryImagePerCat int,           --number of query images in each category
	@negImgsPerQueryImg int          --number of negative images for each query image
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @server_name varchar(max) = @@servername;
	DECLARE @database_name varchar(max) = db_name();
	DECLARE @batchImages nvarchar(max)  -- contain image path and label
	SET @batchImages = 
		CONCAT(N'SELECT image, Label FROM ', @feature_table);

	DECLARE @PythonSQLScript NVARCHAR(MAX) = CONCAT(N'

from revoscalepy import RxSqlServerData, rx_import
from image_similarity.image_similarity_utils import get_training_testing_images, prepare_evaluation_set

print("-------------------------------------------------")
conn_str = "DRIVER={SQL Server};SERVER=', @server_name, ';PORT=1433;DATABASE=', @database_name, ';TRUSTED_CONNECTION=True"
image_data = InputDataSet
print("Split image data into training and testing set...")
get_training_testing_images(image_data, ', @ratioTrainTest, ', "', @train_table, '", "', @test_table, '", conn_str)
print("Getting ranking set from the testing image set...")
prepare_evaluation_set(conn_str, "', @feature_table, '", "', @test_table, '", "', @evaluation_table, '", ', @queryImagePerCat, ', ', @negImgsPerQueryImg, ')
print("DONE.")
print("-------------------------------------------------")
');

	EXECUTE sp_execute_external_script
		@language = N'python',
		@script = @PythonSQLScript,
		@input_data_1 = @batchImages,
		@params = N'@database_name varchar(max), @server_name varchar(max)',
		@database_name = @database_name,
		@server_name = @server_name;

END
GO