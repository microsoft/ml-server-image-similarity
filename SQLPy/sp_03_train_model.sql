/*
THIS SAMPLE SCRIPT MAINLY SERVERS FOUR PURPOSES:
1. GET DNN FEATURES CALCULATED IN THE FIRST STEP FOR TRAINING AND TESTING IMAGES, AND TRAIN A MULTI-CLASS CLASSIFIER USING RX_NEURAL_NETWORK
2. EVALUATE THE ACCURACY OF THE CLASSIFIER USING THE TESTING IMAGES
3. SAVE THE PREDICTED SCORES CALCULATED BY THE CLASSIFIER OF ALL THE IMAGES INTO SQL SCORES TABLE,
4. SAVE THE MODEL INTO SQL MODEL TABLE 
*/
/*
PARAMETERS:
@feature_table: CONTAIN IMAGES PATH, LABEL AND DNN FEATURES. CREATED IN THE FIRST STEP
@train_table: CONTAINS TRAINING IMAGES PATH, CREATED IN THE SECOND STEP
@test_table: CONTAINS TESTING IMAGES PATH, CREATED IN THE SECOND STEP
@scores_table: USED TO SAVE THE CLASSIFIER'S PREDICTED SCORES FOR ALL THE IMAGES
@model_table: USED TO SAVE THE CLASSIFIER
@dbName: DATABASE NAME
*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[TrainClassifier];
GO

--EXEC [dbo].[TrainClassifier] 'features', 'training_images', 'testing_images', 'scores', 'model'
CREATE OR ALTER PROCEDURE [dbo].[TrainClassifier]
(
	@feature_table nvarchar(20),   --sql table saved images' DNN features and labels
	@train_table nvarchar(20),     --sql table saved training images and created in step2
	@test_table nvarchar(20),      --sql table saved testing images and created in step2
	@scores_table nvarchar(20),    --sql table to save the predicted scores of all the images
	@model_table nvarchar(20)     --sql table to save the model
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @server_name varchar(max) = @@servername;
	DECLARE @database_name varchar(max) = db_name();
	DECLARE @PythonSQLScript NVARCHAR(MAX) = CONCAT(N'

from revoscalepy import RxSqlServerData, rx_data_step, RxOdbcData, rx_get_var_names
from microsoftml import rx_neural_network, sgd_optimizer, rx_predict, concat
from image_similarity.image_similarity_utils import get_label_levels, save_model, generate_model_formula
import pandas as pd

print("------------------------------------------------------------------------")
print("Training classifier...")
conn_str = "DRIVER={SQL Server};SERVER=', @server_name, ';PORT=1433;DATABASE=', @database_name, ';TRUSTED_CONNECTION=True"
levels = get_label_levels("', @feature_table, '", conn_str)   #get levels of Label
colInfo = {"Label": {"type": "factor", "levels": levels}}
train_query = "SELECT * FROM {} WHERE image IN (SELECT image FROM {})".format("', @feature_table, '", "', @train_table, '")
train_data = RxSqlServerData(sql_query=train_query, connection_string=conn_str, column_info=colInfo)

test_query = "SELECT * FROM {} WHERE image IN (SELECT image FROM {})".format("', @feature_table, '", "', @test_table, '")
test_data = RxSqlServerData(sql_query=test_query, connection_string=conn_str, column_info=colInfo)

#formula = generate_model_formula(train_data)
features_all = rx_get_var_names(train_data)
featureSet = ["feature." + str(i) for i in range(len(features_all) - 2)]
label = "Label"
cols = featureSet + [label]

print("Start training...")
classifier = rx_neural_network("Label ~ feature", data=train_data, method="multiClass",
								 optimizer=sgd_optimizer(learning_rate=0.011,
													 l_rate_red_ratio=0.9,
													 l_rate_red_freq=3,
													 momentum=0.2),
								 num_iterations=300,
								 ml_transforms=[concat(cols={"feature": featureSet})])

print("Evaluating model...")
test_score = rx_predict(classifier, test_data, extra_vars_to_write=["image", "Label"])
train_score = rx_predict(classifier, train_data, extra_vars_to_write=["image", "Label"])
testACC = float(len(test_score[test_score["Label"] == test_score["PredictedLabel"]]))/len(test_score)
trainACC = float(len(train_score[train_score["Label"] == train_score["PredictedLabel"]]))/len(train_score)
print("The train accuracy of the neural network model is {}".format(trainACC))
print("The test accuracy of the neural network model is {}".format(testACC))

print("Saving the predictive results of all the images into SQL table...")
outputScore = RxSqlServerData(connection_string=conn_str, table="', @scores_table, '")
rx_data_step(pd.concat([test_score, train_score]), outputScore, overwrite=True)
print("Saving model into SQL table...")
save_model("', @model_table, '", conn_str, classifier, "rx_neural_net")
print("DONE")
print("------------------------------------------------------------------------")
');

	EXEC sp_execute_external_script 
		@language = N'python',
		@script = @PythonSQLScript,
		@params = N'@database_name varchar(max), @server_name varchar(max)',
		@database_name = @database_name,
		@server_name = @server_name;
END;
GO