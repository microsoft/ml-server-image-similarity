---
layout: default
title: HOME
---
<div class="alert alert-warning cig">
Are you unable to connect to your Virtual Machine? See this important information for
<a href="https://blogs.technet.microsoft.com/mckittrick/unable-to-rdp-to-virtual-machine-credssp-encryption-oracle-remediation/">how to resolve.</a>
</div>

This template describes how to build and deploy an image similarity solution with  [SQL Server Machine Learning Services with Python](https://docs.microsoft.com/en-us/sql/advanced-analytics/python/sql-server-python-services).

In this solution, we demonstrate how to apply transfer learning, e.g., using pretrained deep neural network (DNN) model (trained on ImageNet) in solving the image similarity problem for an image based similar product recommendation scenario. The solution uses a small sample of upper body clothing images (around 300 images) as an example: there are 3 different types of textures in the clothing images: dotted, striped, and leopard. Those with similar texture are considered more similar than those with different textures. These data are scraped from the internet using Bing Image Search API and manually annotated. The URLs of these images are provided as a reference.

The users of this solution are welcome to use their own dataset. The end to end machine learning workflow for building such as solution is provided: data preprocessing, featurization, training, testing, evaluation, and ranking. All these major steps are provided in SQL Server Stored procedures with python script embedded inside, which makes it convenient to deploy such as solution with SQL Server ML Services.

For customers who prefer an on-premise solution, the implementation with Microsoft Machine Learning Services is a great option that takes advantage of the powerful combination of SQL Server and the Python languages. We have modeled the steps in the template after a realistic team collaboration on a data science process. Data scientists do the data preparation, model training, and evaluation from their favorite IDE. DBAs can take care of the deployment using SQL stored procedures with embedded code.  We also show how each of these steps can be executed on a SQL Server client environment such as SQL Server Management Studio. A Windows PowerShell script that executes the end-to-end setup and modeling process is provided for convenience. 

This solution starts with data stored in SQL Server.  The data scientist works from the convenience of an IDE on her client machine, while <a href="https://msdn.microsoft.com/en-us/library/mt604885.aspx">setting the computation context to SQL</a>.  When she is done, her code is operationalized as stored procedures in the SQL Database.

A small Jupyter notebook **Test Model.ipynb** is used to submit a new image and see the 10 most similar images returned from the model.

<div class="alert alert-warning">
If you deployed this solution from the <a href="({{ site.aka_url }}">Azure AI Gallery</a>, there was one final step to complete on the VM.  <a href="first_time.html">Click here to learn more</a>.
</div>


