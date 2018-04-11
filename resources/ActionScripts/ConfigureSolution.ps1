$setupLog = "c:\tmp\ConfigureImageSimilarity.txt"
Start-Transcript -Path $setupLog 

##Paramaters to pass to ConfigureSQL.ps1
$StartTime = Get-Date
$SolutionName = "ImageSimilarity"
$InstallPy = "Yes"
$InstallR = "Yes"
$EnableFileStream = "Yes"
$Prompt = "N"


$Query = "SELECT SERVERPROPERTY('ServerName')"
$si = invoke-sqlcmd -Query $Query
$si = $si.Item(0)
$serverName = if([string]::IsNullOrEmpty($servername)) {$si}
Write-Host ("ServerName set to $ServerName")


$ConfigureSql = "C:\Solutions\$SolutionName\Resources\ActionScripts\ConfigureSQL.ps1  $ServerName $SolutionName $InstallPy $InstallR $EnableFileStream $Prompt"
Invoke-Expression $ConfigureSQL 

Write-Host "Done with configuration changes to SQL Server"

$endTime = Get-Date

Write-Host -foregroundcolor 'green'(" $SolutionFullName Workflow Finished Successfully!")
$Duration = New-TimeSpan -Start $StartTime -End $EndTime 
Write-Host -ForegroundColor 'green'(" Total Deployment Time = $Duration") 


Stop-Transcript

## Close Powershell if not run on 
   ## if ($baseurl)
   Exit-PSHostProcess
