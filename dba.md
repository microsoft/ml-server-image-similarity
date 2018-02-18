---
layout: default
title: For the Database Analyst
---

## For the Database Analyst - Operationalize with SQL
------------------------------

<div class="row">
    <div class="col-md-6">
        <div class="toc">
            <li><a href="#system-requirements">System Requirements</a></li>
            <li><a href="#workflow-automation">Workflow Automation</a></li>
            <li><a href="#step0">Step 0: Creating Tables</a></li>
            <li><a href="#step1">Step 1: Featurization of images with pre-trained DNN model</a></li>
            <li><a href="#step2">Step 2: Prepare training/testing/evaluation set</a></li>
            <li><a href="#step3">Step 3: Training multi-class classifier</a></li>
            <li><a href="#step4">Step 4: Evaluate model</a></li>
             <li><a href="#step5">Step 5: Ranking candidates for each query image</a></li>
        </div>
    </div>
    <div class="col-md-6">
              Microsoft Machine Learning Services provide an extensible, scalable platform for integrating machine learning tasks and tools with the applications that consume machine learning services. It includes a database service that runs outside the SQL Server process and communicates securely with R and Python. 
        <p>
       This solution package shows how to pre-process images (cleaning and feature engineering), train prediction models, and perform scoring on the SQL Server machine with stored procedures which includes Python code.  </p>
          </div>
</div>

All the steps can be executed on SQL Server client environment (SQL Server Management Studio). We provide a Windows PowerShell script which invokes the SQL scripts and demonstrates the end-to-end modeling process.

## System Requirements
-----------------------

    {% include requirements.md %}


## Workflow Automation
-------------------
Follow the [PowerShell instructions](Powershell_Instructions.html) to execute all the scripts described below.  [Click here](tables.html) to view the SQL database tables created in this solution.

 
<a name="step0"></a>

### Step 0: Creating Tables
-------------------------


### Input:

* Images in the directory `C:\Solution\ImageSimilarity\data\fashionTexture` are used to populate the FileTable created in this step

### Output:

* ImageStore

### Related files:

* **create_imagesbase_with_filetable.sql**
* **create_file_table.sql**



### Example:

    EXEC CreateTables

Then copy images into the directory `\\computer-name\MSSQLSERVER\FileTableimages\ImageStore`

<a name="step1"></a>

## Step 1: Featurization of images with pre-trained DNN model
-------------------------
This step generates features from the images using a pre-trained Resnet in `microsoftml`. The input is the FileTable `@image_table` which contains the images, the output is the SQL Table `@feature_table` which saves the images' path, label,
and DNN features. The dimension of the features depends on which Resnet Model is used in this step. Here we used Resnet18 which generates 512-dimensional features for each image.
The stored procedure [sp_01_featurize_images.sql](SQLPy/sp_01_featurize_images.sql) contains three steps:

1. First, get the images path from the FileTable, map the distinct categories of all the images to factor labels.

2. Second, get a label for each image based on the its category.

3. Third, calculate the features using `microsoftml` library given the images path. You can find the code in **image_similarity/image_similarity_utils.py**.

### Input:
* `ImageStore` table

### Output:
* `features` table

### Related files:
* **sp_01_featurize_images.sql**

### Example:

    EXEC FeaturizeImages 'ImageStore', 'features'

<a name="step2"></a>

## Step 2: Prepare training/testing/evaluation set
-------------------------
This step prepares the training/testing/evaluation image set. Here is the detail information about how to generate training/testing/evaluation set:

1. Randomly split all the images into training/testing set based on category information and train/test ratio, users can change the parameter `@ratioTrainTest` according to the number of total images they have. For example, if the `@ratioTrainTest = 0.7`, then for each category, randomly select 70% images as training images and the left 30% images as testing images.

2. Once the testing images were inserted into the SQL table, we generate evaluation image set based on testing images since we do not want to evaluation images overlap with the training images.

3. Randomly select images from each category as query images, and then randomly select 1 positive image from the same category and some negative images from the other categories. So for each query image, we create 101 image pairs. Users also can set up parameter `@queryImagePerCat`
 to decide how many query images they want to select from each category, and set up parameter `@negImgsPerQueryImg` to decide how many negative images they want to select for each query image.

4. For example, in this sample, we set up `@queryImagePerCat = 20` and `@negImgsPerQueryImg = 100`, finally, the evaluation set contains 220 query images since the image images contains 11 categories, and each query image has 101 candidates (1 positive image and 100 negative images). 

### Input:
* `features` table

### Output:
* `training_images` table
*  `testing_images` table 
*  `evaluation_images` table
*  `@negImgsPerQueryImg` 

### Related files:
* **sp_02_prepare_data.sql**

### Example:

    EXEC PrepareData 'features', 'training_images', 'testing_images', 'evaluation_images', 0.75, 20, 100

<a name="step3"></a>

## Step 3: Training multi-class classifier
-------------------------
Once the features are computed, and the training images and testing images are inserted into the SQL table, we can use them to train a neural network model using `microsoftml` library and then save the model into SQL table.

1. Get the DNN features for the training images and testing images from the feature table `@feature_table`, then train multi-class classifier using neural network algorithm in `microsoftml` library. Finally, evaluate the performance of the classifier using testing images.

2. Overall accuracy is calculated to measure the performance of the classifier.

    <table class="table" >
        <thead>
            <tr>
                <th>Pre-trained model</th>
                <th>Classifier</th>
                <th>Accuracy on train set</th>
                <th>Accuracy on test set</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>Resnet18</td>
                <td>rx_neural_network</td>
                <td>89.7%</td>
                <td>75.1%</td>
            </tr>
        </tbody>
    </table>

3. Get the predicted scores of all the images in training and testing table using trained classifier, and save the predicted scores into SQL table `@scores_table`. Here we use all the images as the candidates for the last step. Users also can have their own candidate images. To get the predicted scores for users' own candidate images, first, you have to featurize the candidate images using the pre-trained Resnet, and then load the classifier to calculate the predicted scores for your own candidate images.

### Input:
* `features` table
* `training_images` table
* `testing_images` table

### Output:
* `scores` table
* `model` table

### Related files:
* **sp_04_evaluate_model.sql**

### Example:

    EXEC TrainClassifier 'features', 'training_images', 'testing_images', 'scores', 'model'

<a name="step4"></a>

## Step 4: Evaluate model 
-------------------------
Once the model and the predicted scores of all the images are saved into SQL table, we can get the predicted scores from the `@scores_table` for all the image pairs in the evaluation table `@evaluation_table`. Based on the predicted scores, we can calculate the distance between each image pair to measure
their similarity so that we can evaluate the performance of the model in terms of ranking.

1. Load the predicted scores for all the images, for example, in this sample, the image images contains 11 categories, so the predicted score is a 11-dimensional vector for each image.

2. Load the image pairs from the evaluation table, for each image pair, we can get two 11-dimensional vectors, we calculate L2 and Cosine distance between these two vectors to measure the similarity. So for each image pair, we get two distances.

3. We calculate top 1, 2, 4, 5, 8, 10, 15, 20, 28 and 32 accuracy to measure the ranking performance. 

### Input:
* `scores` table
* `evaluation_images` table

### Output:
* accuracy measures

### Related files:
* **sp_04_evaluate_model.sql**

### Example:

    EXEC EvaluateModel 'scores', 'evaluation_images'

<a name="step5"></a>

## Step 5: Ranking candidates for each query image
-------------------------
Once the accuracy of the image ranking system satisfy the requirement, we can rank the candidates for the query images. 

1. In order to get the similar images for each query image quickly, we have to make the predicted scores of all the candidate images ready before this step. We explained how to get the predicted scores for users' own candidate images in step 3. So we assume
the predicted scores of all the candidate images are already saved in SQL table `@scores_table`, we just need to load the predicted scores for all the candidate images from the SQL table. We don't need to calculate them in this step.

2. Assume all the query images are already saved in SQL table `@query_table`. we load the query images from the SQL table, and then featurize the query images using pre-trained Resnet, here you have to used the same pre-trained model which used in the step 1.

3. Load the model which trained in step 3 form SQL table `@model_table`, and calculate the predicted scores for all the query images using the model.

4. Calculate the Cosine distance between each query image and all the candidates, based on the distance, return top K similar images for each query images. Users can set up parameter `@topKCandidates` to decide how many similar images should be returned for each query image.
 For example, here we set `@topKCandidates` equal to 10, so in the result table `@results_table`, each query image has 10 similar images.

### Input:
* `@topKCandidates` - number of images to return for each input
* `query_images` table
* `scores` table 
* `model` table

### Output:
* * `ranking_results` table

### Related files:
* **sp_05_rank_candidates.sql**

### Example:

    EXEC RankCandidates 10, 'query_images', 'scores', 'model', 'ranking_results'









