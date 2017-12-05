<#
.SYNOPSIS
Script to ranking the candidate images for query images based on the similarity between them, using SQL Server and MRS.
#>

[CmdletBinding()]
param(

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$ServerName = "",

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$DBName = "",

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$FeatureTableName = "",

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$TrainingTableName = "",

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$TestingTableName = "",

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$EvaluationTableName = "",

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$ScoresTableName = "",

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$ModelTableName = "",

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$QueryTableName = "",

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$ResultsTableName = "",

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$TrainTestRatio,

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$QueryImgPerCat,

[parameter(Mandatory=$true,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$NegImgsPerQueryImg,

[parameter(Mandatory=$false,ParameterSetName = "IS")]
[ValidateNotNullOrEmpty()]
[String]
$dataPath = ""
)


$filePath = Get-Location
$scriptPath = $filePath.Path+ "\"

if ($dataPath -eq "")
{
$parentPath = Split-Path -parent $filePath
$dataPath = $parentPath + "\data\fashionTexture\"
}


##########################################################################
# Function wrapper to invoke SQL command
##########################################################################
function ExecuteSQL
{
param(
[String]
$sqlscript
)
    Invoke-Sqlcmd -ServerInstance $ServerName  -Database $DBName -InputFile $sqlscript -QueryTimeout 200000
}


##########################################################################
# Function wrapper to invoke SQL query
##########################################################################
function ExecuteSQLQuery
{
param(
[String]
$sqlquery
)
    Invoke-Sqlcmd -ServerInstance $ServerName -Database $DBName -Query $sqlquery -QueryTimeout 200000
}

##########################################################################
# Check if the SQL server/database exists
##########################################################################
$query = "IF NOT EXISTS(SELECT * FROM sys.databases WHERE NAME = '$DBName') CREATE DATABASE $DBName WITH FILESTREAM ( NON_TRANSACTED_ACCESS = FULL, DIRECTORY_NAME = N'FileTableData' )"
Invoke-Sqlcmd -ServerInstance $ServerName -Query $query -ErrorAction SilentlyContinue
if ($? -eq $false)
{
    Write-Host -ForegroundColor Red "Failed the test to connect to SQL server: $ServerName database: $DBName !"
    Write-Host -ForegroundColor Red "Please make sure: `n`t 1. SQL Server: $ServerName exists;
                                     `n`t 2. SQL user: $username has the right credential for SQL server access."
    exit
}

$query = "USE $DBName;"
Invoke-Sqlcmd -ServerInstance $ServerName -Query $query

##########################################################################
# Development
##########################################################################
# create the stored procedure for creating the FileTable
$script = $scriptPath + "create_file_table.sql"
ExecuteSQL $script

# invoke the stored procedure to create the FileTable
Write-Host -ForeGroundColor 'Cyan' ("Creating SQL FileTable...")
$query = "Exec CreateTables"
ExecuteSQLQuery $query

## copy the images into FileTable directory
Write-Host -ForeGroundColor 'green' ("Saving images into SQL FileTale...")

$imageDir = $dataPath + "\*"

$filetableDir = "\\localhost\MSSQLSERVER\FileTableData\ImageStore"

Copy-Item $imageDir $filetableDir -recurse

# create the stored procedure for featuring images
$script = $scriptPath + "sp_01_featurize_images.sql"
ExecuteSQL $script

# invoke the stored procedure to featurize images
Write-Host -ForeGroundColor 'Cyan' ("Featurizing images...")
$query = "Exec FeaturizeImages 'ImageStore', $FeatureTableName"
ExecuteSQLQuery $query

# create the stored procedure for prepareing data
$script = $scriptPath + "sp_02_prepare_data.sql"
ExecuteSQL $script

# invoke the stored procedure to prepare data
Write-Host -ForeGroundColor 'Cyan' ("Preparing data...")
$query = "Exec PrepareData $FeatureTableName, $TrainingTableName, $TestingTableName, $EvaluationTableName, $TrainTestRatio, $QueryImgPerCat, $NegImgsPerQueryImg"
ExecuteSQLQuery $query

# create the stored procedure for training and evaluation
$script = $scriptPath + "sp_03_train_model.sql"
ExecuteSQL $script

# invoke the stored procedure to train a classifier
Write-Host -ForeGroundColor 'Cyan' ("Training classifier...")
$query = "Exec TrainClassifier $FeatureTableName, $TrainingTableName, $TestingTableName, $ScoresTableName, $ModelTableName"
ExecuteSQLQuery $query

# create the stored procedure for evaluating the ranker system
$script = $scriptPath + "sp_04_evaluate_model.sql"
ExecuteSQL $script

# invoke the stored procedure to evaluate the ranker system
Write-Host -ForeGroundColor 'Cyan' ("Evaluating the ranker system...")
$query = "Exec EvaluateModel $ScoresTableName, $EvaluationTableName"
ExecuteSQLQuery $query

# create the stored procedure for ranking the candidates for query images
$script = $scriptPath + "sp_05_rank_candidates.sql"
ExecuteSQL $script

# invoke the stored procedure to rank the candidates for query images
Write-Host -ForeGroundColor 'Cyan' ("Ranking candidates for query images...")
$query = "Exec RankCandidates 10, $QueryTableName, $ScoresTableName, $ModelTableName, $ResultsTableName"
ExecuteSQLQuery $query

Write-Host -ForeGroundColor 'green' ("Finished!")