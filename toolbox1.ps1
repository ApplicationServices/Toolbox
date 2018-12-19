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
# 1.5		2018.12.18	rahd        Corrected Indenture, Versioning, Description and Capitalization acc. to Code review 
# 2.0	    2018.12.18	rahd        Finalized and released Version 2.0 + Added Function List + Removed Function GetUpTime
#
########################################################################################################################

$currentversion = "2.0"

Write-host "Importing Function Library | Toolbox1.ps1 | " -ForegroundColor Yellow -NoNewline
Write-Host "Current Version: $currentversion" -ForegroundColor Yellow

########################################################################################################################
#
# Function List:
#   StopService
#   StopServiceParallel
#   StartService
#   StartServiceParallel
#   ShowServiceStatus
#   Wait
#   ConfirmContinue
#   CreateDir
#   EditTxtFile
#   CheckFile
#   LogToEventlog
#   LogToFile
#   StopClusterGroup
#   StartClusterGroup
#   StopClusterResource
#   StartClusterResource
#   ShowClusterStatus
#   CheckUrl
#   RestartHost
#   RestartHostDelay
#   StopProcessRemote
#   StopProcessLocal
#
########################################################################################################################

########################################################################################################################
#
# Function: StopService
# Description: Stop a Windows service on a specified Windows server
#
# Parameters:
# -Service [service that should be stopped (Either Service Name or Display Name)]
# -Server [server that the service is running on]
# -Startuptype [startup mode that the service will be set to after it has been stopped, default=Disabled]
# -Force [switch to set -force parameter on stop-service commandlet]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.06	rahd       	Modified "Set-Service -Name $service" to "Set-Service -Name $servicestatus.Name"
# 0.3		2018.03.27	rahd       	Added $force switch and if ($force) statement
# 0.4		2018.12.18	rahd       	Added Parameter Validation on $Startuptype
# 0.5		2018.12.18	rahd       	Corrected indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StopService
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Service,
        [Parameter(Position=1, Mandatory=$True)][String]$Server,
        [Parameter(Position=2)][ValidateSet('Manual', 'Disabled')][String]$Startuptype = "Disabled",
        [switch]$Force
    )

    $Servicestatus = Get-Service -Name $Service -ComputerName $Server
    if ($Servicestatus.Status -eq "Stopped"){
        Write-host "The $Service on $Server is already Stopped"
    }
    Else{
        Write-Host "Stopping $Service on $Server and setting it to $startuptype"
        if ($Force){
            stop-service -inputobject $Servicestatus -Force -ErrorAction SilentlyContinue
        }
        else{
            stop-service -inputobject $Servicestatus -ErrorAction SilentlyContinue
        }
        Set-Service -Name $Servicestatus.Name -ComputerName $Server -StartupType $Startuptype
    }
}

########################################################################################################################
#
# Function: StopServiceParallel
# Description: Stop a Windows service on a specified Windows server, running as a seperate PS Job to enable parallelization
#
# Parameters:
# -Service [service that should be stopped]
# -Server [server that the service is running on, default=$env:COMPUTERNAME]
# -Startuptype [startup mode that the service will be set to after it has been stopped, default=Disabled]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Added Parameter Validation on $Startuptype
# 0.3		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StopServiceParallel
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Service,
        [Parameter(Position=1, Mandatory=$True)][String]$Server = "$env:COMPUTERNAME",
        [Parameter(Position=2)][ValidateSet('Manual', 'Disabled')][String]$Startuptype = "Disabled"
    )
    
    $Servicestatus = Get-Service -Name $Service -ComputerName $Server
    if ($Servicestatus.Status -eq "Stopped"){
        Write-host "The $Service on $Server is already Stopped"
    }
    Else{
        Write-Host "Stopping $Service on $Server and setting it to $Startuptype"
        Start-Job -ScriptBlock{stop-service -inputobject $Servicestatus}
        Set-Service -Name $Service -ComputerName $Server -StartupType $Startuptype
    }
}

########################################################################################################################
#
# Function: StartService
# Description: Start a Windows service on a specified Windows server
#
# Parameters:
# -Service [service that should be started (Either Service Name or Display Name)]
# -Server [server that the service is running on, default=$env:COMPUTERNAME]
# -Startuptype [startup mode that the service will be set to after it has been started, default=Automatic]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.06	rahd       	Modified "Set-Service -Name $service" to "Set-Service -Name $servicestatus.Name"
# 0.3		2018.12.18	rahd       	Added Parameter Validation on $Startuptype
# 0.4		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StartService
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Service,
        [Parameter(Position=1, Mandatory=$True)][String]$Server = "$env:COMPUTERNAME",
        [Parameter(Position=2)][ValidateSet('Automatic', 'AutomaticDelayedStart', 'Manual')][String]$Startuptype = "Automatic"
    )

    $Servicestatus = Get-Service -Name $Service -ComputerName $Server
    if ($Servicestatus.Status -eq "Running"){
        Write-host "The $service on $server is already Started"
    }
    Else{
        Write-Host "Starting $Service on $server and setting it to $Startuptype"
        Set-Service -Name $Servicestatus.Name -ComputerName $Server -StartupType $Startuptype
        start-service -inputobject $Servicestatus
    }
}

########################################################################################################################
#
# Function: StartServiceParallel
# Description: Start a Windows service on a specified Windows server, running as a seperate PS Job to enable parallelization
#
# Parameters:
# -Service [service that should be started]
# -Server [server that the service is running on, default=localhost]
# -Startuptype [startup mode that the service will be set to after it has been started, default=Automatic]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Added Parameter Validation on $Startuptype
# 0.3		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StartServiceParallel
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Service,
        [Parameter(Position=1, Mandatory=$True)][String]$Server = "$env:COMPUTERNAME",
        [Parameter(Position=2)][ValidateSet('Automatic', 'AutomaticDelayedStart', 'Manual')][String]$Startuptype = "Automatic"
    )

    $Servicestatus = Get-Service -Name $Service -ComputerName $Server
    if ($Servicestatus.Status -eq "Running"){
        Write-host "The $Service on $Server is already Started"
    }
    Else{
        Write-Host "Starting $Service on $Server and setting it to $Startuptype"
        Set-Service -Name $Servicestatus.Name -ComputerName $Server -StartupType $Startuptype
        Start-Job -ScriptBlock{start-service -inputobject $Servicestatus}
    }
}

########################################################################################################################
#
# Function: ShowServiceStatus
# Description: Shows the status of a service on a specified Windows server
#
# Parameters:
# -Service [service to get the status of]
# -Server [server that the service is running on, default=$env:COMPUTERNAME]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.11	rahd       	Added check for non-existant service
# 0.3		2018.03.22	rahd       	Added check for .status (Starting and Stoppping)
# 0.4		2018.09.24	rahd       	Refactored $service parameter to accept multiple comma separated services in an array
# 0.5		2018.09.24	rahd       	Refactored $server parameter to accept multiple comma separated servers in an array
# 0.6		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function ShowServiceStatus
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String[]]$Service,
        [Parameter(Position=1)][String[]]$Server = "$env:COMPUTERNAME"
    )
    foreach ($Srv in $Server){
        foreach ($Svc in $Service){
            Write-Host "$Svc service on $Srv is: " -nonewline
            if($Servicestatus = Get-Service -Name $Svc -ComputerName $Server -ErrorAction SilentlyContinue){
                if(($Servicestatus.Status -eq "Running") -or ($Servicestatus.Status -eq "Started")){
                    Write-Host -ForegroundColor Green "Started"
                }
                elseif($Servicestatus.Status -eq "Starting"){
                    Write-Host -ForegroundColor Yellow "Starting"
                }
                elseif($Servicestatus.Status -eq "Stopping"){
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
# -Seconds [number of seconds to wait]
# -Countdown [seconds to decrement the counter, default=1]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.11	rahd       	Added Optional countdown parameter to visualize progress
# 0.3		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function Wait
{
    param(
        [Parameter(Position=0, Mandatory=$True)][int]$Seconds,
        [Parameter(Position=1, Mandatory=$False)][int]$Countdown = 1
    )

    $Waittime = $Seconds
    Write-Host "Waiting for $Waittime seconds"
    do{
        Start-Sleep -s $Countdown
        $Seconds -= $Countdown
        Write-Host "Waiting for $Seconds more seconds"
    }
    Until (($Seconds -eq "0") -or ($Seconds -lt "0"))

}

########################################################################################################################
#
# Function: ConfirmContinue
# Description: Prompt user to confirm whether to continue by prompting for Y/N. If -unattended parameter was passed to
#              the powershell script then the prompt will default to Y and be skipped
#
# Parameters:
# -Message [message to print to screen before the (Y/N)]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function ConfirmContinue
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Message
    )

    if(-Not $Unattended){
        $Choice = ""
        while ($Choice -notmatch "[y|n]"){
            $Choice = read-host -prompt "$Message (Y/N)"
        }

        if ($Choice -ne "y"){
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
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function CreateDir
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Dirpath
    )

    $Direxist = test-path $Dirpath
    if ($Direxist -ne $Dirpath){
        New-Item -path $Dirpath -itemtype "Directory"
    }
    Else{
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
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
Function EditTxtFile
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$InFile,
        [Parameter(Position=1, Mandatory=$True)][String]$OutFile,
        [Parameter(Position=2, Mandatory=$True)][String]$OldReplace,
        [Parameter(Position=3, Mandatory=$True)][String]$NewReplace
    )

    $ImportFile = Get-Content -Path $InFile
    ForEach-Object{
        $ImportFile -replace $OldReplace, $NewReplace
    }   | Set-Content -Path $OutFile
}

########################################################################################################################
#
# Function: CheckFile
# Description: Searches a text file for a string
#
# Parameters:
# -TestFile [Specify the text file to be parsed]
# -TestString [Specify the String to be checked for]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2016.12.11	rahd       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function CheckFile
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$TestFile,
        [Parameter(Position=1, Mandatory=$True)][String]$TestString
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
# Function: LogToEventlog
# Description: Save the script output to the windows eventlog for Audit purpose
#
# Parameters:
# -EventlogSource [specify the eventlog application source]
# -Message [specify the message added to the eventlog entry]
# -Server [specify the server to create the log entry on Default=$env:COMPUTERNAME]
# -EventID [specify the EventID number to create in Event log Default=11223]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.18	rahd       	Added Parameter $Server for remote servers
# 0.3		2018.01.11	rahd       	Added "-ErrorAction SilentlyContinue" to New-Eventlog line
# 0.4		2018.12.18	rahd       	Added optional $EventID Parameter
# 0.5		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function LogToEventlog
{
    param(
        [Parameter(Position=0, Mandatory=$True)][string]$EventlogSource,
        [Parameter(Position=1, Mandatory=$True)][string]$Message,
        [Parameter(Position=2)][string]$Server = "$env:COMPUTERNAME",
        [Parameter(Position=3)][int]$EventID = 11223
    )
    
    # Generate $EventlogMessage
    $AdminUsername = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $LogFileExists = Get-EventLog -LogName Application | Where-Object {$_.Source -eq $EventlogSource} 
    $Newline = "`r`n"
    $EventlogMessage = "$AdminUsername$Newline$Message"
    
    # If $EventLogSource do not exist, create it
    if (! $LogFileExists){
        New-EventLog -LogName Application -Source $EventlogSource -ComputerName $Server -ErrorAction SilentlyContinue
    }

    # Write $EventlogMessage to EventLog
    Write-EventLog -LogName Application -Source $EventlogSource -EventId $EventID -EntryType Information -Message $EventlogMessage -ComputerName $Server
}

########################################################################################################################
# 
# Function: LogToFile
# Description: Save the script output to a logfile for Audit purposes
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
# 0.2		2018.12.18	rahd       	Added Parameter Validation on $Logging
# 0.3		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function LogToFile
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Logpath,
        [Parameter(Position=1, Mandatory=$True)][String]$FName,
        [Parameter(Position=2, Mandatory=$True)][ValidateSet('Enable', 'Disable')][String]$Logging
    )
    
    $Date = Get-Date -UFormat "%Y%m%d"
    $Direxist = test-path $Logpath
    $LName = "$Logpath$FName-$Date.txt"
        
    if ($Direxist -ne $Logpath){
        New-Item -path $Logpath -itemtype "Directory"
    }

    If ($Logging -eq "Enable"){
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
# -Cluster [Cluster to access]
# -ClusterGroup [Cluster group to be stopped]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StopClusterGroup
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Cluster,
        [Parameter(Position=1, Mandatory=$True)][String]$ClusterGroup
    )
    
    if ((Get-Cluster -name $Cluster | Get-ClusterGroup -name $ClusterGroup).state -eq 'offline')
    {
        Write-host "The $ClusterGroup on $Cluster is already Offline" 
    }
    Else
    {
        Write-host "Trying to stop $ClusterGroup cluster resource $Cluster"
        Get-Cluster -name $Cluster | Stop-ClusterGroup -name $ClusterGroup
    }
}

########################################################################################################################
#
# Function: StartClusterGroup
# Description: Starts a cluster Group
#
# Parameters:
# -Cluster [Cluster to access]
# -ClusterGroup [Cluster group to be started]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StartClusterGroup
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Cluster,
        [Parameter(Position=1, Mandatory=$True)][String]$ClusterGroup
    )
    
    if ((Get-Cluster -name $Cluster | Get-ClusterGroup -name $ClusterGroup).state -eq 'online')
    {
        Write-host "The $ClusterGroup on $Cluster is already Online" 
    }
    Else
    {
        Write-host "Trying to start $ClusterGroup cluster resource $Cluster"
        Get-Cluster -name $Cluster | Start-ClusterGroup -name $ClusterGroup
    }
}

########################################################################################################################
#
# Function: StopClusterResource
# Description: Stops a cluster resource
#
# Parameters:
# -Cluster [Cluster to access]
# -ClusterGroup [Cluster Group alias]
# -ClusterResource [Cluster resource to be stopped]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StopClusterResource
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Cluster,
        [Parameter(Position=1, Mandatory=$True)][String]$ClusterGroup,
        [Parameter(Position=2, Mandatory=$True)][String]$ClusterResource
    )
    
    if ((Get-Cluster -name $Cluster | Get-ClusterGroup -name $ClusterGroup | Get-ClusterResource -Name $ClusterResource).state -eq 'offline')
    {
        Write-host "The $ClusterResource in $ClusterGroup on $Cluster is already Offline" 
    }
    Else
    {
        Write-host "Trying to stop $ClusterResource in $ClusterGroup on $Cluster"
        Get-Cluster -name $Cluster | Get-ClusterGroup -name $ClusterGroup | Stop-ClusterResource -name $ClusterResource
    }
}

########################################################################################################################
#
# Function: StartClusterResource
# Description: Starts a cluster resource
#
# Parameters:
# -Cluster [Cluster to access]
# -ClusterGroup [Cluster Group alias]
# -ClusterResource [Cluster resource to be stopped]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StartClusterResource
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Cluster,
        [Parameter(Position=1, Mandatory=$True)][String]$ClusterGroup,
        [Parameter(Position=2, Mandatory=$True)][String]$ClusterResource
    )
     
    if ((Get-Cluster -name $Cluster | Get-ClusterGroup -name $ClusterGroup | Get-ClusterResource -Name $ClusterResource).state -eq 'online')
    {
        Write-host "The $ClusterResource in $ClusterGroup on $Cluster is already Online" 
    }
    Else
    {
        Write-host "Trying to start $ClusterResource in $ClusterGroup on $Cluster"
        Get-Cluster -name $Cluster | Get-ClusterGroup -name $ClusterGroup | Start-ClusterResource -name $ClusterResource
    }
}

########################################################################################################################
#
# Function: ShowClusterStatus
# Description: Check the cluster resources status
#
# Parameters:
# -Cluster [Cluster to access]
# -ClusterGroup [Cluster Group alias]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function ShowClusterStatus
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Cluster,
        [Parameter(Position=1, Mandatory=$True)][String]$ClusterGroup
    )
    
    $ClusterResource = @(Get-Cluster -name $Cluster | Get-ClusterGroup -name $ClusterGroup | Get-ClusterResource)
    
    Foreach ($Resource in $ClusterResource)
    {
        Write-Host "$ClusterGroup : $Resource is: " -nonewline
        if($ClusterResource.state -eq 'Online') {
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
# -WebUrl [Specify the url to be tested]
# -StatusCode [Specify the expected status code returned (Default=200)]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2017.12.22	rahd       	Added parameter $StatusCode
# 0.3		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
# NOTE: 	    CheckUrl requires PowerShell 3.0
########################################################################################################################
function CheckUrl
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$WebUrl,
        [Parameter(Position=1)][string]$StatusCode=200
    )

    ForEach ($Url in $WebUrl){
    Write-Host "Querying Service $Url :" -NoNewline
        if ((Invoke-WebRequest -uri $Url).statuscode -eq $StatusCode){
            Write-Host " URL OK - HTTP code: " -Foregroundcolor Green -NoNewline
            (Invoke-WebRequest -uri $Url).StatusCode
        }
        Else{
            Write-Host " URL ERROR - HTTP code: " -Foregroundcolor Red -NoNewline
            (Invoke-WebRequest -uri $Url).StatusCode
        }    
    }
}

########################################################################################################################
#
# Function: RestartHost
# Description: restart a specified windows server and wait for powershell to be available again on the host before proceeding
#
# Parameters:
# -Server [server to be restarted]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function RestartHost
{
    param(
        [Parameter(Mandatory=$True,Position=0)][String]$Server
    )

    Restart-Computer -ComputerName $Server -Force
    Write-Host "Restarting host: $Server"
}

########################################################################################################################
#
# Function: RestartHostDelay
# Description: restart a specified windows server and wait for a specified time for powershell to be available again on the host before proceeding
#
# Parameters:
# -Server [Server to be restarted]
# -Time [Specify the timeout to wait until powershell is available again before continuing, default=0]
# -Delay [Specify how often Powershell Queries Powershell on the remote machine ,default=2]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function RestartHostDelay
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Server,
        [String]$Time = 0,
        [String]$Delay = 2
    )

    Restart-Computer -ComputerName $Server -Wait -For PowerShell -Timeout $Time -Delay $Delay -Force
    Write-Host "Restarting host: $Server with timeout: $Time"
}

########################################################################################################################
#
# Function: StopProcessRemote
# Description: terminates a specified process on a server
#
# Parameters:
# -Server [server that the service is running on]
# -Processname [specify the process that will be stopped]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StopProcessRemote
{
    param(
        [Parameter(Position=0, Mandatory=$True)][String]$Server,
        [Parameter(Position=1, Mandatory=$True)][String]$Processname
    )

    $Process = get-process -ComputerName $Server| where {$_.Name -eq $Processname}

    if ($Process -ne $null){
        Write-host "The following process: $($Process.Name) will be terminated"
        invoke-command -ComputerName $Server -ScriptBlock {get-process $Process.Name |Stop-Process}
    }
    else{
        Write-host "Process is not found"
    }
}

########################################################################################################################
#
# Function: StopProcessLocal
# Description: terminates a specified process on the localhost
#
# Parameters:
# -Processname [specify the process that will be stopped]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StopProcessLocal
{
    param(
        [Parameter(Position=0,Mandatory=$True)][String]$Processname
    )

    $Process = get-process | where {$_.Name -eq $Processname}
    if ($Process -ne $null){
        Write-host "The following process: $($Process.Name) will be terminated"
        get-process $Process.Name |Stop-Process
    }
    else{
        Write-host "Process is not found"
    }
}