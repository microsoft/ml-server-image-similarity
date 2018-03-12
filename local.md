---
layout: default
title: Setup for Local Code Execution
---
## Setup for Local Code Execution

You can execute code on your local computer and push the computations to the SQL Server.

_Follow the steps in this section only if your local computer is different than the SQL Server machine._

## On the SQL Server Computer: Configure for Remote Access

Connect to the SQL Server computer to perform the following steps.

There must be an open Windows firewall to allow a connection to the SQL Server. To open the firewall, execute the following command in a PowerShell window on the SQL Server computer (or VM you deployed from Azure AI Gallery):

    netsh advfirewall firewall add rule name="SQLServer" dir=in action=allow protocol=tcp localport=1433

## On Your Local Computer 
Now switch to your local computer and perform the following steps to get the code and setup your local environment.

* [Install Machine Learning Server](https://docs.microsoft.com/en-us/machine-learning-server/install/machine-learning-server-windows-install). Make sure to include installation of Python and the Pre-trained Models.

* Clone the solution code to your computer:

        git clone {{site.code_url}}.git

* Install the image similarity package:

    cd ml-server-image-similarity
    "C:\Program Files\Microsoft\ML Server\PYTHON_SERVER\python.exe" setup.py install

* In the **Python\run_image_similarity.py** file, change the connection string at the bottom to specify your server.  If you have a userid and password, replace `TRUSTED_CONNECTION=True` with `uid=YOURUSERID;pwd=YOURPASSWORD`.

[&lt; Back to PowerShell Instructions](powershell_instructions.html)