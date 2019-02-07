

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
[string]$Prompt,

[parameter(Mandatory=$false, Position=5)]
[ValidateNotNullOrEmpty()] 
[string]$isDeploy
)
$startTime = Get-Date




###Check to see if user is Admin

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator")
        
if ($isAdmin -eq 'True') {


$setupLog = "c:\tmp\setup_log.txt"
Start-Transcript -Path $setupLog
$startTime = Get-Date
Write-Host  "Start time:" $startTime

$isDeploy = if($isDeploy -eq "Yes") {"Yes"} ELSE {"No"}

#$Prompt= if ($Prompt -match '^y(es)?$') {'Y'} else {'N'}

##Change Values here for Different Solutions 
$SolutionName = "ImageSimilarity"
$SolutionFullName = "ml-server-image-similarity" 
$Shortcut = "SolutionHelp.url"


### DON'T FORGET TO CHANGE TO MASTER LATER...
$Branch = "master" 
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


if (Get-Module -ListAvailable -Name SQLServer) 
{Update-Module -Name "SQLServer" -MaximumVersion 21.0.17199}
Else 
{Install-Module -Name SqlServer -RequiredVersion 21.0.17199 -Scope AllUsers -AllowClobber -Force}

#Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
Import-Module -Name SqlServer -MaximumVersion 21.0.17199 -Force


## if FileStreamDB is Required Alter Firewall ports for 139 and 445
if ($EnableFileStream -eq 'Yes')
    {
    netsh advfirewall firewall add rule name="Open Port 139" dir=in action=allow protocol=TCP localport=139
    netsh advfirewall firewall add rule name="Open Port 445" dir=in action=allow protocol=TCP localport=445
Write-Host (
"Firewall has been opened for filestream access")
    }


############################################################################################
#Configure SQL to Run our Solutions 
############################################################################################


if([string]::IsNullOrEmpty($servername))
{
$Query = "SELECT SERVERPROPERTY('ServerName')"
$si = invoke-sqlcmd -Query $Query
$si = $si.Item(0)
$servername = $si
}
ELSE 
{$servername} 

Write-Host ("
ServerName set to $ServerName")


### Change Authentication From Windows Auth to Mixed Mode 
If ($MixedAuth -eq 'Yes')
{ Write-Host "Changing SQL Authentication to Mixed Mode"
Invoke-Sqlcmd -Query "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;" -ServerInstance "LocalHost" 
}

Write-Host ("
    Configuring SQL to allow running of External Scripts")
### Allow Running of External Scripts , this is to allow R Services to Connect to SQL
Invoke-Sqlcmd -Query "EXEC sp_configure  'external scripts enabled', 1"

### Force Change in SQL Policy on External Scripts 
Invoke-Sqlcmd -Query "RECONFIGURE WITH OVERRIDE" 
Write-Host ("
    SQL Server Configured to allow running of External Scripts")

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
    Write-Host ("
        Restarting SQL Services")
    ### Changes Above Require Services to be cycled to take effect 
    ### Stop the SQL Service and Launchpad wild cards are used to account for named instances  
    Restart-Service -Name "MSSQ*" -Force
}


if($MixedAuth -eq 'Yes')
{
$Query = "CREATE LOGIN $username WITH PASSWORD=N'$password', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
Invoke-Sqlcmd -Query $Query -ErrorAction SilentlyContinue

$Query = "ALTER SERVER ROLE [sysadmin] ADD MEMBER $username"
Invoke-Sqlcmd -Query $Query -ErrorAction SilentlyContinue
}


###Unbind Python 
Set-Location $scriptPath
invoke-expression ".\UpdateMLServer.bat"
Write-Host "ML Server has been updated"

####Instal Python 

if($InstallPy -eq 'Yes')
{
#### Section for ImageSimilarity - install python package and copy resnet files
$src= "C:\Program Files\Microsoft\ML Server\PYTHON_SERVER\Lib\site-packages\microsoftml\mxLibs\resnet*"
$dest= "C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\PYTHON_SERVICES\Lib\site-packages\microsoftml\mxLibs"
copy-item $src $dest
Write-Host ("
Done with copying ResNet models")

# install package for both SQL and ML python
Set-Location $SolutionPath\Resources\ActionScripts
$installPyPkg = ".\installPyPkg.bat c:\Solutions\ImageSimilarity"
Invoke-Expression $installPyPkg 
Write-Host ("
Done installing image_similarity package")

##### End of section for ImageSimilarity
}


####Run Configure SQL to Create Databases and Populate with needed Data
#$ConfigureSql = "C:\Solutions\$SolutionName\Resources\ActionScripts\ConfigureSQL.ps1  $ServerName $SolutionName $InstallPy $InstallR $EnableFileStream"
$ConfigureSql = "$ScriptPath\ConfigureSQL.ps1  $ServerName $SolutionName $InstallPy $InstallR $EnableFileStream"
Invoke-Expression $ConfigureSQL 

Write-Host "Done with configuration changes to SQL Server"

Remove-Item  "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\$Shortcut" -ErrorAction SilentlyContinue

#$LoadImageData  = "C:\Solutions\$SolutionName\Resources\ActionScripts\LoadImageData.ps1  $isDeploy"
$LoadImageData  = "$ScriptPath\LoadImageData.ps1  $isDeploy $Prompt"


##Create Shortcuts and Autostart Help File 
Copy-Item "$ScriptPath\$Shortcut" C:\Users\Public\Desktop\



if ($isDeploy -eq "No") 
    {Invoke-Expression $LoadImageData}
    ELSE 
    {
    Copy-Item "$ScriptPath\RunOnce.cmd" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
    }



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




$WsShell = New-Object -ComObject WScript.Shell
$shortcut = $WsShell.CreateShortcut($desktop + $checkoutDir + ".lnk")
$shortcut.TargetPath = $solutionPath
$shortcut.Save()


# install modules for sample website
if($SampleWeb  -eq "Yes")
    {
    Set-Location $SolutionPath\Website\
    npm install
    (Get-Content $SolutionPath\Website\server.js).replace('XXYOURSQLPW', $password) | Set-Content $SolutionPath\Website\server.js
    (Get-Content $SolutionPath\Website\server.js).replace('XXYOURSQLUSER', $username) | Set-Content $SolutionPath\Website\server.js
    }

# if ($isDeploy -eq "No") 
#     {
#     Write-Host -NoNewLine 'Press any key to continue...';
#     $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
#     }


$endTime = Get-Date

Write-Host (" $SolutionFullName Workflow Finished Successfully!")
$Duration = New-TimeSpan -Start $StartTime -End $EndTime 
Write-Host (" Total Deployment Time = $Duration") 






Stop-Transcript

## Close Powershell if not run on 
   ## if ($baseurl)
   Exit-PSHostProcess
   EXIT

   
##Launch HelpURL 
if(!$isDeploy -eq "Yes") 
    {
    Start-Process https://microsoft.github.io/ml-server-image-similarity/
    }

}

ELSE 
{ 
   Write-Host "To install this Solution you need to run Powershell as an Administrator. This program will close automatically in 20 seconds"
   Start-Sleep -s 20
## Close Powershell 
Exit-PSHostProcess
EXIT }