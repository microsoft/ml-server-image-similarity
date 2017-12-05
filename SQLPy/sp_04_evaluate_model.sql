/*
THIS SAMPLE SCRIPT USED TO EVALUATE THE MODEL USING EVALUATION IMAGE SET (FOR EACH QUERY IMAGE, IT HAS 1 POSITIVE IMAGE AND 100 NEGATIVE IMAGES)
1. LOAD PREDICTED SCORES FOR ALL THE IMAGES FROM SQL TABLE
2. LAOD EVALUATE IMAGE PAIRS FROM SQL TABLE, GET PREDICTED SCORES FOR EACH IMAGE PAIE AND THEN CALCULATE L2 AND COSINE DISTANCE 
3. CALCULATE TOP 1, 2, 4, 5, 8, 10, 15, 20, 28, 32 ACCURACY TO MEASURE THE PERFORMANCE
*/
/*
PARAMETERS:
@scores_table: CONTAINS CLASSIFIERS' PREDICTED SCORES FOR ALL THE IMAGES. CREATED IN THE THIRD STEP
@evaluation_table: CONTAINS EVALUATION IMAGE PAIRS, CREATED IN THE SECOND STEP
@dbName: DATABASE NAME
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[EvaluateModel];
GO

--EXEC [dbo].[EvaluateModel] 'scores', 'evaluation_images'
CREATE OR ALTER PROCEDURE [dbo].[EvaluateModel]
(
	@scores_table nvarchar(20),     --sql table saved predicted scores of all the images created in step3
	@evaluation_table nvarchar(20)  --sql table saved evaluation image pairs created in step2
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @server_name varchar(max) = @@servername;
	DECLARE @database_name varchar(max) = db_name();
	DECLARE @PythonSQLScript NVARCHAR(MAX) = CONCAT(N'

from revoscalepy import RxSqlServerData, rx_import
from image_similarity.image_similarity_utils import calculate_ranking_metrics, load_predicted_scores

print("------------------------------------------------------------------------")
distMethods = ["L2", "cosine"]
# Load classifier output for all images in testing set
print("Getting predictes scores for all the images...")
conn_str = "DRIVER={SQL Server};SERVER=', @server_name, ';PORT=1433;DATABASE=', @database_name, ';TRUSTED_CONNECTION=True"
image_scores = load_predicted_scores(conn_str, "', @scores_table, '")

print("Loading image pairs...")
imagePairQuery = "SELECT * FROM ', @evaluation_table, '"
imagePairData_sql = RxSqlServerData(connection_string=conn_str, sql_query=imagePairQuery, strings_as_factors=False)
imagePairData = rx_import(imagePairData_sql)

print("Calculating ranking metrics...")
calculate_ranking_metrics(image_scores, imagePairData, distMethods)
print("DONE.")
print("------------------------------------------------------------------------")
');
	EXECUTE sp_execute_external_script
		@language = N'python',
		@script = @PythonSQLScript,
		@params = N'@database_name varchar(max), @server_name varchar(max)',
		@database_name = @database_name,
		@server_name = @server_name;

END
GO