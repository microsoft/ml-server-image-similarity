## Installation

This file explains how to install SQL Server with python and all the necessary libraries to run the image similarity demo.

#### Python with SQL Server Community Technical Preview

The first step is to download [SQL Server 2017 ctp](https://www.microsoft.com/en-us/evalcenter/evaluate-sql-server-2017-ctp/). One of the most important features of the version is that it has built-in Python and R services. It comes with Anaconda 4.2.0 (64-bit) with Python 3.5.

To test that python is working correctly, make sure that the library `revoscalepy` and `microsoftml` can be loaded. To test it, go to the installation folder and look for `python.exe` inside `PYTHON_SERVICES` folder.

	Set-Location "C:\Program Files\Microsoft SQL Server\YOUR-MSSQL-SERVER-INSTANCE-FOLDER\PYTHON_SERVICES"
	python.exe -c "import revoscalepy, microsoftml"

You have to add this folder (`C:\Program Files\Microsoft SQL Server\YOUR-MSSQL-SERVER-INSTANCE-FOLDER\PYTHON_SERVICES`) to the windows path.

Make sure that python runs inside SQL Server correctly. For that, open SQL Server and connect to your database engine. You need to enable external scripts. For that, press `New Query` and execute:

	Exec sp_configure 'external scripts enabled', 1
	Reconfigure with override

Then you need to restart SQL Server. Right click on the server and then restart. After restarting, you have to make sure that in external scripts enables run_value is 1.

#### Install image similarity libraries
The last step is to install the image similarity libraries. You have to go to the folder where you defined the libraries and modified the file [configuration_settings.py] with your credentials of SQL Server. Once the credentials are changed, execute from there:

	Set-Location PATH-TO-IMAGE-SIMILARITY-SQL-Python-CODE
	"C:\Program Files\Microsoft SQL Server\YOUR-MSSQL-SERVER-INSTANCE-FOLDER\PYTHON_SERVICES\python.exe" setup.py install

