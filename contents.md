---
layout: default
title: Template Contents
---

## Template Contents
--------------------

The following is the directory structure for this template:

- [**data**](#data)  This contains all the images used to train and test the image similarity model.
- [**Python**](#model-development-in-python)  This contains the Python code to prepare training/testing/evaluation set, train the multi-class classifier and evaluate the model.
- [**Resources**](#resources-for-the-solution-packet) This directory contains other resources for the solution package.
- [**SQLPy**](#operationalize-in-sql-python) This contains the T-SQL code with Python to pre-process the datasets, train the model and find similarities for new images. It also contains a PowerShell script to automate the entire process, including loading the data into the database (not included in the T-SQL code).



### Data
----------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description</th></tr>
<tr><td> .\Data\LengthOfStay.csv  </td><td> Synthetic data modeled after real world hospital inpatient records </td></tr>
</table>

### Model Development in Python
-------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> {{ site.jupyter_name}}  </td><td> Contains the Jupyter Notebook file that trains the model. </td></tr>
<tr><td> Test Model.ipynb  </td><td> Contains the Jupyter Notebook file that demonstrates the model. </td></tr>
<tr><td>copy_images_to_filetable.py  </td><td> Populates the SQL database with the image needed for training and testing the model </td></tr>
<tr><td>parameters.py  </td><td> Parameters used in run_image_similarity.py  </td></tr>
<tr><tdrun_image_similarity.py  </td><td> featurize images using pre-trained DNN model, prepare training/testing/evaluation image set, train a multi-class classifier and save the model into SQL table, evaluate the image ranking system using evlauation image set, and  return top K similar candidates for new query images</td></tr>
</table>


* See [For the Data Scientist](data_scientist.html) for more details about these files.


### Operationalize in SQL Python XXXFIX THIS
-------------------------------------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> .\SQLPy\Length_Of_Stay.ps1  </td><td> Automates execution of all .sql files and creates stored procedures </td></tr>
<tr><td> .\SQLPy\execute_yourself.sql  </td><td> used in Length_Of_Stay.sql </td></tr>
<tr><td> .\SQLPy\load_data.ps1  </td><td> used in Length_Of_Stay.sql </td></tr>
<tr><td> .\SQLPy\step0_create_table.sql  </td><td> Creates initial <code>LengthOfStay</code> table </td></tr>
<tr><td> .\SQLPy\step1_data_processing.sql  </td><td> Handles missing data </td></tr>
<tr><td> .\SQLPy\step2_feature_engineering.sql  </td><td> Standardizes measures and creates <code>number_of_issues</code> and <code>lengthofstay_bucket</code> </td></tr>
<tr><td> .\SQLPy\step3a_splitting.sql  </td><td> Splits data into train and test </td></tr>
<tr><td> .\SQLPy\step3b_training.sql  </td><td> Trains and scores a gradient boosted trees model (rx_btrees) or Random Forest (rx_dforest)  </td></tr>
<tr><td> .\SQLPy\step3c_testing_evaluating.sql  </td><td> Scores and evaluates models </td></tr>


</table>

* See [ For the Database Analyst](dba.html) for more information about these files.
* Follow the [PowerShell Instructions](Powershell_Instructions.html) to execute the PowerShell script which automates the running of all these .sql files.

### Resources for the Solution Package
------------------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>

<tr><td> .\Resources\create_user.sql </td><td> Used during initial SQL Server setup to create the user and password and grant permissions. </td></tr>
<tr><td> .\Resources\Data_Dictionary.xlsx   </td><td> Description of all variables in the LengthOfStay.csv data file</td></tr>
<tr><td> .\Resources\Images\ </td><td> Directory of images used for the  Readme.md  in this package. </td></tr>
</table>




[&lt; Home](index.html)
