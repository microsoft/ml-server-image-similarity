---
layout: default
title: Template Contents
---

## Template Contents
--------------------

The following is the directory structure for this template:

- [**data**](#data)  This directory is used to download images for this solution. 
- [**imagesimilarity**](#image-similarity) This directory contains the imagesimilarity package used for the solution
- [**Python**](#model-development-in-python)  This contains the Python code to prepare training/testing/evaluation set, train the multi-class classifier and evaluate the model.
- [**Resources**](#resources-for-the-solution-packet) This directory contains other resources for the solution package.




### Data
----------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description</th></tr>
<tr><td> download_data.py </td><td> Python script to download images named in the **fashion_texture_urls.tsv** file. </td></tr>
<tr><td> fashion_texture_urls.tsv </td><td> list of images and their categorization to be downloaded. </td></tr>
<tr><td> download_data.bat </td><td> Executes **download_data.py** </td></tr>
</table>

### Image Similarity
----------------------------
This folder contains a Python package with helper functions that are used both in the **run_image_similarity.py ** code as well as the SQL Stored Procedures. 

### Model Development in Python
-------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> {{ site.jupyter_name}}  </td><td> Contains the Jupyter Notebook file that trains the model. </td></tr>
<tr><td> Test Model.ipynb  </td><td> Contains the Jupyter Notebook file that demonstrates the model. </td></tr>
<tr><td>copy_images_to_filetable.py  </td><td> Populates the SQL database with the image needed for training and testing the model </td></tr>
<tr><td>parameters.py  </td><td> Parameters used in run_image_similarity.py  </td></tr>
<tr><td>run_image_similarity.py  </td><td> featurize images using pre-trained DNN model, prepare training/testing/evaluation image set, train a multi-class classifier and save the model into SQL table, evaluate the image ranking system using evlauation image set, and  return top K similar candidates for new query images</td></tr>
</table>


* See [For the Data Scientist](data_scientist.html) for more details about these files.


### Operationalize in SQL Python 
-------------------------------------------------------
Stored procedures in SQL implement the model training workflow. 

* See [ For the Database Analyst](dba.html) for more information.
* Follow the [PowerShell Instructions](Powershell_Instructions.html) to execute the PowerShell script which creates these stored procedures.

### Resources for the Solution Package
------------------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>

<tr><td> .\Resources\ActionScripts\ConfigureSQL.ps1</td><td>Configures SQL, called from ImageSimilaritySetup.ps1  </td></tr>
<tr><td> .\Resources\ActionScripts\CreateDatabase.sql</td><td>Creates the database for this solution, called from ConfigureSQL.ps1  </td></tr>
<tr><td> .\Resources\ActionScripts\CreateSQLObjectsPy.sql</td><td>Creates the tables and stored procedures for this solution, called from ConfigureSQL.ps1   </td></tr>
<tr><td> .\Resources\ActionScripts\ImageSimilaritySetup.ps1</td><td>Configures SQL, creates and populates database</td></tr>
<tr><td> .\Resources\ActionScripts\installPyPkg.bat</td><td>Installs the imagesimilarity Python package   </td></tr>
<tr><td> .\Resources\ActionScripts\LoadImageData.ps1</td><td>Used to trigger the download of images, upload to SQL, and run the solution workflow.  </td></tr>
<tr><td> .\Resources\ActionScripts\RunOnce.cmd</td><td>Used to run LoadImageData.ps1 the first time a user logs onto the VM.  </td></tr>
<tr><td> .\Resources\ActionScripts\SolutionHelp.url</td><td>URL to the help page. </td></tr>

</table>




[&lt; Home](index.html)
