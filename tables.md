---
layout: default
title: Description of Database Tables
---

## SQL Database Tables
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
