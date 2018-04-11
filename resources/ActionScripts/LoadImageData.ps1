$Install = Read-Host -Prompt 'Would you like to play a game?'

If($Install -eq "Yes" -or $Install -eq "Y")
{
$setupLog = "c:\tmp\ConfigureImageSimilarity.txt"
Start-Transcript -Path $setupLog 

##Paramaters to pass to ConfigureSQL.ps1
$StartTime = Get-Date
$ServerName = $Query = "SELECT SERVERPROPERTY('ServerName')"
    $si = invoke-sqlcmd -Query $Query
    $si = $si.Item(0)
    $serverName = if([string]::IsNullOrEmpty($servername)) {$si}
Write-Host ("ServerName set to $ServerName")
$dbName = "ImageSimilarity_Py" 
$src = "C:\Solutions\ImageSimilarity\Data"
$dst = "\\$ServerName\MSSQLSERVER\FileTableData\ImageStore\"

$Query =    "INSERT INTO [ImageSimilarity_Py].[dbo].[query_images] VALUES (0,'C:\Solutions\ImageSimilarity\data\dotted\81.jpg')"
            # INSERT INTO [ImageSimilarity_Py].[dbo].[query_images] VALUES (0,'C:\Solutions\ImageSimilarity\data\fashionTexture\floral\2562.jpg')
            # INSERT INTO [ImageSimilarity_Py].[dbo].[query_images] VALUES (0,'C:\Solutions\ImageSimilarity\data\fashionTexture\leopard\3093.jpg')"

Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query 


Write-Host "Copy Image Files into FileStream Table"
    Set-Location "C:\Solutions\ImageSimilarity\Data"
    Invoke-Expression ".\import_data.bat"
    $src = "$Src\dotted"         
    copy-item -Force -Recurse -Verbose -PassThru $src $dst -ErrorAction SilentlyContinue
    copy-item -Force -Recurse $src $dst -ErrorAction SilentlyContinue
    $src = "$Src\leopard"         
    copy-item -Force -Recurse -Verbose -PassThru $src $dst -ErrorAction SilentlyContinue
    copy-item -Force -Recurse $src $dst -ErrorAction SilentlyContinue
    $src = "$Src\striped"         
    copy-item -Force -Recurse -Verbose -PassThru $src $dst -ErrorAction SilentlyContinue
    copy-item -Force -Recurse $src $dst -ErrorAction SilentlyContinue

Write-Host " Image Files Copied to FileStream Table" 

Write-Host (" Training Model and Scoring Data...")

Set-Location "C:\Solutions\ImageSimilarity\Python"
Invoke-Expression ".\run_image_similarity.bat"





$Pyend = Get-Date

$Duration = New-TimeSpan -Start $PyStart -End $Pyend 
Write-Host ("Py Server Configured in $Duration")

}
ELSE
{"Why Not?"}