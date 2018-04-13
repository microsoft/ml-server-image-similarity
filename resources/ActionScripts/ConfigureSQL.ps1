[CmdletBinding()]
param(
[parameter(Mandatory=$true, Position=1)]
[string]$ServerName,

[parameter(Mandatory=$true, Position=2)]
[string]$SolutionName,

[parameter(Mandatory=$true, Position=3)]
[string]$InstallPy,

[parameter(Mandatory=$true, Position=4)]
[string]$InstallR,

[parameter(Mandatory=$true, Position=5)]
[string]$EnableFileStream,

[parameter(Mandatory=$False, Position=6)]
[string]$isDeploy
) 


$ScriptPath = "C:\Solutions\$SolutionName\Resources\ActionScripts"


##$db = if ($Prompt -eq 'Y') {Read-Host  -Prompt "Enter Desired Database Base Name"} else {$SolutionName} 

##########################################################################

# Create Database and BaseTables 

#########################################################################

####################################################################
# Check to see If SQL Version is at least SQL 2017 and Not SQL Express 
####################################################################


$query = 
"select 
        case 
            when 
                cast(left(cast(serverproperty('productversion') as varchar), 4) as numeric(4,2)) >= 14 
                and CAST(SERVERPROPERTY ('edition') as varchar) Not like 'Express%' 
            then 'Yes'
        else 'No' end as 'isSQL17'"

$isCompatible = Invoke-Sqlcmd -ServerInstance $ServerName -Database Master -Query $query
$isCompatible = $isCompatible.Item(0)
if ($isCompatible -eq 'Yes' -and $InstallPy -eq 'Yes') {
    Write-Host " This Version of SQL is Compatible with SQL Py "

    ## Create Py Database
    Write-Host "Creating SQL Database for Py "


    Write-Host ("Using $ServerName SQL Instance") 

    ## Create PY Server DB
    $dbName = $db + "_Py"
    $SqlParameters = @("dbName=$dbName")

    $CreateSQLDB = "$ScriptPath\CreateDatabase.sql"

    $CreateSQLObjects = "$ScriptPath\CreateSQLObjectsPy.sql"
    Write-Host ("Calling Script to create the  $dbName database") 
    invoke-sqlcmd -inputfile $CreateSQLDB -serverinstance $ServerName -database master -Variable $SqlParameters


    Write-Host ("SQLServerDB $dbName Created")
    invoke-sqlcmd "USE $dbName;" 

    Write-Host ("Calling Script to create the objects in the $dbName database")
    invoke-sqlcmd -inputfile $CreateSQLObjects -serverinstance $ServerName -database $dbName


    Write-Host("SQLServerObjects Created in $dbName Database")
$OdbcName = "obdc" + $dbname
 ## Create ODBC Connection for PowerBI to Use 
Add-OdbcDsn -Name $OdbcName -DriverName "ODBC Driver 13 for SQL Server" -DsnType 'System' -Platform '64-bit' -SetPropertyValue @("Server=$ServerName", "Trusted_Connection=Yes", "Database=$dbName") -ErrorAction SilentlyContinue -PassThru

}
else 
{
    if ($isCompatible -eq 'Yes' -and $InstallPy -eq 'Yes') {"This Version of SQL is not compatible with Py , Py Code and DB's will not be Created "}
    else
    {Write-Host "There is not a py version of this solution"}
}
 

###Conifgure Database for Py 
if ($isCompatible -eq 'Yes'-and $InstallPy -eq 'Yes')
{
$PyStart = get-date
Write-Host "  

Configuring $SolutionName Solution for Py 

"
$dbname = $db + "_Py"
}

    $LoadImageData  = "$ScriptPath\LoadData.ps1  $isDeploy"
    Write-Host $LoadImageData
 if ($isDeploy -eq "No")
 {
# $LoadImageData  = "$ScriptPath\LoadData.ps1  $isDeploy"
# Write-Host $LoadImageData
Invoke-Expression $LoadImageData 
 }
 ELSE 
 {
Copy-Item "$ScriptPath\RunOnce.cmd" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
}