---
layout: default
title: Description of Database Tables
---

## SQL Database Tables and Stored Procedures
-----------------------

Below are the data tables that you will find in your database after deployment.

<table class="table" >
	<thead>
		<tr>
			<th>Table</th>
			<th>Description</th>
		</tr>
	</thead>
	<tbody>
		<tr>
			<td>dbo.ImageStore</td>
            <td>FileTable, used to save the images</td>
        </tr>
        <tr>
			<td>dbo.features</td>
            <td>SQL table which used to save images' path, label and DNN features</td>
        </tr>
        <tr>
			<td>dbo.training_images</td>
            <td>training images</td>
        </tr>
        <tr>
			<td>dbo.testing_images</td>
            <td>testing images</td>
        </tr>
        <tr>
			<td>dbo.evaluation_images</td>
            <td>image pairs used to evaluate the model</td>
        </tr>
        <tr>
			<td>dbo.scores</td>
            <td>predicted scores of all the images</td>
        </tr>
        <tr>
			<td>dbo.model</td>
            <td>trained model</td>
        </tr>
        <tr>
			<td>dbo.query_images</td>
            <td>query images</td>
        </tr>
        <tr>
			<td>dbo.ranking_results</td>
            <td>ranked candidates for all the query images</td>
        </tr>
    </tbody>
</table>

The following stored procedures are used in this solutions:
v<table class="table" >
	<thead>
		<tr>
			<th>Stored Procedure</th>
			<th>Description</th>
		</tr>
	</thead>
	<tbody>
	    <tr>
        <td>EvaluateModel</td><td>Evaluates the performance of the model in terms of ranking</td>
        </tr>
        <tr>
        <td>FeaturizeImages</td><td>Generates features from the images using a pre-trained Resnet in `microsoftml` </td>
        </tr>
        <tr>
        <td>Initial_Run_Once_Py</td><td>Runs the training workflow natively in SQL for this solution</td>
        </tr>
        <tr>
        <td>PrepareData</td><td>Creates and prepares the training/testing/evaluation image set </td>
        </tr>
        <tr>
        <td>RankCandidates</td><td>Finds similar images for each query image</td>
        </tr>
        <tr>
        <td>TrainClassifier</td><td>Trains a neural network model using `microsoftml` library and saves the model into SQL table </td>
        </tr>
        </table>