########################################################################################################################
# FILENAME:		toolbox2.ps1
# CREATED BY:	rahd
# CREATED:		2018.01.22
# DESCRIPTION:  Application Services Powershell Function Collection Toolbox 2 Release
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.01.22	rahd       	Initial version created
# 0.2		2018.01.22	rahd       	Added functions CheckConnection, TestPort, TestShare
# 0.3		2018.01.23	rahd       	Modified function GetUpTime
# 0.4		2018.01.25	rahd       	Added function CheckDiskSpace
# 0.5		2018.02.07	rahd       	Added functions StartIISSite, StopIISSite, CheckIISSite
# 0.6		2018.02.12	rahd       	Added function TestSQLConnection
# 0.7		2018.02.13	rahd       	Modified function TestPort
# 0.8		2018.02.14	rahd       	Modified functions CheckConnection, CheckDiskSpace, StartIISSite, StopIISSite
# 0.8.1		2018.02.15	rahd        Added Greeting message
# 0.9		2018.02.16	rahd        Added function CheckProcess
# 0.10		2018.09.26	rahd        Modified function GetUpTime, TestSQLConnection
# 0.11		2018.09.27	rahd        Added function TestORAConnection
# 0.11.1	2018.09.27	rahd        Anomynized Headers
# 0.12	    2018.12.18	rahd        Corrected Indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0 + Added Function List
#
########################################################################################################################

$currentversion = "1.0"

Write-host "Importing Function Library | Toolbox2.ps1 | " -ForegroundColor Yellow -NoNewline
Write-Host "Current Version: $currentversion" -ForegroundColor Yellow

########################################################################################################################
#
# Function List:
#   CheckConnection
#   TestPort
#   TestShare
#   GetUpTime
#   CheckDiskSpace
#   StartIISSite
#   StopIISSite
#   CheckIISSite
#   TestSQLConnection
#   CheckProcess
#   TestORAConnection (0.1a)
#
########################################################################################################################

########################################################################################################################
#
# Function: CheckConnection
# Description: Test basic (ping) connectivity to specified server(s)
#
# Parameters:
# -Server [server(s) to be tested]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.01.11	rahd       	Initial version created
# 0.2		2018.02.14	rahd       	Refactored $server parameter to accept multiple comma separated servers in an array
# 0.3		2018.12.14	rahd       	Corrected indenture and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function CheckConnection
{
    param(
        [Parameter(Position=0, Mandatory=$True)]
        [String[]]$Server
    )
    
    $ErrorActionPreference = "SilentlyContinue"
    
    foreach ($_ in $Server){
        Test-Connection -ComputerName $_ -Count 1
        if ($Error[0].Exception){
            $Error[0].Exception
            $Error.clear()
        }
    }
}

########################################################################################################################
#
# Function: TestPort
# Description: Test connection to one or more ports on a server
#
# Parameters:
# -Server [server to test port on]
# -Port [Port(s) to be tested][Input as comma separated numbers]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.01.22	rahd       	Initial version created
# 0.2		2018.02.13	rahd       	Refactored $port parameter to accept multiple comma separated ports in an array
# 0.3		2018.12.14	rahd       	Corrected indenture, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function TestPort
{
    param(
        [Parameter(Mandatory=$True)][String]$Server,
        [String[]]$Port
    )

    $ErrorActionPreference = "SilentlyContinue"

    foreach ($_ in $Port){
        $Connection = New-Object System.Net.Sockets.TcpClient($Server, $_)
        write-host "Testing connection to $Server on port $_ : " -NoNewline
        
        if ($Connection.Connected){
            Write-Host "Success" -ForegroundColor Green
            $Connection.Close()
        }
        elseif ($Error[0].Exception){
            Write-Host "Failed " -ForegroundColor Red
            $Error.clear()
        }
    }
}
########################################################################################################################
#
# Function: TestShare
# Description: Test connection to a Share on a server
#
# Parameters:
# -Share [Share to be tested][Input as "\\Servername\Sharename"]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.01.22	rahd       	Initial version created
# 0.2		2018.12.14	rahd       	Corrected indenture, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function TestShare
{
    param(
        [Parameter(Mandatory=$True)][String]$Share
    )

    Write-Host "Checking Share availability of share: $Share" -ForegroundColor Yellow
    Write-Host "Share $Share is: " -NoNewline

    if(Test-Path -Path "$Share" -ErrorAction SilentlyContinue){
        Write-Host "Available" -ForegroundColor Green
    }
    else{
        if ($Error[0].Exception -is [System.UnauthorizedAccessException]){
            Write-Host "$Error" -ForegroundColor Yellow
        }  
        else{
            Write-Host "Unavailable" -ForegroundColor Red -NoNewline
            Write-Host " $Error" -ForegroundColor Yellow
        }
    }
    $Error.Clear()
}

########################################################################################################################
#
# Function: GetUptime
# Description: list each server and the current uptime since last booted
#
# Parameters:
# -Server [server(s) to get uptime information from][Input as comma separated Servernames]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.01.23	rahd       	Modified generic 'Unable to retrieve WMI Object win32_operatingsystem from $Server' Error Message to 'Write-Warning "$error"'
# 0.3		2018.09.26	rahd       	Refactored $server parameter to accept multiple comma separated servers in an array
# 0.4		2018.12.14	rahd       	Corrected indenture, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function GetUptime
{
    Param(
        [Parameter(Mandatory=$True)]
        [String[]]$Server
    )

    foreach ($Srv in $Server){
        if($Command = Get-WmiObject win32_operatingsystem -ComputerName $Srv -ErrorAction SilentlyContinue){
            $Format = [datetime]::Now - $Command.ConverttoDateTime($Command.lastbootuptime)
            Write-host $srv "| uptime"$Format.Days":"$Format.Hours":"$Format.Minutes" (Days:Hours:Minutes)"
        }
        else{
            Write-Host "$Srv | " -NoNewline
            Write-Warning "$Error"
            $Error.Clear()
        }
    } 
}

########################################################################################################################
#
# Function: CheckDiskSpace
# Description: Checks Local and Network drives for Free and used disk space
#
# Parameters:
# -Server [server to test (Default = $env:COMPUTERNAME)]
# -Credential [Credentials to use for server connection]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.01.25	rahd       	Initial version created
# 0.2		2018.02.14	rahd       	Refactored internal If logic regarding $credential
# 0.3		2018.12.14	rahd       	Corrected indenture, Description, Comments and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function CheckDiskSpace
{
    param(
        [Parameter(Position=0)][String]$Server = "$env:COMPUTERNAME",
        [Parameter(Position=1)][System.Management.Automation.Credential()]$Credential
    )

    BEGIN{
        # Define function to format Size Output
        function FormatGetFreeDisk 
        {
            param ($Size)
            switch ($Size) 
            {
                {$_ -ge 1PB}{"{0:#.#' PB'}" -f ($Size / 1PB); break}
                {$_ -ge 1TB}{"{0:#.#' TB'}" -f ($Size / 1TB); break}
                {$_ -ge 1GB}{"{0:#.#' GB'}" -f ($Size / 1GB); break}
                {$_ -ge 1MB}{"{0:#.# 'MB'}" -f ($Size / 1MB); break}
                {$_ -ge 1KB}{"{0:#' KB'}" -f ($Size / 1KB); break}
                default {"{0}" -f ($Size) + " B"}
            }
        }

        # Define WMI Query to include DriveType 3 (Local Disk) and DriveType 4 (Network Drive)
        $WMIQuery = 'SELECT * FROM Win32_LogicalDisk WHERE Size != Null AND DriveType = 3 OR DriveType = 4'

    }
    PROCESS{
            if ($Server -eq $env:COMPUTERNAME){
                $Disks = Get-WmiObject -Query $WMIQuery -ComputerName $Server -ErrorAction SilentlyContinue
                if ($Error) {
                    Write-Host "$Server | " -NoNewline
                    Write-Warning "$Error"
                    $Error.Clear()
                }
            }
            else
            {
                if (!($Credential)) {
                    $Disks = Get-WmiObject -Query $WMIQuery -ComputerName $Server -ErrorAction SilentlyContinue
                }
                else {
                    $Disks = Get-WmiObject -Query $WMIQuery -ComputerName $Server -Credential $Credential -ErrorAction SilentlyContinue
                }
                if ($Error) {
                    Write-Host "$Server | " -NoNewline
                    Write-Warning "$Error"
                    $Error.Clear()
                }
            }
            # Populate $Diskarray array
            $Diskarray = @()
            $Disks | ForEach-Object { $Diskarray += $_ }
                    
            # Outputs diskarray using FormatGetFreeDisk function
            $Diskarray | Select-Object @{n='Server Name';e={$_.SystemName}},
                @{n='Disk Letter';e={$_.DeviceID}},
                @{n='Volume Size';e={FormatGetFreeDisk $_.Size}},
                @{n='Available';e={FormatGetFreeDisk $_.FreeSpace}},
                @{n='Used Space';e={FormatGetFreeDisk (($_.Size)-($_.FreeSpace))}},
                @{n='Used Space %';e={[int](((($_.Size)-($_.FreeSpace))/($_.Size) * 100))}} | Format-Table -AutoSize
    }
}

########################################################################################################################
#
# Function: StartIISSite
# Description: Start IIS Site on soecified server
#
# Parameters:
# -Server [server to start IIS Sites on (Default = $env:COMPUTERNAME)]
# -Website [Wildcard parameter for website to be started (Type * for all websites)]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.02.06	rahd       	Initial version created
# 0.2		2018.02.14	rahd       	Refactored internal If logic
# 0.3		2018.12.14	rahd       	Corrected indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StartIISSite
{
    param(
        [Parameter(Position=0)][String]$Server = "$env:COMPUTERNAME",
        [Parameter(Position=1, Mandatory=$True)][String]$Website
    )

    Invoke-Command -ComputerName $Server -ScriptBlock{
        Import-Module -Name webadministration

        $Site = (Get-Website | where {$_.name -like "*$using:Website*"})
        $Site | select Name, State, serverautostart, applicationpool, physicalpath| Format-Table -AutoSize
        if (!($Site)){
            Write-Host "No IIS Sites matching $using:Website" -ForegroundColor DarkGray
        }

        $Site | select Name, State, ServerAutostart | format-table -AutoSize
        foreach ($Site in $Site){
            $IISSite = "IIS:\Sites\" + $Site.name
            if ($Site.state -eq "Started"){
                Write-Host "Site is already started: " -ForegroundColor DarkGreen -NoNewline
                $Site.name
            }
            elseif ($Site.state -eq "Stopped"){
                Write-Host "Starting site: " -ForegroundColor Yellow -NoNewline
                $Site.name
                $Site.Start()
                Set-ItemProperty -Path $IISSite serverAutoStart True
                write-host "Setting Start Automatically to True"
            }
        }
    }
}

########################################################################################################################
#
# Function: StopIISSite
# Description: Stop IIS Site on soecified server
#
# Parameters:
# -Server [server to stop IIS Sites on (Default = $env:COMPUTERNAME)]
# -Website [Wildcard parameter for website to be stopped (Type * for all websites)]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.02.06	rahd       	Initial version created
# 0.2		2018.02.14	rahd       	Refactored internal If logic
# 0.3		2018.12.14	rahd       	Corrected indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function StopIISSite
{
    param(
        [Parameter(Position=0)][String]$server = "$env:COMPUTERNAME",
        [Parameter(Position=1, Mandatory=$true)][String]$Website
    )

    Invoke-Command -ComputerName $server -ScriptBlock{
        Import-Module -Name webadministration

        $Site = (Get-Website | where {$_.name -like "*$using:Website*"})
        $Site | select Name, State, serverautostart, applicationpool, physicalpath| Format-Table -AutoSize
        if (!($Site)) {
            Write-Host "No IIS Sites matching $using:Website" -ForegroundColor DarkGray
        }

        $Site | select Name, State, ServerAutostart | format-table -AutoSize
        foreach ($Site in $Site){
            $IISSite = "IIS:\Sites\" + $Site.name
            if ($Site.state -eq "Stopped"){
                Write-Host "Site is already stopped: " -ForegroundColor DarkGreen -NoNewline
                $Site.name
            }
            elseif ($Site.state -eq "Started"){
                Write-Host "Stopping site: " -ForegroundColor Yellow -NoNewline
                $Site.name
                $Site.Stop()
                write-host "Setting Start Automatically to False"
                Set-ItemProperty -Path $IISSite serverAutoStart False
                
            }
        }
    }
}

########################################################################################################################
#
# Function: CheckIISSite
# Description: Resturns status properties of IIS Site on server
#
# Parameters:
# -Server   [server to check IIS Sites on (Default = $env:COMPUTERNAME)]
# -Website  [Wildcard parameter for website(s) to be checked (Type * for all websites)]
# -WebApps  [Switch parameter, set, to show status for Web Applications]
# -AppPools [Switch parameter, set, to show status for Application Pools]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.02.06	rahd       	Initial version created
# 0.2		2018.02.07	rahd       	Added webapps, apppools switches
# 0.3		2018.12.14	rahd       	Corrected indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function CheckIISSite
{
    param(
        [Parameter(Position=0)][String]$Server = "$env:COMPUTERNAME",
        [Parameter(Position=1, Mandatory=$true)][String]$Website,
        [switch]$WebApps,
        [switch]$AppPools
    )

    Invoke-Command -ComputerName $Server -ScriptBlock{
        Import-Module -Name webadministration

        Write-Host "Listing Websites matching $using:Website on $using:Server" -ForegroundColor Yellow        
        $Site = (Get-Website | where {$_.name -like "*$using:Website*"})
        $Site | select Name, State, serverautostart, applicationpool, physicalpath| Format-Table -AutoSize
        if (!($Site)) {
            Write-Host "No IIS Sites matching $using:Website" -ForegroundColor DarkGray
        }
        if ($using:WebApps){
            Write-Host "Listing Web Applications matching $using:Website on $using:Server" -ForegroundColor Yellow
            $WebApp = (Get-WebApplication | where {$_.name -like "*$using:Website*" -or $_.ApplicationPool -like"*$using:Website*"})
            $WebApp | select path, ApplicationPool, PhysicalPath | Format-Table -AutoSize
            if (!($WebApp)){
                Write-Host "No Web Applications matching $using:Website"  -ForegroundColor DarkGray
            }
        }
        if ($using:AppPools){
            Write-Host "Listing Application Pools matching $using:Website on $using:Server" -ForegroundColor Yellow
            $AppPool = (Get-Item IIS:\AppPools\*$using:Website*)
            $AppPool | select Name, State, autostart, enable32BitAppOnWin64 | Format-Table -AutoSize
            if (!($AppPool)){
                Write-Host "No Application Pool matching $using:Website"  -ForegroundColor DarkGray
            }
        }
    }
}

########################################################################################################################
#
# Function: TestSQLConnection
# Description: Opens up a connection to a SQL Instance, using either Integrated or SQL Authentication
#
# Parameters:
# -SQLserver [SQL server to connect to]
# -Database [Database to connect to (Default = master)]
# -UserID [User credentials]
# -PassWD [User Password]
# -NotIntegratedSec [switch to not use integrated security]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.02.12	rahd       	Initial version created
# 0.2		2018.09.26	rahd       	Total remake
# 0.3		2018.12.17	rahd       	Corrected indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################

function TestSQLConnection
{
    param(
        [Parameter(Position=0,Mandatory=$true)][String[]] $SQLserver,
        [Parameter(Position=1)][String] $Database = "master",
        [String] $UserID,
        [String] $PassWD,
        [Switch] $NotIntegratedSec
    )

$ErrorActionPreference = "SilentlyContinue"

    ForEach ($SQLsrv in $SQLserver){
        # Defines Connection String using Integrated Security
        if (!($NotintegratedSec)){
            Write-Host "Trying to open SQL Connection, using Integrated Security     "
            Write-Host "| ($SQLserver/$Database) |:   " -ForegroundColor Yellow -NoNewline
	
            $SQLConnection = "Server = $SQLsrv; Database = $Database; Integrated Security = True;"
	        $SQLConn = new-object ("Data.SqlClient.SqlConnection") $SqlConnection
        }
        # Defines Connection String using SQL Security
        else{
            if (!($userID)){
                Write-Warning "No User specified for connection"
                $UserID = Read-Host -Prompt "Please type in userID"
            }        
            if (!($passWD)){
                Write-Warning "No Password specified for user: $UserID"
                $PassWDSec = Read-Host -Prompt "Please type in Password for $UserID" -AsSecureString
                $PassWD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PassWDSec))
            }

            Write-Host "Trying to open SQL Connection, not using Integrated Security "
            Write-Host "| ($SQLserver/$Database) |:   " -ForegroundColor Yellow -NoNewline

            $SQLConnection = "Server = $SQLsrv; Database = $Database; uid = $UserID; pwd = $PassWD;"
	        $SQLConn = new-object ("Data.SqlClient.SqlConnection") $SQLConnection
        }
    
        # Opens Connection    
        $SQLConn.Open()

        # Closes connection
        if ($SQLConn.State -eq 'Open'){
            Write-Host "Opened successfully" -ForegroundColor Green
            Write-Host "Trying to close SQL Connection                               "
            Write-Host "| ($SQLserver/$Database) |:   " -ForegroundColor Yellow -NoNewline
            $SQLConn.Close();
            write-host "Closed successfully" -ForegroundColor Green
	    }
        Else{
            Write-Host "SQL Connection is not opened" -ForegroundColor Red
            Write-Host "$SQLserver | " -NoNewline
            write-host $Error -ForegroundColor Red
            $Error.Clear()
        }    
    }
}

########################################################################################################################
#
# Function: CheckProcess
# Description: Checks if process is running on server
#
# Parameters:
# -Server [server to be tested]
# -Processname [Process(s) to be checked(Comma seperate for multiple processes)]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.02.16	rahd       	Initial version created
# 0.2		2018.12.18	rahd       	Corrected indenture, Versioning, Description and Capitalization acc. to Code review
# 1.0	    2018.12.18	rahd        Finalized and released Version 1.0
#
########################################################################################################################
function CheckProcess
{
    param(
        [Parameter(Position=0)][String]$Server = $env:COMPUTERNAME,
        [Parameter(Position=1, Mandatory=$True)][String[]]$Processname
    )

    $ErrorActionPreference = "SilentlyContinue"

    foreach ($_ in $Processname){
        $Process = get-process -ComputerName $Server -Name $_
        $Process | Format-Table
        if (!($Process)) {
            Write-Warning "$Error"
            $Error.Clear()
        }
    }
}

########################################################################################################################
#
# Function: TestORAConnection
# Description: Test Oracle Conenctivity, by opening a connection to a datasource
#
# Parameters:
# -datasource [used for buildiong connection string]
# -userID [used for buildiong connection string]
# -passWD [used for buildiong connection string]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1a		2018.09.27	rahd       	Initial version created
#
########################################################################################################################

function TestORAConnection
{
    param
    (
    [String] $datasource,
    [String] $userID,
    [String] $passWD
    )

    $ErrorActionPreference = "SilentlyContinue"

    add-type -Path D:\Oracle\product\12.1.0\client_1\ODP.NET\managed\common\Oracle.ManagedDataAccess.dll
    #add-type -AssemblyName System.Data.OracleClient

    $ORAconnection = "User Id=$userID; Password=$passWD; Data Source=$datasource"

    Write-Host "Trying to open ORACLE Connection "
    Write-Host "| $datasource |:   " -ForegroundColor Yellow -NoNewline

    $ORAconn = New-Object Oracle.ManagedDataAccess.Client.OracleConnection($ORAconnection)
    #$ORAconn = New-Object System.Data.OracleClient.OracleConnection($ORAconnection)
    $ORAconn.Open()
        
    if ($ORAConn.State -eq 'Open')
        {
            Write-Host "Opened successfully" -ForegroundColor Green
            Write-Host "Trying to close ORACLE Connection                               "
            Write-Host "| $datasource |:   " -ForegroundColor Yellow -NoNewline
            $ORAConn.Close();

            if ($ORAConn.State -eq 'Closed')
                {
                Write-Host "Closed successfully" -ForegroundColor Green
                }   
            else
                {
                Write-Host "Connection NOT Closed!" -ForegroundColor Red
                }
		}
    Else
        {
            Write-Host "ORACLE Connection is not opened" -ForegroundColor Red
            Write-Host "$datasource | " -NoNewline
            write-host $error -ForegroundColor Red
            $error.Clear()
        }    
}