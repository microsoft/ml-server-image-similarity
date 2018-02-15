rem install package for both SQL and ML python
cd %1
echo in directory:  %1
"C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\PYTHON_SERVICES\python.exe" setup.py install
"C:\Program Files\Microsoft\ML Server\PYTHON_SERVER\python.exe" setup.py install
echo installed python package