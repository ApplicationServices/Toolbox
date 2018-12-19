########################################################################################################################
# FILENAME:		toolbox1.ps1
# CREATED BY:	bbhj
# CREATED:		2017.06.17
# DESCRIPTION:  Application Services Powershell Function Collection Toolbox Release
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.06	rahd       	Modified Functions StopService, StartService
# 0.3		2017.12.06	rahd       	Added Function CheckFile, modified functions ShowServiceStatus, Wait
# 0.4		2017.12.18	rahd       	Modified Function LogToEventlog
# 0.5		2017.12.22	rahd        Modified Function CheckUrl
# 1.0		2018.01.12	rahd        Finalized Version 1.0 (No modifications)
# 1.0.1		2018.02.15	rahd        Added Greeting message
# 1.1		2018.03.22	rahd        Modified Function ShowServiceStatus
# 1.2		2018.03.27	rahd        Modified Function StopService
# 1.3		2018.04.04	rahd        Removed function Echo
# 1.4		2018.04.04	rahd        Modified Function ShowServiceStatus to accepts CSV input
# 1.4.1		2018.10.16	rahd        Anonymized Headers
#
########################################################################################################################

$currentversion = "1.4.1"

Write-host "Importing Function Library | Toolbox1.0.ps1 | " -ForegroundColor Yellow -NoNewline
Write-Host "Current Version: $currentversion" -ForegroundColor Yellow

########################################################################################################################
#
# Function: StopService
# Description: Stop a Windows service on a specified Windows server
#
# Parameters:
# -service [service that should be stopped (Either Service Name or Display Name)]
# -server [server that the service is running on]
# -startuptype [startup mode that the service will be set to after it has been stopped, default=Disabled]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.06	rahd       	Modified "Set-Service -Name $service" to "Set-Service -Name $servicestatus.Name"
# 0.3		2018.03.27	rahd       	Added $force switch and if ($force) statement
#
########################################################################################################################
function StopService
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$service,
    [Parameter(Mandatory=$True)]
    [String]$server,
    [String]$startuptype = "Disabled",
    [switch]$force
    )

    $servicestatus = Get-Service -Name $service -ComputerName $server
    if ($servicestatus.Status -eq "Stopped")
    {
        Write-host "The $service on $server is already Stopped"
    }
    Else {
        Write-Host "Stopping $service on $server and setting it to $startuptype"
        if ($force){
            stop-service -inputobject $servicestatus -Force -ErrorAction SilentlyContinue
        }
        else{
            stop-service -inputobject $servicestatus -ErrorAction SilentlyContinue
        }
        Set-Service -Name $servicestatus.Name -ComputerName $server -StartupType $startuptype
    }
}

########################################################################################################################
#
# Function: StopServiceParallel
# Description: Stop a Windows service on a specified Windows server
#
# Parameters:
# -service [service that should be stopped]
# -server [server that the service is running on, default=localhost]
# -startuptype [startup mode that the service will be set to after it has been stopped, default=Disabled]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function StopServiceParallel
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$service,
    [Parameter(Mandatory=$True)]
    [String]$server = "localhost",
    [String]$startuptype = "Disabled"
    )
    
    $servicestatus = Get-Service -Name $service -ComputerName $server
    if ($servicestatus.Status -eq "Stopped")
    {
        Write-host "The $service on $server is already Started"
    }
    Else {
        Write-Host "Stopping $service on $server and setting it to $startuptype"
        Start-Job -ScriptBlock{stop-service -inputobject $servicestatus}
        Set-Service -Name $service -ComputerName $server -StartupType $startuptype
    }
}

########################################################################################################################
#
# Function: StartService
# Description: Start a Windows service on a specified Windows server
#
# Parameters:
# -service [service that should be started (Either Service Name or Display Name)]
# -server [server that the service is running on, default=localhost]
# -startuptype [startup mode that the service will be set to after it has been started, default=Automatic]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.06	rahd       	Modified "Set-Service -Name $service" to "Set-Service -Name $servicestatus.Name"
#
########################################################################################################################
function StartService
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$service,
    [Parameter(Mandatory=$True)]
    [String]$server,
    [String]$startuptype = "Automatic"
    )

    $servicestatus = Get-Service -Name $service -ComputerName $server
    if ($servicestatus.Status -eq "Running")
    {
        Write-host "The $service on $server is already Started"
    }
    Else {
        Write-Host "Starting $service on $server and setting it to $startuptype"
        Set-Service -Name $servicestatus.Name -ComputerName $server -StartupType $startuptype
        start-service -inputobject $servicestatus
    }
}

########################################################################################################################
#
# Function: StartServiceParallel
# Description: Start a Windows service on a specified Windows server
#
# Parameters:
# -service [service that should be started]
# -server [server that the service is running on, default=localhost]
# -startuptype [startup mode that the service will be set to after it has been started, default=Automatic]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function StartServiceParallel
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$service,
    [Parameter(Mandatory=$True)]
    [String]$server = "localhost",
    [String]$startuptype = "Automatic"
    )

    $servicestatus = Get-Service -Name $service -ComputerName $server
    if ($servicestatus.Status -eq "Running")
    {
        Write-host "The $service on $server is already Started"
    }
    Else {
        Write-Host "Starting $service on $server and setting it to $startuptype"
        Set-Service -Name $servicestatus.Name -ComputerName $server -StartupType $startuptype
        Start-Job -ScriptBlock{start-service -inputobject $servicestatus}
    }
}

########################################################################################################################
#
# Function: ShowServiceStatus
# Description: Shows the status of a service on a specified Windows server
#
# Parameters:
# -service [service to get the status of]
# -server [server that the service is running on, default=localhost]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.11	rahd       	Added check for non-existant service
# 0.3		2018.03.22	rahd       	Added check for .status (Starting and Stoppping)
# 0.4		2018.09.24	rahd       	Refactored $service parameter to accept multiple comma separated services in an array
# 0.5		2018.09.24	rahd       	Refactored $server parameter to accept multiple comma separated servers in an array
#
########################################################################################################################
function ShowServiceStatus
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String[]]$service,
    [String[]]$server = "localhost"
    )
    foreach ($srv in $server){
        foreach ($svc in $service){
            Write-Host "$svc service on $srv is: " -nonewline
            if($servicestatus = Get-Service -Name $svc -ComputerName $server -ErrorAction SilentlyContinue){
                if(($servicestatus.Status -eq "Running") -or ($servicestatus.Status -eq "Started")){
                    Write-Host -ForegroundColor Green "Started"
                   }
                elseif($servicestatus.Status -eq "Starting"){
                    Write-Host -ForegroundColor Yellow "Starting"
                }
                elseif($servicestatus.Status -eq "Stopping"){
                    Write-Host -ForegroundColor Red "Stopping"
                }
                else{
                    Write-Host -ForegroundColor Red "Stopped"
                }
            }
            else{
                Write-Host -ForegroundColor DarkGray "Non-Existant"
            }
        }
    }
}

########################################################################################################################
#
# Function: Wait
# Description: Waits for a specified number of seconds
#
# Parameters:
# -seconds [number of seconds to wait]
# -countdown [seconds to decrement the counter]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2016.12.11	rahd       	Added Optional countdown parameter to visualize progress
#
########################################################################################################################
function Wait
{
    param
    (
    [Parameter(Mandatory=$True)]
    [int]$seconds = 0,
    [Parameter(Mandatory=$false)]
    [int]$Countdown = 1
    )

    $waittime = $seconds
    Write-Host "Waiting for $waittime seconds"
    do{
        Start-Sleep -s $Countdown
        $seconds -= $Countdown
        Write-Host "Waiting for $seconds more seconds"
    }
    Until (($seconds -eq "0") -or ($seconds -lt "0"))

}

########################################################################################################################
#
# Function: ConfirmContinue
# Description: Prompt user to confirm whether to continue by prompting for Y/N. If -unattended parameter was passed to
#              the powershell script then the prompt will default to Y and be skipped
#
# Parameters:
# -message [message to print to screen before the Y/N]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function ConfirmContinue
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$message
    )

    if(-Not $unattended)
    {
        $choice = ""
        while ($choice -notmatch "[y|n]") {
            $choice = read-host -prompt "$message (Y/N)"
        }

        if ($choice -ne "y") {
            exit
        }
    }
}

########################################################################################################################
#
# Function: CreateDir
# Description: Create directory if it does not exist
#
# Parameters:
# -Dirpath [new directory or path]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function CreateDir
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$Dirpath
    )

    $Dir_exist = test-path $Dirpath
    if ($Dir_exist -ne $Dirpath)
    {
        New-Item -path $Dirpath -itemtype "Directory"
    }
    Else
    {
        Write-host "Directory already exist $Dirpath"
    }
}

########################################################################################################################
#
# Function: EditTxtFile
# Description: Import a text file and enable the user to search and replace a string and save the file at the end.
#
# Parameters:
# -InFile [Specify the text file to be imported]
# -OutFile [Specify the text file to be exported, this can be to the same file or a new]
# -OldReplace [Search the imported document for a string]
# -NewReplace [Edit the search string and replace the string]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
Function EditTxtFile
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$InFile,
    [Parameter(Mandatory=$True)]
    [String]$OutFile,
    [Parameter(Mandatory=$True)]
    [String]$OldReplace,
    [Parameter(Mandatory=$True)]
    [String]$NewReplace
    )

    $ImportFile = Get-Content -Path $InFile
    ForEach-Object{
        $ImportFile -replace $OldReplace, $NewReplace
    } | Set-Content -Path $OutFile
}

########################################################################################################################
#
# Function: CheckFile
# Description: searches a text file for a string
#
# Parameters:
# -TestFile [Specify the text file to be parsed]
# -TestString [Specify the String to be checked for]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2016.12.11	rahd       	Initial version created
#
########################################################################################################################
function CheckFile
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$TestFile,
    [Parameter(Mandatory=$True)]
    [String]$TestString
    )
    if (select-string -Path $TestFile -Pattern $TestString){
        Write-Host "String $TestString found in $TestFile"
    }
    Else{
        Write-Host "String $TestString NOT found in $TestFile" -ForegroundColor Red
    }
}

########################################################################################################################
#
# Function: GetUptime
# Description: list each server and the current uptime since last booted
#
# Parameters:
# -server [server to get uptime information]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function GetUptime
{
      Param
      (
      [Parameter(Mandatory=$True)]
      [String]$server
      )

      if($command=Get-WmiObject win32_operatingsystem -ComputerName $Server){
          $format = [datetime]::Now - $command.ConverttoDateTime($command.lastbootuptime)
          Write-host $server "| uptime"$format.Days":"$format.Hours":"$format.Minutes" (Days:Hours:Minutes)"
     }else{
          Write-Error "Unable to retrieve WMI Object win32_operatingsystem from $Server"
     } 
}

########################################################################################################################
# 
# Function: LogToEventlog
# Description: Save the script output to the windows eventlog for Audit purpose
#
# Parameters:
# -eventlog_source [specify the eventlog application source]
# -Message [specify the message added to the eventlog entry]
# -Server [specify the server to create the log entry on Default=Localhost]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.18	rahd       	Added Parameter $Server for remote servers
# 0.3		2018.01.11	rahd       	Added "-ErrorAction SilentlyContinue" to New-Eventlog line
#
########################################################################################################################
function LogToEventlog
{
    param
    (
    [Parameter(Mandatory=$True)]
    [string]$EventlogSource,
    [Parameter(Mandatory=$True)]
    [string]$Message,
    [string]$Server = "$env:COMPUTERNAME"
    )
    
    $Admin_username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $logFileExists = Get-EventLog -LogName Application | Where-Object {$_.Source -eq $EventlogSource} 
    $Newline = "`r`n"
    $eventlogMessage = "$Admin_username$Newline$Message"
    
    
    if (! $logFileExists) {
        New-EventLog -LogName Application -Source $EventlogSource -ComputerName $Server -ErrorAction SilentlyContinue
    }
    Write-EventLog -LogName Application -Source $EventlogSource -EventId 11223 -EntryType Information -Message $EventlogMessage -ComputerName $Server
}

########################################################################################################################
# 
# Function: LogToFile
# Description: Save the script output to a logfiles for Audit purpose
#
# Parameters:
# -Logpath [path to logfile, will be generate if nothing exist]
# -FName [depecify the filename of the, the data and extention .log will be added to the file automaticly]
# -Logging [specify if logging is enable or disable]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function LogToFile
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$Logpath,
    [Parameter(Mandatory=$True)]
    [String]$FName,
    [Parameter(Mandatory=$True)]
    [String]$logging
    )
    
    $Date = Get-Date -UFormat "%Y%m%d"
    $Dir_exist = test-path $Logpath
    $LName = "$Logpath$FName-$Date.txt"
        
    if ($Dir_exist -ne $Logpath){
        New-Item -path $Logpath -itemtype "Directory"
    }

    If ($logging -eq "Enable"){
        Start-Transcript -path $LName
    }
    else{
        Stop-Transcript
    }
}

########################################################################################################################
#
# Function: StopClusterGroup
# Description: Stops a cluster Group
#
# Parameters:
# -clusterGroup [cluster group to be stopped]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function StopClusterGroup
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$cluster,
    [Parameter(Mandatory=$True)]
    [String]$clusterGroup
    )
    
    if ((Get-Cluster -name $cluster | Get-ClusterGroup -name $clusterGroup).state -eq 'offline')
    {
        Write-host "The $clusterGroup on $cluster is already Offline" 
    }
    Else
    {
        Write-host "Trying to stop $clusterGroup cluster resource $cluster"
        Get-Cluster -name $cluster | Stop-ClusterGroup -name $clusterGroup
    }
}

########################################################################################################################
#
# Function: StartClusterGroup
# Description: Starts a cluster Group
#
# Parameters:
# -clusterGroup [cluster group to be started]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function StartClusterGroup
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$cluster,
    [Parameter(Mandatory=$True)]
    [String]$clusterGroup
    )
    
    if ((Get-Cluster -name $cluster | Get-ClusterGroup -name $clusterGroup).state -eq 'online')
    {
        Write-host "The $clusterGroup on $cluster is already Online" 
    }
    Else
    {
        Write-host "Trying to start $clusterGroup cluster resource $cluster"
        Get-Cluster -name $cluster | Start-ClusterGroup -name $clusterGroup
    }
}

########################################################################################################################
#
# Function: StopClusterResource
# Description: Stops a cluster resource
#
# Parameters:
# -clusterHost [cluster host alias]
# -clusterResource [cluster resource to be stopped]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function StopClusterResource
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$cluster,
    [Parameter(Mandatory=$True)]
    [String]$clusterGroup,
    [Parameter(Mandatory=$True)]
    [String]$clusterResource
    )
    
    if ((Get-Cluster -name $cluster | Get-clusterGroup -name $clusterGroup | Get-ClusterResource -Name $clusterResource).state -eq 'offline')
    {
        Write-host "The $clusterResource in $clusterGroup on $cluster is already Offline" 
    }
    Else
    {
        Write-host "Trying to stop $clusterResource in $clusterGroup on $cluster"
        Get-Cluster -name $cluster | Get-ClusterGroup -name $clusterGroup | Stop-ClusterResource -name $clusterResource
    }
}

########################################################################################################################
#
# Function: StartClusterResource
# Description: Starts a cluster resource
#
# Parameters:
# -clusterHost [cluster host alias]
# -clusterResource [cluster resource to be stopped]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function StartClusterResource
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$cluster,
    [Parameter(Mandatory=$True)]
    [String]$clusterGroup,
    [Parameter(Mandatory=$True)]
    [String]$clusterResource
    )
     
    if ((Get-Cluster -name $cluster | Get-clusterGroup -name $clusterGroup | Get-ClusterResource -Name $clusterResource).state -eq 'online')
    {
        Write-host "The $clusterResource in $clusterGroup on $cluster is already Online" 
    }
    Else
    {
        Write-host "Trying to start $clusterResource in $clusterGroup on $cluster"
        Get-Cluster -name $cluster | Get-ClusterGroup -name $clusterGroup | Start-ClusterResource -name $clusterResource
    }
}

########################################################################################################################
#
# Function: ShowClusterStatus
# Description: Check the cluster resources status
#
# Parameters:
# -clusterhost [cluster resources status on the specified cluster]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function ShowClusterStatus
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$cluster,
    [Parameter(Mandatory=$True)]
    [String]$clusterGroup
    )
    
    $clusterResource = @(Get-Cluster -name $cluster | Get-ClusterGroup -name $clusterGroup | Get-ClusterResource)
    
    Foreach ($resource in $clusterResource)
    {
        Write-Host "$clusterGroup : $resource is: " -nonewline
        if($clusterResource.state -eq 'Online') {
            Write-Host -f Green "Online"
        }
        else {
            Write-Host -f Red "Offline"
        }
    }
}

########################################################################################################################
#
# Function: CheckUrl
# Description: Test an url request
#
# Parameters:
# -weburl [Specify the url to be tested]
# -StatusCode [Specify the expected status code returned (Default=200)]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.22	rahd       	Added parameter $StatusCode
#
########################################################################################################################
# NOTE: 	    CheckUrl requires PowerShell 3.0
########################################################################################################################
function CheckUrl
{
    param
    (
    [Parameter(Mandatory=$True)]
    [String]$weburl,
    [string]$StatusCode=200
    )

    ForEach ($url in $weburl){
    Write-Host "Querying Service $url :" -NoNewline
        if ((Invoke-WebRequest -uri $url).statuscode -eq $StatusCode)
        {
            Write-Host " URL OK - HTTP code: " -Foregroundcolor Green -NoNewline
            (Invoke-WebRequest -uri $url).StatusCode
        }
        Else
        {
            Write-Host " URL ERROR - HTTP code: " -Foregroundcolor Red -NoNewline
            (Invoke-WebRequest -uri $url).StatusCode
        }    
    }

}

########################################################################################################################
#
# Function: RestartHost
# Description: restart a specified windows server and wait for powershell to be available again on the host before proceeding
#
# Parameters:
# -server [server to be restarted]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function RestartHost
{
    param(
    [Parameter(Mandatory=$True,Position=0)]
    [String]$server
    )

    Restart-Computer -ComputerName $server -Force
    Write-Host "Restarting host: $server"
}

########################################################################################################################
#
# Function: RestartHostDelay
# Description: restart a specified windows server and wait for a specified time for powershell to be available again on the host before proceeding
#
# Parameters:
# -server [server to be restarted]
# -time [specify the timeout to wait until powershell is available again before continuing, default=0]
# -delay [default=2]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function RestartHostDelay
{
    param(
    [Parameter(Mandatory=$True,Position=0)]
    [String]$server,
    [String]$time = 0,
    [String]$delay = 2
    )

    Restart-Computer -ComputerName $server -Wait -For PowerShell -Timeout $time -Delay $delay -Force
    Write-Host "Restarting host: $server with timeout: $time"
}

########################################################################################################################
#
# Function: StopProcessRemote
# Description: terminates a specified process on a server
#
# Parameters:
# -server [server that the service is running on]
# -processname [specify the process that will be stopped]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function StopProcessRemote
{
    param(
    [Parameter(Mandatory=$True)]
    [String]$server,
    [Parameter(Mandatory=$True)]
    [String]$processname
    )

    $process = get-process -ComputerName $server| where {$_.Name -eq $processname}
    if ($process -ne $null){
    
        Write-host "The following process: $($process.Name) will be terminated"
        invoke-command -ComputerName $server -ScriptBlock {get-process $process.Name |Stop-Process}
    }
    else{
        Write-host "process is not found"
    }
}

########################################################################################################################
#
# Function: StopProcessLocal
# Description: terminates a specified process the localhost
#
# Parameters:
# -processname [specify the process that will be stopped]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
#
########################################################################################################################
function StopProcessLocal
{
    param(
    [Parameter(Mandatory=$True)]
    [String]$processname
    )

    $process = get-process | where {$_.Name -eq $processname}
    if ($process -ne $null){
    
        Write-host "The following process: $($process.Name) will be terminated"
        get-process $process.Name |Stop-Process
    }
    else{
        Write-host "process is not found"
    }
}