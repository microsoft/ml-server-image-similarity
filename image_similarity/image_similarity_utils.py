from revoscalepy import RxSqlServerData, rx_import, rx_data_step, RxOdbcData, rx_write_object, rx_read_object, rx_get_var_names
import glob, shutil
import os, random,  collections
import operator
import numpy as np, scipy.spatial.distance
from pandas import DataFrame, concat
from sklearn.utils import shuffle

random.seed(0)

def get_directories_in_directory(directory):
    return [s for s in os.listdir(directory) if os.path.isdir(directory + "/" + s)]

def get_files_in_directory(directory, postfix = ""):
    if not os.path.exists(directory):
        return []
    fileNames = [s for s in os.listdir(directory) if not os.path.isdir(directory + "/" + s)]
    if not postfix or postfix == "":
        return fileNames
    else:
        return [s for s in fileNames if s.lower().endswith(postfix)]

def get_random_number(low, high):
    randomNumber = random.randint(low, high)
    return randomNumber

def get_random_list_element(listND, containsHeader = False):
    if containsHeader:
        index  = get_random_number(1, len(listND) - 1)
    else:
        index = get_random_number(0, len(listND) - 1)
    return listND[index]

def compute_vector_distance(vec1, vec2, method):
    assert (len(vec1) == len(vec2))
    # Distance computation
    vecDiff = vec1 - vec2
    method = method.lower()
    if method == 'l2':
        dist = np.linalg.norm(vecDiff, 2)
    elif method == "cosine":
        dist = scipy.spatial.distance.cosine(vec1, vec2)
    else:
        raise Exception("Distance method unknown: " + method)
    assert (not np.isnan(dist))
    return dist

def map_images_to_predictedscores(classifierOutput):
    features = dict()
    for index, row in classifierOutput.iterrows():
        key = row['image']
        features[key] = row.drop(['image', 'Label', 'PredictedLabel'])
    return features

def is_same_class(queryClass, targetClass):
    queryElements = queryClass.split("\\")
    query = queryElements[len(queryElements) - 2]
    targetElements = targetClass.split("\\")
    target = targetElements[len(targetElements) - 2]
    return query == target

def prepare_evaluation_set(conn_str, feature_table, test_table, evaluation_table, maxQueryImgsPerCat, maxNegImgsPerQueryImg):
    evaluation_set = DataFrame()
    query = "SELECT image, Label FROM {} WHERE image IN (SELECT image FROM {})".format(feature_table, test_table)
    test_images = RxSqlServerData(sql_query=query, connection_string=conn_str)
    test_images_df = rx_import(test_images)
    classes = test_images_df.Label.unique()
    for queryCat in classes:
        query_images = shuffle(test_images_df.loc[test_images_df["Label"] == queryCat, "image"])
        selectQueryImages = query_images.sample(n=maxQueryImgsPerCat, random_state=0, replace=True)
        for index, queryImage in selectQueryImages.iteritems():
            refImage = get_random_list_element(list(set(query_images) - set([queryImage])))
            firstitem = DataFrame({'queryCat': [queryCat], 'queryImage': [queryImage], 'refCat': [queryCat], 'refImage': [refImage]})
            evaluation_set = concat([evaluation_set, firstitem])
            for _ in range(maxNegImgsPerQueryImg):
                refCat = get_random_list_element(list(set(classes) - set([queryCat])))
                refImages = test_images_df.loc[test_images_df["Label"] == refCat, "image"]
                refImage = shuffle(refImages).sample(n=1, random_state=0)
                refImage = refImage.iloc[0]
                secitem = DataFrame({'queryCat': [queryCat], 'queryImage': [queryImage], 'refCat': [refCat], 'refImage': [refImage]})
                evaluation_set = concat([evaluation_set, secitem])
    evaluation_images = RxSqlServerData(table=evaluation_table, connection_string=conn_str)
    rx_data_step(evaluation_set, evaluation_images, overwrite=True)

def rank_candiate_images(conn_str, queryImageVector, candidateImageVector, top_k_candidates, results_table):
    ranking_results = DataFrame()
    for queryKey in queryImageVector.keys():
        queryFeat = queryImageVector[queryKey]
        candidates = dict()
        for candidateKey in candidateImageVector.keys():
            refFeat = candidateImageVector[candidateKey]
            dist = scipy.spatial.distance.cosine(queryFeat, refFeat)
            candidates[candidateKey] = dist
        sorted_candidates = sorted(candidates.items(), key=operator.itemgetter(1))[:top_k_candidates]
        for key, value in dict(sorted_candidates).items():
            item = DataFrame({'queryImage': [queryKey], 'refImage': [key], 'distance': [value]})
            ranking_results = concat([ranking_results, item])
    ranking_results_table = RxSqlServerData(table=results_table, connection_string=conn_str)
    rx_data_step(ranking_results, ranking_results_table, overwrite=True)

def copy_image_to_filetable(image_path, image_filetable_folder):
    if not os.path.exists(image_filetable_folder):
        os.makedirs(image_filetable_folder)
    for jpgfile in glob.iglob(os.path.join(image_path, "*.jpg")):
        shutil.copy(jpgfile, image_filetable_folder)

def map_category_to_label(image_table, conn_str):
    lutLabel2Id = dict()
    query = "SELECT name FROM " + image_table + " WHERE is_directory = 1"
    category_sql = RxSqlServerData(sql_query=query, connection_string=conn_str)
    category_names = rx_import(category_sql)
    for index, key in enumerate(category_names.name.unique()):
        lutLabel2Id[key] = index
    return lutLabel2Id

def get_label_levels(feature_table, conn_str):
    levels = []
    query = "SELECT Label FROM " + feature_table
    labels_sql = RxSqlServerData(sql_query=query, connection_string=conn_str)
    labels_level = rx_import(labels_sql)
    for index, key in enumerate(labels_level.Label.unique()):
        levels.append(str(int(key)))
    return levels

def get_image_path(image_table, connection_string):
    query = 'SELECT (FILETABLEROOTPATH() + [file_stream].GetFileNamespacePath()) as image FROM ' + image_table + " WHERE is_directory = 0"
    filetable_sql = RxSqlServerData(sql_query=query, connection_string=connection_string)
    imageData = rx_import(filetable_sql, strings_as_factors=False)
    return imageData

def get_image_label(path, lutLabel2Id):
    pathitems = path.split('\\')
    label = lutLabel2Id[pathitems[len(pathitems) - 2]]
    return label

def get_training_testing_images(image_data, train_test_ratio, train_table, test_table, conn_str):
    trainImages = DataFrame()
    testImages = DataFrame()
    classes = image_data.Label.unique()
    trainTable = RxSqlServerData(table=train_table, connection_string=conn_str)
    testTable = RxSqlServerData(table=test_table, connection_string=conn_str)
    for category in classes:
        images = image_data.loc[image_data["Label"] == category, "image"]
        images = shuffle(images)
        splitIndex = int(train_test_ratio * len(images))
        trainImages = concat([trainImages, images[:splitIndex].to_frame()])
        testImages = concat([testImages, images[splitIndex:].to_frame()])
    rx_data_step(trainImages, trainTable, overwrite=True)
    rx_data_step(testImages, testTable, overwrite=True)

def featurize_transform(dataset, context):
    from microsoftml import rx_featurize, load_image, resize_image, extract_pixels, featurize_image
    data = DataFrame(dataset)
    data = rx_featurize(
        data=data,
        overwrite=True,
        ml_transforms=[
            load_image(cols={"feature": "image"}),
            resize_image(cols="feature", width=224, height=224),
            extract_pixels(cols="feature"),
            featurize_image(cols="feature", dnn_model='Resnet18')
        ]
    )
    return data

def compute_features(data, output_table, connection_string):
    results_sql = RxSqlServerData(table=output_table, connection_string=connection_string)
    rx_data_step(input_data=data, output_file=results_sql, overwrite=True,
                 transform_function=featurize_transform,
                 report_progress=2)

def save_model(table_name, connection_string, classifier, name):
    classifier_odbc = RxOdbcData(connection_string, table=table_name)
    rx_write_object(classifier_odbc, key=name, value=classifier, serialize=True, overwrite=True)

def load_model(table_name, connection_string, name):
    classifier_odbc = RxOdbcData(connection_string, table=table_name)
    classifier = rx_read_object(classifier_odbc, key=name, deserialize=True)
    return classifier

def generate_model_formula(sql_data):
    features_all = rx_get_var_names(sql_data)
    features_to_remove = ["Label", "image"]
    train_features = [x for x in features_all if x not in features_to_remove]
    formula = "Label ~ " + " + ".join(train_features)
    return formula

def calculate_ranking_metrics(imageFeatures, imagePairData, distMethods):
    queryImageInfo = imagePairData.queryImage.unique()
    allDists = {queryIndex: collections.defaultdict(list) for queryIndex in range(len(queryImageInfo))}

    for queryIndex, queryKey in enumerate(queryImageInfo):
        queryFeat = imageFeatures[queryKey]
        if queryIndex % 50 == 0:
            print(
                "Computing distances for query image {} of {}: {}..".format(queryIndex, len(queryImageInfo), queryKey))
        refImages = imagePairData[imagePairData["queryImage"] == queryKey]
        for index, row in refImages.iterrows():
            refFeat = imageFeatures[row["refImage"]]
            for distMethod in distMethods:
                dist = compute_vector_distance(queryFeat, refFeat, distMethod)
                allDists[queryIndex][distMethod].append(dist)

    for distMethod in distMethods:
        correctRanks = []
        for queryIndex, queryKey in enumerate(queryImageInfo):
            sortOrder = np.argsort(allDists[queryIndex][distMethod])
            refImages = imagePairData[imagePairData["queryImage"] == queryKey].refImage
            boCorrectMatches = [is_same_class(queryKey, targetKey) for (index, targetKey) in refImages.iteritems()]
            boCorrectMatches = np.array(boCorrectMatches)[sortOrder]
            positiveRank = np.where(boCorrectMatches)[0][0] + 1
            correctRanks.append(positiveRank)
        medianRank = round(np.median(correctRanks))
        top1Acc = 100.0 * np.sum(np.array(correctRanks) == 1) / len(correctRanks)
        top2Acc = 100.0 * np.sum(np.array(correctRanks) <= 2) / len(correctRanks)
        top4Acc = 100.0 * np.sum(np.array(correctRanks) <= 4) / len(correctRanks)
        top5Acc = 100.0 * np.sum(np.array(correctRanks) <= 5) / len(correctRanks)
        top8Acc = 100.0 * np.sum(np.array(correctRanks) <= 8) / len(correctRanks)
        top10Acc = 100.0 * np.sum(np.array(correctRanks) <= 10) / len(correctRanks)
        top15Acc = 100.0 * np.sum(np.array(correctRanks) <= 15) / len(correctRanks)
        top20Acc = 100.0 * np.sum(np.array(correctRanks) <= 20) / len(correctRanks)
        top28Acc = 100.0 * np.sum(np.array(correctRanks) <= 28) / len(correctRanks)
        top32Acc = 100.0 * np.sum(np.array(correctRanks) <= 32) / len(correctRanks)
        print("correct Ranks [%s]" % ", ".join(map(str, correctRanks)))
        print("Distance {:>10}: top1Acc = {:5.2f}%, top2Acc = {:5.2f}%, top4Acc = {:5.2f}%, "
              "top5Acc = {:5.2f}%, top8Acc = {:5.2f}%, top10Acc = {:5.2f}%, top15Acc = {:5.2f}%, "
              "top20Acc = {:5.2f}%, top28Acc = {:5.2f}%, top32Acc = {:5.2f}%, meanRank = {:5.2f}, medianRand = {:2.0f}".format(
                distMethod, top1Acc, top2Acc, top4Acc, top5Acc, top8Acc, top10Acc, top15Acc, top20Acc, top28Acc, top32Acc, np.mean(correctRanks), medianRank))

def load_predicted_scores(conn_str, score_table):
    sqlQuery = "SELECT * FROM " + score_table
    images = RxSqlServerData(connection_string=conn_str, sql_query=sqlQuery, strings_as_factors=False)
    imageScores = rx_import(images)
    image_scores = map_images_to_predictedscores(imageScores)
    return image_scores

