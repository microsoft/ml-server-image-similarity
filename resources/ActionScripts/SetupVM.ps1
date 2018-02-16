

[CmdletBinding()]
param(
[parameter(Mandatory=$false, Position=1)]
[ValidateNotNullOrEmpty()] 
[string]$serverName,

[parameter(Mandatory=$false, Position=2)]
[ValidateNotNullOrEmpty()] 
[string]$username,

[parameter(Mandatory=$false, Position=3)]
[ValidateNotNullOrEmpty()] 
[string]$password,

[parameter(Mandatory=$false, Position=4)]
[ValidateNotNullOrEmpty()] 
[string]$Prompt
)
$startTime = Get-Date

$Query = "SELECT SERVERPROPERTY('ServerName')"
$si = invoke-sqlcmd -Query $Query
$si = $si.Item(0)

$serverName = if([string]::IsNullOrEmpty($servername)) {$si}

$setupLog = "c:\tmp\setup_log.txt"
Start-Transcript -Path $setupLog -Append
$startTime = Get-Date
Write-Host  "Start time:" $startTime 


Write-Host "ServerName set to $ServerName"

#$Prompt= if ($Prompt -match '^y(es)?$') {'Y'} else {'N'}
$Prompt = 'N'


##Change Values here for Different Solutions 
$SolutionName = "ImageSimilarity"
$SolutionFullName = "ml-server-image-similarity" 
$JupyterNotebook = "TestModel.ipynb"
$Shortcut = "SolutionHelp.url"


### DON'T FORGET TO CHANGE TO MASTER LATER...
$Branch = "dev" 
$InstallR = 'No'  ## If Solution has a R Version this should be 'Yes' Else 'No'
$InstallPy = 'Yes' ## If Solution has a Py Version this should be 'Yes' Else 'No'
$SampleWeb = 'No' ## If Solution has a Sample Website  this should be 'Yes' Else 'No' 
$EnableFileStream = 'Yes' ## If Solution Requires FileStream DB this should be 'Yes' Else 'No' 
$UsePowerBI = 'No' ## If Solution uses PowerBI
$Prompt = 'N'
$MixedAuth = 'No'




###These probably don't need to change , but make sure files are placed in the correct directory structure 
$solutionTemplateName = "Solutions"
$solutionTemplatePath = "C:\" + $solutionTemplateName
$checkoutDir = $SolutionName
$SolutionPath = $solutionTemplatePath + '\' + $checkoutDir
$desktop = "C:\Users\Public\Desktop\"
$scriptPath = $SolutionPath + "\Resources\ActionScripts\"
$SolutionData = $SolutionPath + "\Data\"




##########################################################################
#Clone Data from GIT
##########################################################################


$clone = "git clone --branch $Branch --single-branch https://github.com/Microsoft/$SolutionFullName $solutionPath"

if (Test-Path $SolutionPath) { Write-Host " Solution has already been cloned"}
ELSE {Invoke-Expression $clone}

If ($InstalR -eq 'Yes')
{
Write-Host "Installing R Packages"
Set-Location "C:\Solutions\$SolutionName\Resources\ActionScripts\"
# install R Packages
Rscript install.R 
}


#################################################################
##DSVM Does not have SQLServer Powershell Module Install or Update 
#################################################################



Write-Host "Installing SQLServer Power Shell Module or Updating to latest "

# if (Get-Module -ListAvailable -Name SQLServer) {Update-Module -Name "SQLServer"}
#  else 
#   {
#     Install-Module -Name SQLServer -Scope AllUsers -AllowClobber -Force
#     Import-Module -Name SQLServer
#   }

#   if (Get-Module -ListAvailable -Name SQLServer) {Write-Host "SQL Powershell Module Already Installed"}
#     ELSE 
   {
     Install-Module -Name SQLServer -Scope AllUsers -AllowClobber -Force
     Import-Module SqlServer -Version 21.0.17178
   }




## if FileStreamDB is Required Alter Firewall ports for 139 and 445
if ($EnableFileStream -eq 'Yes')
    {
    netsh advfirewall firewall add rule name="Open Port 139" dir=in action=allow protocol=TCP localport=139
    netsh advfirewall firewall add rule name="Open Port 445" dir=in action=allow protocol=TCP localport=445
    Write-Host "Firewall has been opened for filestream access..."
    }

 




############################################################################################
#Configure SQL to Run our Solutions 
############################################################################################

#Write-Host -ForegroundColor 'Cyan' " Switching SQL Server to Mixed Mode"


### Change Authentication From Windows Auth to Mixed Mode 
If ($MixedAuth -eq 'Yes')
{ Write-Host "Changing SQL Authentication to Mixed Mode"
Invoke-Sqlcmd -Query "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;" -ServerInstance "LocalHost" 
}

Write-Host "Configuring SQL to allow running of External Scripts "
### Allow Running of External Scripts , this is to allow R Services to Connect to SQL
Invoke-Sqlcmd -Query "EXEC sp_configure  'external scripts enabled', 1"

### Force Change in SQL Policy on External Scripts 
Invoke-Sqlcmd -Query "RECONFIGURE WITH OVERRIDE" 
Write-Host " SQL Server Configured to allow running of External Scripts "

### Enable FileStreamDB if Required by Solution 
if ($EnableFileStream -eq 'Yes') 
    {
# Enable FILESTREAM
        $instance = "MSSQLSERVER"
        $wmi = Get-WmiObject -Namespace "ROOT\Microsoft\SqlServer\ComputerManagement14" -Class FilestreamSettings | where-object {$_.InstanceName -eq $instance}
        $wmi.EnableFilestream(3, $instance) 
        Stop-Service "MSSQ*" -Force
        Start-Service "MSSQ*"
 
    
        #Import-Module "sqlps" -DisableNameChecking
        Invoke-Sqlcmd "EXEC sp_configure filestream_access_level, 2"
        Invoke-Sqlcmd "RECONFIGURE WITH OVERRIDE"
        Stop-Service "MSSQ*"
        Start-Service "MSSQ*"
    }
ELSE
    { 
    Write-Host "Restarting SQL Services "
    ### Changes Above Require Services to be cycled to take effect 
    ### Stop the SQL Service and Launchpad wild cards are used to account for named instances  
    Restart-Service -Name "MSSQ*" -Force
}
### Start the SQL Service 
#Start-Service -Name "MSSQ*"
#Write-Host -ForegroundColor 'Cyan' " SQL Services Restarted"

if($MixedAuth -eq 'Yes')
{
$Query = "CREATE LOGIN $username WITH PASSWORD=N'$password', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
Invoke-Sqlcmd -Query $Query -ErrorAction SilentlyContinue

$Query = "ALTER SERVER ROLE [sysadmin] ADD MEMBER $username"
Invoke-Sqlcmd -Query $Query -ErrorAction SilentlyContinue
}
####Instal Python 


if($InstallPy -eq 'Yes')
{
#### Section for ImageSimilarity - install python package and copy resnet files
$src= "C:\Program Files\Microsoft\ML Server\PYTHON_SERVER\Lib\site-packages\microsoftml\mxLibs\resnet*"
$dest= "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\PYTHON_SERVICES\Lib\site-packages\microsoftml\mxLibs"
copy-item $src $dest
Write-Host "Done with copying ResNet models"

# install package for both SQL and ML python
Set-Location $SolutionPath\Resources\ActionScripts
$installPyPkg = ".\installPyPkg.bat c:\Solutions\ImageSimilarity"
Invoke-Expression $installPyPkg 
Write-Host "Done installing image_similarity package"

##### End of section for ImageSimilarity

}


###Install SQL CU 
{Write-Host " Checking SQL CU Version If Behind install Latest CU...."}

$Query = "SELECT CASE 
WHEN  
    (RIGHT(CAST(SERVERPROPERTY('ProductUpdateLevel') as varchar),1) > 1)
    AND 
    (SELECT Left(CAST(SERVERPROPERTY('productversion') as varchar),2))>= 14
THEN 1 
ELSE 0 
END "
$RequireCuUpdate = Invoke-Sqlcmd -Query $Query
$RequireCuUpdate = $RequireCuUpdate.Item(0)

IF ($RequireCuUpdate -eq 0) 
{
WRITE-Host "CU Needs Updating will be done at end of Script"
}
ELSE 
{Write-Host "CU is Current" }



####Run Configure SQL to Create Databases and Populate with needed Data
$ConfigureSql = "C:\Solutions\$SolutionName\Resources\ActionScripts\ConfigureSQL.ps1  $ServerName $SolutionName $InstallPy $InstallR $EnableFileStream $Prompt"
Invoke-Expression $ConfigureSQL 

Write-Host "Done with configuration changes to SQL Server"




If ($UsePowerBI -eq 'Yes') 
{
    Write-Host "Installing latest Power BI..."
    # Download PowerBI Desktop installer
    Start-BitsTransfer -Source "https://go.microsoft.com/fwlink/?LinkId=521662&clcid=0x409" -Destination powerbi-desktop.msi

    # Silently install PowerBI Desktop
    msiexec.exe /i powerbi-desktop.msi /qn /norestart  ACCEPT_EULA=1

    if (!$?) 
    {
        Write-Host -ForeGroundColor Red " Error installing Power BI Desktop. Please install latest Power BI manually."
    }
}



##Create Shortcuts and Autostart Help File 
Copy-Item "$ScriptPath\$Shortcut" C:\Users\Public\Desktop\
Copy-Item "$ScriptPath\$Shortcut" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
Write-Host -ForeGroundColor cyan " Help Files Copied to Desktop"


$WsShell = New-Object -ComObject WScript.Shell
$shortcut = $WsShell.CreateShortcut($desktop + $checkoutDir + ".lnk")
$shortcut.TargetPath = $solutionPath
$shortcut.Save()


if($MixedAuth -eq 'Yes')
{
    If($InstallR = 'Yes')
        {
        ## copy Jupyter Notebook files
        Move-Item $SolutionPath\R\$JupyterNotebook  c:\tmp\
        sed -i "s/XXYOURSQLPW/$password/g" c:\tmp\$JupyterNotebook
        sed -i "s/XXYOURSQLUSER/$username/g" c:\tmp\$JupyterNotebook
        Move-Item  c:\tmp\$JupyterNotebook $SolutionPath\R\
        }

    if ($InstallPy -eq "Yes")
        {
        Move-Item $SolutionPath\Python\$JupyterNotebook  c:\tmp\
        sed -i "s/XXYOURSQLPW/$password/g" c:\tmp\$JupyterNotebook
        sed -i "s/XXYOURSQLUSER/$username/g" c:\tmp\$JupyterNotebook
        Move-Item  c:\tmp\$JupyterNotebook $SolutionPath\Python\
        }
}


# install modules for sample website
if($SampleWeb  -eq "Yes")
    {
    Set-Location $SolutionPath\Website\
    npm install
    Move-Item $SolutionPath\Website\server.js  c:\tmp\
    sed -i "s/XXYOURSQLPW/$password/g" c:\tmp\server.js
    sed -i "s/XXYOURSQLUSER/$username/g" c:\tmp\server.js
    Move-Item  c:\tmp\server.js $SolutionPath\Website
    }



IF ($RequireCuUpdate -eq 0) 
{
WRITE-Host "Downloading Latest CU"

Start-BitsTransfer -Source "https://download.microsoft.com/download/C/4/F/C4F908C9-98ED-4E5F-88D5-7D6A5004AEBD/SQLServer2017-KB4052987-x64.exe" -Destination c:\tmp\SQLServer2017-KB4052987-x64.exe  

Write-Host "CU has been Downloaded now to install , go have a cocktail as this takes a while"

Invoke-Expression "c:\tmp\SQLServer2017-KB4052987-x64.exe /q /IAcceptSQLServerLicenseTerms /IACCEPTPYTHONLICENSETERMS /IACCEPTROPENLICENSETERMS /Action=Patch /InstanceName=MSSQLSERVER"
Write-Host "CU Install has commenced"
Write-Host " Powershell time to take a nap"
Start-Sleep -s 600
Write-Host " Powershell nap time is over"

# Stop-Service "MSSQ*" -Force
# Start-Service "MSSQ*"

##Invoke-Expression "shutdown /f /r"

##Write-Host "CU has been Installed"
}

##Launch HelpURL 
Start-Process "https://microsoft.github.io/$SolutionFullName/Typical.html"

$endTime = Get-Date

Write-Host -foregroundcolor 'green'(" $SolutionFullName Workflow Finished Successfully!")
$Duration = New-TimeSpan -Start $StartTime -End $EndTime 
Write-Host -ForegroundColor 'green'(" Total Deployment Time = $Duration") 


Stop-Transcript

## Close Powershell 
Exit-PSHostProcess
EXIT 