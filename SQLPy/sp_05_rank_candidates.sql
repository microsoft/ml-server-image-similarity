/*
THIS SAMPLE SCRIPT MAINLY SERVERS FOUR PURPOSES:
1. LOAD CLASSIFIER'S PREDICTED SCORES FOR ALL THE CANDIDATE IMAGES FROM SCORES TABLE
2. LOAD QUERY IMAGES FROM QUERY IMAGE TABLE, AND FEATURIZE QUERY IMAGES USING PRE-TRAINED DNN MODEL
3. LOAD THE CLASSIFIER FROM MODEL TABLE, AND CALCULATE THE PREDICTED SCORES FOR QUERY IMAGES
4. CALCULATE THE COSINE DISTANCE BETWEEN QUERY IMAGE AND CANDIDATE IMAGES, RANK THE CANDIDATES FOR EACH QUERY IMAGE, AND RETURN THE TOP K SIMILAR IMAGES BACK
WE ASSUME ALL THE QUERY IAMGES ARE ALREADY IN SQL TABLE AND THE PREDICTED SCORES FOR ALL THE CANDIDATES WERE PRE-CALCULATED AND SAVED IN SQL TABLE
*/
/*
PARAMETERS:
@topKCandidates: THE NUMBER OF SIMILAR IMAGES WHICH SHOULD BE RETURNED FOR EACH QUERY IMAGE
@query_table: CONTAINS ALL THE QUERY IMAGES
@scores_table: CONTAINS PREDICTED SCORES FOR ALL THE CANDIDATE IMAGES
@model_table: CONTAINS THE CLASSIFIER
@results_table: USED TO SAVE THE RANKING RESULTS FOR EACH QUERY IMAGE
@dbName: DATABASE NAME
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[RankCandidates];
GO

--EXEC [dbo].[RankCandidates] 10, 'query_images', 'scores', 'model', 'ranking_results'
CREATE OR ALTER PROCEDURE [dbo].[RankCandidates]
(
	@topKCandidates int,
	@query_table nvarchar(20),   --sql table saved the query images
	@scores_table nvarchar(20),   --sql table saved predicted scores for all the images
	@model_table nvarchar(20),    --sql table saved the model
	@results_table nvarchar(20)  --sql table used to save ranking results
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @server_name varchar(max) = @@servername;
	DECLARE @database_name varchar(max) = db_name();
	DECLARE @PythonSQLScript NVARCHAR(MAX) = CONCAT(N'

from revoscalepy import RxSqlServerData, rx_data_step
from microsoftml import rx_predict
from image_similarity.image_similarity_utils import load_model, featurize_transform, load_predicted_scores, map_images_to_predictedscores, rank_candiate_images

print("------------------------------------------------------------------------")
print("Loading the classifier output for all the candidate images...")
conn_str = "DRIVER={SQL Server};SERVER=', @server_name, ';PORT=1433;DATABASE=', @database_name, ';TRUSTED_CONNECTION=True"
candidateImage_scores = load_predicted_scores(conn_str, "', @scores_table, '")

print("Loading query images...")
queryImagesSql = "SELECT * FROM ', @query_table, '"
queryImages = RxSqlServerData(connection_string=conn_str, sql_query=queryImagesSql, strings_as_factors=False)

print("Featurizing query images...")
query_image_features = rx_data_step(input_data=queryImages, overwrite=True,
                                    transform_function=featurize_transform, report_progress=2)

print("Loading classifier...")
classifier = load_model("', @model_table, '", conn_str, "rx_neural_net")

print("Getting classifier output for query images...")
queryImageScores = rx_predict(classifier, query_image_features, extra_vars_to_write=["image", "Label"])
queryImageVector = map_images_to_predictedscores(queryImageScores)

print("Calculating cosine similarity between each image pair...")
rank_candiate_images(conn_str, queryImageVector, candidateImage_scores, ', @topKcandidates, ', "', @results_table, '")
print("DONE.")
print("---------------------------------------------------------------")
')
	EXECUTE sp_execute_external_script
		@language = N'python',
		@script = @PythonSQLScript,
		@params = N'@database_name varchar(max), @server_name varchar(max)',
		@database_name = @database_name,
		@server_name = @server_name;
END
GO