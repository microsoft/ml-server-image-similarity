---
layout: default
title: Quick Start
---

## Quick Start
-----------------
 
 There are multiple ways you can try this solution package out for yourself.

* Visit the [Azure AI Gallery]({{ site.aka_url }}) and use the `Deploy` button.  All necessary software will be installed and configured for you as well as the initial deployment of the solution.  You will be all set to explore the code and [try out the model](jupyter.html) on the deployed virtual machine.

* For an On-Prem installation:

    * **On the SQL Server Machine**

        * Follow [these instructions](SetupSQL.html) to setup the server.

        * Once the server is configured, you can use the [PowerShell Instructions](Powershell_Instructions.html) for a quick deployment of all tables to your own machine.

    * **On your local computer** - follow these steps only if your local computer is not the same as the SQL Server machine.  These steps will already be done by running the PowerShell script if your SQL Server is on your local computer.

        * [Install Machine Learning Server](https://docs.microsoft.com/en-us/machine-learning-server/install/machine-learning-server-windows-install). Make sure to also include the Pre-trained Models during  installation.

        *  Clone the solution code to your computer:

                git clone https://github.com/Microsoft/ml-server-image-similarity.git 
        

        * Install the image similarity package:

            cd ml-server-image-similarity
            "C:\Program Files\Microsoft\ML Server\PYTHON_SERVER\python.exe" setup.py install
    
    * You can then follow the steps in [For the Data Scientist](data-scientist.html) or [For the Database Analyst](dba.html).