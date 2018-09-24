########################################################################################################################
# FILENAME:		toolbox2.0.ps1
# CREATED BY:	Rasmus Ahrendt Deleuran (rahd)
# CREATED:		2018.01.22
# DESCRIPTION:  NNIT Application Services Powershell Function Collection Toolbox 2.0 Release
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
#
########################################################################################################################

$currentversion = "0.9"

Write-host "Importing Function Library | Toolbox2.0.ps1 | " -ForegroundColor Yellow -NoNewline
Write-Host "Current Version: $currentversion" -ForegroundColor Yellow

########################################################################################################################
#
# Function: CheckConnection
# Description: Test basic (ping) connectivity to specified server(s)
#
# Parameters:
# -server [server(s) to be tested]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.01.11	rahd       	Initial version created
# 0.2		2018.02.14	rahd       	Refactored $server parameter to accept multiple comma separated servers in an array
#
########################################################################################################################
function CheckConnection
{
    param(
    [Parameter(Position=0, Mandatory=$True)]
    [String[]]$server
    )
    
    $ErrorActionPreference = "SilentlyContinue"
    
    foreach ($_ in $server){
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
# Description: Test connection to a port on a server
#
# Parameters:
# -server [server to test port on]
# -port [Port to be tested]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.01.22	rahd       	Initial version created
# 0.2		2018.02.13	rahd       	Refactored $port parameter to accept multiple comma separated ports in an array
#
########################################################################################################################
function TestPort
{
    param
    (
    [Parameter(Mandatory=$True)][String]$server,
    [String[]]$port
    )

    $ErrorActionPreference = "SilentlyContinue"

    foreach ($_ in $port) {
        $connection = New-Object System.Net.Sockets.TcpClient($server, $_)
        write-host "Testing connection to $server on port $_ : " -NoNewline
        
        if ($connection.Connected) {
            Write-Host "Success" -ForegroundColor Green
            $connection.Close()
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
# -share [Share to be tested]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.01.22	rahd       	Initial version created
#
########################################################################################################################
function TestShare
{
    param
    (
    [Parameter(Mandatory=$True)][String]$share
    )

    Write-Host "Checking Share availability of share: $share" -ForegroundColor Yellow
    Write-Host "Share $Share is: " -NoNewline
    if(Test-Path -Path "$Share" -ErrorAction SilentlyContinue){
        Write-Host "Available" -ForegroundColor Green
    }
    else{
        if ($Error[0].Exception -is [System.UnauthorizedAccessException]){
            Write-Host "$Error" -ForegroundColor Yellow
        }  
        else{
            Write-Host "UnAvailable" -ForegroundColor Red -NoNewline
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
# -server [server to get uptime information]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2017.06.17	bbhj       	Initial version created
# 0.2		2018.01.23	rahd       	Modified generic 'Unable to retrieve WMI Object win32_operatingsystem from $Server' Error Message to 'Write-Warning "$error"'
#
########################################################################################################################
function GetUptime
{
    Param(
    [Parameter(Mandatory=$True)]
    [String]$server
    )

    if($command = Get-WmiObject win32_operatingsystem -ComputerName $Server -ErrorAction SilentlyContinue){
        $format = [datetime]::Now - $command.ConverttoDateTime($command.lastbootuptime)
        Write-host $server "| uptime"$format.Days":"$format.Hours":"$format.Minutes" (Days:Hours:Minutes)"
    }
    else{
        Write-Host "$server | " -NoNewline
        Write-Warning "$error"
        $error.Clear()
    } 
}

########################################################################################################################
#
# Function: CheckDiskSpace
# Description: Checks Local and Network drives for Free and used disk space
#
# Parameters:
# -server [server to test (Default = $env:COMPUTERNAME)]
# -Credential [Credentials to use for server connection]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.01.25	rahd       	Initial version created
# 0.2		2018.02.14	rahd       	Refactored internal If logic regarding $credential
#
########################################################################################################################
function CheckDiskSpace
{
    param
    (
    [Parameter(Position=0)]
    [String]$server = "$env:COMPUTERNAME",
    [Parameter(Position=1, Mandatory=$false)]
    [System.Management.Automation.Credential()]$Credential
    )

    BEGIN{
        function FormatGetFreeDisk 
        {
            param ($size)
            switch ($size) 
            {
                {$_ -ge 1PB}{"{0:#.#' PB'}" -f ($size / 1PB); break}
                {$_ -ge 1TB}{"{0:#.#' TB'}" -f ($size / 1TB); break}
                {$_ -ge 1GB}{"{0:#.#' GB'}" -f ($size / 1GB); break}
                {$_ -ge 1MB}{"{0:#.# 'MB'}" -f ($size / 1MB); break}
                {$_ -ge 1KB}{"{0:#' KB'}" -f ($size / 1KB); break}
                default {"{0}" -f ($size) + " B"}
            }
        }

        $wmiquery = 'SELECT * FROM Win32_LogicalDisk WHERE Size != Null AND DriveType = 3 OR DriveType = 4'

    }
    PROCESS{
            if ($server -eq $env:COMPUTERNAME){
                $disks = Get-WmiObject -Query $wmiquery -ComputerName $server -ErrorAction SilentlyContinue
                if ($Error) {
                    Write-Host "$server | " -NoNewline
                    Write-Warning "$error"
                    $error.Clear()
                }
            }
            else
            {
                if (!($Credential)) {
                    $disks = Get-WmiObject -Query $wmiquery -ComputerName $server -ErrorAction SilentlyContinue
                }
                else {
                    $disks = Get-WmiObject -Query $wmiquery -ComputerName $server -Credential $Credential -ErrorAction SilentlyContinue
                }
                if ($Error) {
                    Write-Host "$server | " -NoNewline
                    Write-Warning "$error"
                    $error.Clear()
                }
            }
            $diskarray = @()
            $disks | ForEach-Object { $diskarray += $_ }
                    
            $diskarray | Select-Object @{n='Server Name';e={$_.SystemName}},
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
# Description: 
#
# Parameters:
# -server [server to start IIS Sites on]
# -website [Wildcard parameter for website to be started (Type * for all websites)]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1a		2018.02.06	rahd       	Initial version created
# 0.2		2018.02.14	rahd       	Refactored internal If logic
#
########################################################################################################################
function StartIISSite
{
    param
    (
    [Parameter(Position=0)]
    [String]$server = "$env:COMPUTERNAME",
    [Parameter(Position=1, Mandatory=$true)]
    [String]$website
    )

    Invoke-Command -ComputerName $server -ScriptBlock {
        Import-Module -Name webadministration

        $site = (Get-Website | where {$_.name -like "*$using:website*"})
        $site | select Name, State, serverautostart, applicationpool, physicalpath| Format-Table -AutoSize
        if (!($site)) {
            Write-Host "No IIS Sites matching $using:website" -ForegroundColor DarkGray
        }

        $site | select Name, State, ServerAutostart | format-table -AutoSize
        foreach ($site in $site) {
            $iissite = "IIS:\Sites\" + $site.name
            if ($site.state -eq "Started"){
                Write-Host "Site is already started: " -ForegroundColor DarkGreen -NoNewline
                $site.name
            }
            elseif ($site.state -eq "Stopped"){
                Write-Host "Starting site: " -ForegroundColor Yellow -NoNewline
                $site.name
                $site.Start()
                Set-ItemProperty -Path $iissite serverAutoStart True
                write-host "Setting Start Automatically to True"
            }
        }
    }
}

########################################################################################################################
#
# Function: StopIISSite
# Description: 
#
# Parameters:
# -server [server to stop IIS Sites on]
# -website [Wildcard parameter for website to be stopped (Type * for all websites)]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1a		2018.02.06	rahd       	Initial version created
# 0.2		2018.02.14	rahd       	Refactored internal If logic
#
########################################################################################################################
function StopIISSite
{
    param
    (
    [Parameter(Position=0)]
    [String]$server = "$env:COMPUTERNAME",
    [Parameter(Position=1, Mandatory=$true)]
    [String]$website
    )

    Invoke-Command -ComputerName $server -ScriptBlock {
        Import-Module -Name webadministration

        $site = (Get-Website | where {$_.name -like "*$using:website*"})
        $site | select Name, State, serverautostart, applicationpool, physicalpath| Format-Table -AutoSize
        if (!($site)) {
            Write-Host "No IIS Sites matching $using:website" -ForegroundColor DarkGray
        }

        $site | select Name, State, ServerAutostart | format-table -AutoSize
        foreach ($site in $site) {
            $iissite = "IIS:\Sites\" + $site.name
            if ($site.state -eq "Stopped"){
                Write-Host "Site is already stopped: " -ForegroundColor DarkGreen -NoNewline
                $site.name
            }
            elseif ($site.state -eq "Started"){
                Write-Host "Stopping site: " -ForegroundColor Yellow -NoNewline
                $site.name
                $site.Stop()
                write-host "Setting Start Automatically to False"
                Set-ItemProperty -Path $iissite serverAutoStart False
                
            }
        }
    }
}

########################################################################################################################
#
# Function: CheckIISSite
# Description: 
#
# Parameters:
# -server   [server to check IIS Sites on]
# -website  [Wildcard parameter for website(s) to be checked (Type * for all websites)]
# -webapps  [Switch parameter, set to true to show status for Web Applications]
# -apppools [Switch parameter, set to true to show status for Application Pools]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1a		2018.02.06	rahd       	Initial version created
# 0.2		2018.02.07	rahd       	Added webapps, apppools switches
#
########################################################################################################################
function CheckIISSite
{
    param
    (
    [Parameter(Position=0)]
    [String]$server = "$env:COMPUTERNAME",
    [Parameter(Position=1, Mandatory=$true)]
    [String]$website,
    [switch]$webapps,
    [switch]$apppools
    )

    Invoke-Command -ComputerName $server -ScriptBlock {
        Import-Module -Name webadministration

        Write-Host "Listing Websites matching $using:website on $using:server" -ForegroundColor Yellow        
        $site = (Get-Website | where {$_.name -like "*$using:website*"})
        $site | select Name, State, serverautostart, applicationpool, physicalpath| Format-Table -AutoSize
        if (!($site)) {
            Write-Host "No IIS Sites matching $using:website" -ForegroundColor DarkGray
        }
        if ($using:webapps) {
            Write-Host "Listing Web Applications matching $using:website on $using:server" -ForegroundColor Yellow
            $webapp = (Get-WebApplication | where {$_.name -like "*$using:website*" -or $_.ApplicationPool -like"*$using:website*"})
            $webapp | select path, ApplicationPool, PhysicalPath | Format-Table -AutoSize
            if (!($webapp)) {
                Write-Host "No Web Applications matching $using:website"  -ForegroundColor DarkGray
            }
        }
        if ($using:apppools) {
            Write-Host "Listing Application Pools matching $using:website on $using:server" -ForegroundColor Yellow
            $apppool = (Get-Item IIS:\AppPools\*$using:website*)
            $apppool | select Name, State, autostart, enable32BitAppOnWin64 | Format-Table -AutoSize
            if (!($apppool)) {
                Write-Host "No Application Pool matching $using:website"  -ForegroundColor DarkGray
            }
        }
    }
}

########################################################################################################################
#
# Function: TestSQLConnection
# Description: 
#
# Parameters:
# -Srcserver [server to test from (Default = $env:COMPUTERNAME)]
# -SQLserver [SQL server to connect to]
# -database [Database to connect to (Default = master)]
# -userID [User credentials]
# -passWD [User Password]
# -integratedSec [switch to use integrated security instead of userID and passWD]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1		2018.02.12	rahd       	Initial version created
#
########################################################################################################################

function TestSQLConnection
{
    param
    (
    [String] $Srcserver = $env:COMPUTERNAME,
    [String] $SQLserver,
    [String] $database = "master",
    [String] $userID,
    [String] $passWD,
    [Switch] $integratedSec
    )
    
    # Suppress Error messages
    $ErrorActionPreference = "SilentlyContinue"
    
    # Prompts for userID and passWD if empty
    if (!($integratedSec)) {
        if (!($userID)) {
            Write-Warning "No User specified for connection"
            $userID = Read-Host -Prompt "Please type in userID"
        }        
        if (!($passWD)) {
            Write-Warning "No Password specified for user: $userID"
            $passWDSec = Read-Host -Prompt "Please type in Password for $userID" -AsSecureString
        }
        $passWD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($passWDSec))
    }

    # Build Connection string and $SQLConn object
    if ($IntegratedSec){
        $SQLConnStr = "Data Source=$SQLServer;Initial Catalog=$database;Integrated Security=true;Connect Timeout=3;"
    }
    else {
        $SQLConnStr = "Data Source=$SQLServer;Initial Catalog=$database;User ID=$userID;Password=$passWD;Connect Timeout=3;"
    }
    $SQLConn = new-object ("Data.SqlClient.SqlConnection") $SQLConnStr

    # Open Connection using $SQLConn object    
    Write-Host "Trying to open SQL Connection  | ($SQLserver/$database) |: " -ForegroundColor Yellow -NoNewline
    Invoke-Command -ComputerName $Srcserver -ScriptBlock {
        $SQLConn = new-object ("Data.SqlClient.SqlConnection") $using:SQLConnStr
        $SQLConn.Open()

        # Write output based on connection state
        if ($SQLConn.State -eq 'Open')
        {
            Write-Host "Opened successfully" -ForegroundColor Green
            Write-Host "Trying to close SQL Connection | ($using:SQLserver/$using:database) |: " -ForegroundColor Yellow -NoNewline
            $SQLConn.Close();
            write-host "Closed successfully" -ForegroundColor Green
        }
        else {
            Write-Host "SQL Connection is not opened" -ForegroundColor Red
            Write-Host "$using:SQLserver | " -NoNewline
            Write-Warning "$error"
            $error.Clear()
        }
    }
}

########################################################################################################################
#
# Function: CheckProcess
# Description: Checks if process is running on server(s)
#
# Parameters:
# -server [server to be tested]
# -processname [Process(s) to be checked(Comma seperate for multiple processes)]
#
########################################################################################################################
# MODIFICATIONS
# VERSION	DATE		INIT       	DESCRIPTION
# 0.1a		2018.02.16	rahd       	Initial version created
#
########################################################################################################################
function CheckProcess
{
    param(
    [Parameter(Position=0)]
    [String]$server = $env:COMPUTERNAME,
    [Parameter(Position=1, Mandatory=$True)]
    [String[]]$processname
    )

    $ErrorActionPreference = "SilentlyContinue"

    foreach ($_ in $processname) {
        $process = get-process -ComputerName $server -Name $_
        $process | Format-Table
        if (!($process)) {
            Write-Warning "$error"
            $error.Clear()
        }
    }
}