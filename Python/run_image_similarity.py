from image_similarity.image_similarity_utils import *
from microsoftml import rx_neural_network, sgd_optimizer, rx_predict, concat
import pandas as pd
from revoscalepy import RxSqlServerData, rx_data_step, rx_import
from parameters import *

#featurize images using pre-trained DNN model
def featurize_images(conn_str, image_table, feature_table):
    imageData = get_image_path(TABLE_IMAGES, conn_str)
    lutLabel2Id = map_category_to_label(image_table, conn_str)
    imageData["Label"] = imageData["image"].map(lambda x: get_image_label(x, lutLabel2Id))
    compute_features(imageData, feature_table, conn_str)

#prepare training/testing/evaluation image set
def prepare_data(conn_str, feature_table, train_table, test_table, evaluation_table, numQueryImagePerCat, numNegImgsPerQueryImg, ratioTrainTest):
    image_data_sql = RxSqlServerData(connection_string=conn_str, sql_query="SELECT image, Label FROM " + feature_table,
                                     string_as_factors=False)
    image_data_df = rx_import(image_data_sql)
    print("Split image data into training and testing set...")
    get_training_testing_images(image_data_df, ratioTrainTest, train_table, test_table, conn_str)
    print("Getting ranking set from the testing image set...")
    prepare_evaluation_set(conn_str, feature_table, test_table, evaluation_table, numQueryImagePerCat, numNegImgsPerQueryImg)

#Train a mul-class classifier, and save the model into SQL table
def train_classifier(conn_str, feature_table, training_table, testing_table, score_table, model_table, DNNDimension):
    levels = get_label_levels(feature_table, conn_str)  # get levels of Label
    colInfo = {"Label": {"type": "factor", "levels": levels}}
    train_query = "SELECT * FROM {} WHERE image IN (SELECT image FROM {})".format(feature_table, training_table)
    train_data = RxSqlServerData(sql_query=train_query, connection_string=conn_str, column_info=colInfo)

    test_query = "SELECT * FROM {} WHERE image IN (SELECT image FROM {})".format(feature_table, testing_table)
    test_data = RxSqlServerData(sql_query=test_query, connection_string=conn_str, column_info=colInfo)

    featureSet = ["feature." + str(i) for i in range(DNNDimension)]
    label = "Label"
    cols = featureSet + [label]
    classifier = rx_neural_network("Label ~ feature", data=train_data, method="multiClass",
                                   optimizer=sgd_optimizer(learning_rate=0.011,
                                                           l_rate_red_ratio=0.9,
                                                           l_rate_red_freq=3,
                                                           momentum=0.2),
                                   num_iterations=300,
                                   ml_transforms=[concat(cols={"feature": featureSet})])

    test_score = rx_predict(classifier, test_data, extra_vars_to_write=["image", "Label"])
    train_score = rx_predict(classifier, train_data, extra_vars_to_write=["image", "Label"])
    testACC = float(len(test_score[test_score["Label"] == test_score["PredictedLabel"]])) / len(test_score)
    trainACC = float(len(train_score[train_score["Label"] == train_score["PredictedLabel"]])) / len(train_score)
    print("The train accuracy of the neural network model is {}".format(trainACC))
    print("The test accuracy of the neural network model is {}".format(testACC))

    print("Saving the predictive results of all the images into SQL table...")
    outputScore = RxSqlServerData(connection_string=conn_str, table=score_table)
    rx_data_step(pd.concat([test_score, train_score]), outputScore, overwrite=True)
    print("Saving model into SQL table...")
    save_model(model_table, conn_str, classifier, MODEL_NAME)

#evaluate the image ranking system using evlauation image set
def evaluate_model(conn_str, candidate_table, image_pairs_table):
    distMethods = ["L2", "cosine"]
    image_scores = load_predicted_scores(conn_str, TABLE_SCORE)
    imagePairQuery = "SELECT * FROM " + image_pairs_table
    imagePairData_sql = RxSqlServerData(connection_string=conn_str, sql_query=imagePairQuery, strings_as_factors=False)
    imagePairData = rx_import(imagePairData_sql)
    print("Calculating ranking metrics...")
    calculate_ranking_metrics(image_scores, imagePairData, distMethods)

#For each query image, return top K similar candidates for each query image
def rank_candidates(conn_str, query_table, model_table, results_table):
    print("Loading the classifier output for all the candidate images...")
    candidateImageVector = load_predicted_scores(conn_str, TABLE_SCORE)

    print("Loading query images...")
    queryImagesSql = "SELECT * FROM " + query_table
    queryImages = RxSqlServerData(connection_string=conn_str, sql_query=queryImagesSql, strings_as_factors=False)

    print("Embedding query images...")
    query_image_features = rx_data_step(input_data=queryImages, overwrite=True,
                                        transform_function=featurize_transform, report_progress=2)

    print("Loading classifier...")
    classifier = load_model(model_table, conn_str, MODEL_NAME)

    print("Getting classifier output for query images...")
    queryImageScores = rx_predict(classifier, query_image_features, extra_vars_to_write=["image", "Label"])
    queryImageVector = map_images_to_predictedscores(queryImageScores)

    print("Calculating cosine similarity between each image pair...")
    rank_candiate_images(conn_str, queryImageVector, candidateImageVector, TOP_K_CANDIDATES, results_table)

if __name__ == "__main__":
    conn_str = "DRIVER={SQL Server};SERVER=localhost;PORT=1433;DATABASE=ImageSimilarity_Py;TRUSTED_CONNECTION=True"
    featurize_images(conn_str, TABLE_IMAGES, TABLE_FEATURE)
    prepare_data(conn_str, TABLE_FEATURE, TABLE_TRAINING, TABLE_TESTING, TABLE_RANKING, maxQueryImgsPerSubdir, maxNegImgsPerQueryImg, ratioTrainTest)
    train_classifier(conn_str, TABLE_FEATURE, TABLE_TRAINING, TABLE_TESTING, TABLE_SCORE, TABLE_MODEL, DNNOutputDimension)
    evaluate_model(conn_str, TABLE_SCORE, TABLE_RANKING)
    rank_candidates(conn_str, TABLE_QUERY, TABLE_MODEL, TABLE_RESULTS)