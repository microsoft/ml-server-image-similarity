---
layout: default
title: For the images Scientist
---

## For the Data Scientist - Develop with Python
----------------------------


<div class="row">
    <div class="col-md-6">
        <div class="toc">
            <li><a href="#first">{{ site.solution_name }}</a></li>
            <li><a href="#system-requirements">System Requirements</a></li>
            <li><a href="#data">Data</a></li>
            <li><a href="#end-to-end_run">End-to-end run</a></li>
            <li><a href="#step1">Step1: Pre-Processing and Cleaning</a></li>
            <li><a href="#step2">Step2: Feature Engineering</a></li>
            <li><a href="#step3">Step3: Splitting, Training, Testing and Evaluating</a></li>
            <li><a href="#step4">Step 4: Evaluate model</a></li>
            <li><a href="#step5">Step 5: Ranking candidates for each query image</a></li>
            <li><a href="#template-contents">Template Contents</a></li>
        </div>
    </div>
    <div class="col-md-6">
        Microsoft Machine Learning Services provide an extensible, scalable platform for integrating machine learning tasks and tools with the applications that consume machine learning services. It includes a database service that runs outside the SQL Server process and communicates securely with R and Python. 
        <p>
       This solution package shows how to pre-process images (cleaning and feature engineering), train prediction models, and perform scoring on the SQL Server machine with Python.  </p>
    </div>
</div>

Scientists who are testing and developing solutions can work from the convenience of their preferred IDE on their client machine, while <a href="https://msdn.microsoft.com/en-us/library/mt604885.aspx">setting the computation context to SQL</a> (see  **Python** folder for code).  They can also deploy the completed solutions to SQL Server 2017 by embedding calls to Python in stored procedures. These solutions can then be further automated by the use of SQL Server Integration Services and SQL Server agent: a PowerShell script (.ps1 file) automates the running of the SQL code.

<a name="first"></a>

## {{ site.solution_name }}
--------------------------


To try this out yourself, see the [Quick Start](quick.html) section on the main page.  

This page describes what happens in each of the steps. 


## System Requirements
--------------------------

    {% include requirements.md %}

This code was tested using SQL Server 2017, and assumes that SQL Server with Python Service was installed. The installation process can be found [here](install.md).



## Data
--------------------------

{% include inputdata.html %}


[Click here](tables.html) to view the SQL database tables created in this solution.


## End-to-end Run
--------------------------

In the **Python** folder,the **run_image_similarity.py** file contains the code to run this solution. You can also run through all the code with the **Train Model** [Jupyter notebook](jupyter.html) in this directory. 

Since a model has already been built, you can also skip to the **Test Model** [Jupyter notebook](jupyter.html) to use the model to find similar images for a new image. Try out one of the images in the notebook or try an image of your own.

<a name="step1"></a>

### Step 1: Featurization of images with pre-trained DNN model
--------------------------

The `featurize_images` function generates features from the images using a pre-trained Resnet in `microsoftml`. The input is the FileTable named in the `TABLE_IMAGES` variable.  This table contains the images, the output is the SQL Table named in the `TABLE_FEATURE` variable,  which saves the images' path, label,
and DNN features. The dimension of the features depends on which Resnet Model is used in this step. Here we used Resnet18 which generates 512-dimensional features for each image.


1. First, get the images path from the FileTable, map the distinct categories of all the images to factor labels.

2. Second, get a label for each image based on its category.

3. Third, calculate the features using `microsoftml` library given the images path.

<a name="step2"></a>

### Step 2: Prepare training/testing/evaluation set
--------------------------

The `prepare_data` function prepares the training/testing/evaluation image set. 

1. Randomly split all the images into training/testing set based on category information and train/test ratio. You can change the parameter `ratioTrainTest` according to the number of total images. For example, if the `ratioTrainTest = 0.7`, then for each category, randomly select 70% images as training images and the left 30% images as testing images.

2. Once the testing images were inserted into the SQL table, we generate evaluation image set based on testing images since we do not want to evaluation images overlap with the training images.

3. Randomly select images from each category as query images, and then randomly select 1 positive image from the same category and some negative images from the other categories. So for each query image, we create 101 image pairs. Users also can set up parameter `maxQueryImgsPerSubdir`
 to decide how many query images they want to select from each category, and set up parameter `maxNegImgsPerQueryImg` to decide how many negative images they want to select for each query image.

4. For example, in this sample, we set up `maxQueryImgsPerSubdir = 20` and `maxNegImgsPerQueryImg = 100`, finally, the evaluation set contains 220 query images since the image data contains 11 categories, and each query image has 101 candidates (1 positive image and 100 negative images). 

<a name="step3"></a>

### Step 3: Training multi-class classifier
--------------------------

Once the features are computed, and the training images and testing images are inserted into the SQL table, we can use them in the `train_classifier` function to train a neural network model using microsofotml library and then save the model into SQL table.  

1) Get the DNN features for the training images and testing images from the feature table named in  `TABLE_FEATURE`, then train multi-class classifier using neural network algo in microsoftml library. Finally, evaluate the performance of the classifier using testing images.

2) Overall accuracy is calculated to measure the performance of the classifier.
   
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


3) Get the predicted scores of all the images in training and testing table using trained classifier, and save the predicted scores into SQL table named in `TABLE_SCORE`. Here we use all the images as the candidates for the last step. Users also can have their own candidate images. To get the predicted scores for users' own candidate images, first, you have to featurize the candidate images using pre-trained Resnet, and then load the classifier to calculate the predicted scores for your own candidate images. 

<a name="step4"></a>

### Step 4: Evaluate model
--------------------------

Once the model and the predicted scores of all the images are saved into SQL table, we can get the predicted scores from the table named in `TABLE_SCORE` for all the image pairs in evaluation table named in `TABLE_RANKING`. Based on the predicted scores, we can calculate the distance between each image pair to measure
their similarity so that we can evaluate the performance of the model in terms of ranking.

1. Load the predicted scores for all the images, for example, in this sample, the image data contains 11 categories, so the predicted score is a 11-dimensional vector for each image.

2. Load the image pairs from the evaluation table, for each image pair, we can get two 11-dimensional vectors, we calculate L2 and Cosine distance between these two vectors to measure the similarity. So for each image pair, we get two distances.

3. We calculate top 1, 2, 4, 5, 8, 10, 15, 20, 28 and 32 accuracy to measure the ranking performance.


<a name="step5"></a>

### Step 5: Ranking candidates for each query image
--------------------------

Once the accuracy of the image ranking system satisfy the requirement, we can rank the candidates for the query images. 

1. In order to get the similar images for each query image quickly, we have to make the predicted scores of all the candidate images ready before this step. We explained how to get the predicted scores for users' own candidate images in step 3. So we assume
the predicted scores of all the candidate images are already saved in SQL table named in `TABLE_SCORE`, we just need to load the predicted scores for all the candidate images from the SQL table. We don't need to calculate them in this step.

2. Assume all the query images are already saved in SQL table named in `TABLE_QUERY`. we load the query images from the SQL table, and then featurize the query images using pre-trained Resnet, here you have to used the same pre-trained model which used in the step 1.

3. Load the model which trained in step 3 form SQL table named in `TABLE_MODEL`, and calculate the predicted scores for all the query images using the model.

4. Calculate the Cosine distance between each query image and all the candidates, based on the distance, return top K similar images for each query images. Users can set up parameter `TOP_K_CANDIDATES` to decide how many similar images should be returned for each query image.
 For example, here we set `TOP_K_CANDIDATES` equal to 5, so in the result table named in `TABLE_RESULTS`, each query image has 10 similar images.



## Template Contents 
---------------------

[View the contents of this solution template](contents.html).


To try this out yourself: 

* View the [Quick Start](quick.html).

[&lt; Home](index.html)
