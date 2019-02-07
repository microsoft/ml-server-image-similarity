param(
[parameter(Mandatory=$false, Position=1)]
[ValidateNotNullOrEmpty()] 
[string]$isDeploy,
[parameter(Mandatory=$false, Position=2)]
[ValidateNotNullOrEmpty()] 
[string]$Prompt
)





Write-Host " 
Starting the Image Similarity Data Flow."
Write-Host " 
This script will download all images listed in ""c:\Solutions\ImageSimilarity\fashion_texture_urls.tsv"" 
onto your machine, upload them to SQL and execute the end-to-end workflow to train an image similarity model.
This portion of the script will take about 6 minutes to complete.
"
if($Prompt -ne "N")
{
$Install = Read-Host -Prompt "Please respond YES to continue"
}
If($Install -eq "Yes" -or $Install -eq "Y" -or $Prompt -eq "N")
{
    $setupLog = "c:\tmp\setup_log.txt"
    Start-Transcript -Path $setupLog -Append


    ##Copy Url to Start Menu
if ($isDeploy -eq "Yes")
    {
    Copy-Item "C:\Solutions\ImageSimilarity\Resources\ActionScripts\SolutionHelp.url" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
    }

##Paramaters to pass to ConfigureSQL.ps1
$StartTime = Get-Date
 $Query = "SELECT SERVERPROPERTY('ServerName')"
    $ServerName  = invoke-sqlcmd -Query $Query
    $ServerName = $ServerName.Item(0)
Write-Host ("ServerName set to $ServerName")
$dbName = "ImageSimilarity_Py" 
$src = "C:\Solutions\ImageSimilarity\Data"
$dst = "\\$ServerName\MSSQLSERVER\FileTableData\ImageStore\"

$Query =    "INSERT INTO [ImageSimilarity_Py].[dbo].[query_images] VALUES (0,'C:\Solutions\ImageSimilarity\data\dotted\81.jpg')
            INSERT INTO [ImageSimilarity_Py].[dbo].[query_images] VALUES (0,'C:\Solutions\ImageSimilarity\data\striped\379.jpg')
            INSERT INTO [ImageSimilarity_Py].[dbo].[query_images] VALUES (0,'C:\Solutions\ImageSimilarity\data\leopard\147.jpg')"

Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query 


Write-Host "Copy Image Files into FileStream Table"
    Set-Location "C:\Solutions\ImageSimilarity\Data"
    Invoke-Expression ".\download_data.bat"
    $src = ".\dotted"         
    
    copy-item -Force -Recurse $src $dst -ErrorAction SilentlyContinue
    $src = ".\leopard"         

    copy-item -Force -Recurse $src $dst -ErrorAction SilentlyContinue
    $src = ".\striped"         

    copy-item -Force -Recurse $src $dst -ErrorAction SilentlyContinue

Write-Host ("
    Image Files Copied to FileStream Table" )

Write-Host ("
    Training Model and Scoring Data...")

# Set-Location "C:\Solutions\ImageSimilarity\Python"
# Invoke-Expression ".\run_image_similarity.bat"

$query = "EXEC Inital_Run_Once_Py"
Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0


$Pyend = Get-Date

$Duration = New-TimeSpan -Start $StartTime -End $Pyend 
Write-Host ("
    Data Loaded and Trained in $Duration")


    ##Launch HelpURL 
    
 

##Remove Run Once
Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\RunOnce.cmd" -ErrorAction SilentlyContinue
if($Prompt -ne "N")
{
    Read-Host ("
    Images have been loaded into SQL and the model has been trained and the data has been scored. 


    Press the Enter Key to continue")
}
Start-Process https://microsoft.github.io/ml-server-image-similarity/

 
}
ELSE 
{
Start-Process https://microsoft.github.io/ml-server-image-similarity/first_time.html
}
