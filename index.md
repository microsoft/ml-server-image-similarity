---
layout: default
title: HOME
---


This solution provides a template (including training, testing, evaluation, and ranking process) to recognize image similarity using a pre-trained DNN model and SQL Server Machine Learning Service with Python. We consider category-level image similarity in this solution. The data we used for this solution is a small upper body clothing texture dataset consisting of 1716 images, where each image is annotated as one of 11 different textures. All images were scraped using Bing Image Search and hand-annotated.

For customers who prefer an on-premise solution, the implementation with Microsoft Machine Learning Services is a great option that takes advantage of the powerful combination of SQL Server and the Python languages. We have modeled the steps in the template after a realistic team collaboration on a data science process. Data scientists do the data preparation, model training, and evaluation from their favorite IDE. DBAs can take care of the deployment using SQL stored procedures with embedded code.  We also show how each of these steps can be executed on a SQL Server client environment such as SQL Server Management Studio. A Windows PowerShell script that invokes the SQL scripts that execute the end-to-end modeling process is provided for convenience. 

This solution starts with data stored in SQL Server.  The data scientist works from the convenience of an IDE on her client machine, while <a href="https://msdn.microsoft.com/en-us/library/mt604885.aspx">setting the computation context to SQL</a>.  When she is done, her code is operationalized as stored procedures in the SQL Database.

A small Jupyter notebook is used to submit a new image and see the 10 most similar images returned from the model.

<img src="images/diagram.png">

