<#
.SYNOPSIS
    RestroOrder Complete Automated Installer
.DESCRIPTION
    Installs IIS, SQL Server 2019 Dev, SSMS, .NET packages, restores DB, configures Google Drive
.NOTES
    Run as Administrator
.PARAMETER BackupFilePath
    Path to database backup file to restore
.PARAMETER SkipGoogleDrive
    Skip Google Drive setup
.PARAMETER CleanupType
    Type of cleanup: Full, SalesOnly, or None
.EXAMPLE
    .\Install-RestroOrder.ps1 -BackupFilePath "D:\Backups\RestroOrder.bak" -CleanupType "Full"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$BackupFilePath = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipGoogleDrive,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Full", "SalesOnly", "None")]
    [string]$CleanupType = "None"
)

# Logging Setup
$LogPath = "C:\RestroOrder\Logs\Install_$((Get-Date).ToString('yyyyMMdd_HHmmss')).log"
$Global:ErrorActionPreference = "Stop"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    if (!(Test-Path (Split-Path $LogPath))) {
        New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null
    }
    Add-Content -Path $LogPath -Value $logEntry
    if ($Level -eq "ERROR") {
        Write-Host $Message -ForegroundColor Red
    } elseif ($Level -eq "SUCCESS") {
        Write-Host $Message -ForegroundColor Green
    } elseif ($Level -eq "WARNING") {
        Write-Host $Message -ForegroundColor Yellow
    } else {
        Write-Host $Message
    }
}

# Create directories
$Directories = @(
    "C:\RestroOrder",
    "C:\RestroOrder\Logs",
    "C:\RestroOrder\Backups",
    "C:\RestroOrder\Temp",
    "C:\RestroOrder\Database",
    "C:\RestroOrder\Config",
    "C:\RestroOrder\Scripts"
)

foreach ($dir in $Directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Log "Created directory: $dir"
    }
}

Write-Log "==========================================" SUCCESS
Write-Log "RestroOrder Automated Installation Started" INFO
Write-Log "Installation Log: $LogPath" INFO
Write-Log "==========================================" SUCCESS

# Check if running as Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "ERROR: This script must be run as Administrator!" ERROR
    exit 1
}

# Step 1: Enable IIS
Write-Log "Step 1/10: Enabling IIS and required features..." INFO
try {
    $IISFeatures = @(
        "IIS-WebServerRole",
        "IIS-WebServer",
        "IIS-CommonHttpFeatures",
        "IIS-ApplicationInit",
        "IIS-ASPNET45",
        "IIS-NetFxExtensibility45",
        "IIS-ISAPIExtensions",
        "IIS-ISAPIFilter",
        "IIS-HealthAndDiagnostics",
        "IIS-RequestMonitoring",
        "IIS-UrlAuthorization",
        "IIS-RequestFiltering",
        "IIS-HttpCompressionStatic",
        "IIS-HttpCompressionDynamic",
        "IIS-ManagementService"
    )
    
    foreach ($feature in $IISFeatures) {
        Write-Log "  Enabling: $feature" INFO
        Enable-WindowsOptionalFeature -Online -FeatureName $feature -All -NoRestart -LogLevel Warning | Out-Null
    }
    
    Write-Log "IIS installed successfully" SUCCESS
} catch {
    Write-Log "Failed to enable IIS: $_" ERROR
    exit 1
}

# Step 2: Install .NET 8 Hosting Bundle
Write-Log "Step 2/10: Installing .NET 8 Hosting Bundle..." INFO
$DotNetUrl = "https://download.visualstudio.microsoft.com/download/pr/dotnet/8.0.0/dotnet-hosting-8.0.0-win.exe"
$DotNetPath = "C:\RestroOrder\Temp\dotnet-hosting.exe"

try {
    if (!(Test-Path $DotNetPath)) {
        Write-Log "  Downloading .NET 8 Hosting Bundle..." INFO
        Invoke-WebRequest -Uri $DotNetUrl -OutFile $DotNetPath -UseBasicParsing
    }
    
    Write-Log "  Installing .NET 8..." INFO
    Start-Process -FilePath $DotNetPath -ArgumentList "/quiet", "/norestart" -Wait
    
    # Verify installation
    $dotnetVersion = dotnet --version 2>$null
    if ($dotnetVersion) {
        Write-Log ".NET 8 Hosting Bundle installed (Version: $dotnetVersion)" SUCCESS
    } else {
        Write-Log ".NET installation may require manual verification" WARNING
    }
} catch {
    Write-Log "Failed to install .NET: $_" ERROR
}

# Step 3: Download and Install SQL Server 2019 Developer
Write-Log "Step 3/10: Downloading SQL Server 2019 Developer Edition..." INFO
$SqlUrl = "https://download.microsoft.com/download/7/f/8/7f8a9c43-8c8a-4f7c-9d8e-1f8b8c8e8f8e/SQL2019-SSEI-Dev.exe"
$SqlPath = "C:\RestroOrder\Temp\SQL2019-SSEI-Dev.exe"

try {
    if (!(Test-Path $SqlPath)) {
        Write-Log "  Downloading SQL Server 2019 (This may take 10-15 minutes)..." INFO
        Invoke-WebRequest -Uri $SqlUrl -OutFile $SqlPath -UseBasicParsing
    }
    
    $SqlConfigFile = "C:\RestroOrder\Temp\SQLConfig.ini"
    @'
[OPTIONS]
ACTION="Install"
FEATURES=SQLEngine,Replication,FullText,Tools
INSTANCENAME="MSSQLSERVER"
SQLSYSADMINACCOUNTS="BUILTIN\Administrators"
AGTSVCSTARTUPTYPE="Automatic"
BROWSERSVCSTARTUPTYPE="Automatic"
QUIET="True"
IACCEPTSQLSERVERLICENSETERMS="True"
'@ | Set-Content -Path $SqlConfigFile -Encoding ASCII
    
    Write-Log "  Installing SQL Server 2019 (This may take 15-20 minutes)..." INFO
    Start-Process -FilePath $SqlPath -ArgumentList "/ConfigurationFile=$SqlConfigFile", "/Quiet" -Wait
    
    Write-Log "SQL Server 2019 Developer installed" SUCCESS
} catch {
    Write-Log "Failed to install SQL Server: $_" ERROR
    Write-Log "You may need to download and install SQL Server manually" WARNING
}

# Step 4: Install SSMS
Write-Log "Step 4/10: Downloading and installing SSMS..." INFO
$SsmsUrl = "https://aka.ms/ssmsfullsetup"
$SsmsPath = "C:\RestroOrder\Temp\SSMS-Setup.exe"

try {
    if (!(Test-Path $SsmsPath)) {
        Write-Log "  Downloading SSMS (This may take 5-10 minutes)..." INFO
        Invoke-WebRequest -Uri $SsmsUrl -OutFile $SsmsPath -UseBasicParsing
    }
    
    Write-Log "  Installing SSMS..." INFO
    Start-Process -FilePath $SsmsPath -ArgumentList "/install", "/quiet", "/norestart" -Wait
    
    Write-Log "SSMS installed successfully" SUCCESS
} catch {
    Write-Log "Failed to install SSMS: $_" ERROR
}

# Step 5: Start SQL Server Service
Write-Log "Step 5/10: Starting SQL Server services..." INFO
try {
    $Services = @("MSSQLSERVER", "SQLAgent", "SQLBrowser")
    foreach ($svc in $Services) {
        $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($service -and $service.Status -ne "Running") {
            Start-Service -Name $svc
            Write-Log "  Started: $svc" INFO
        }
    }
    Write-Log "SQL Server services started" SUCCESS
} catch {
    Write-Log "Failed to start SQL Server services: $_" WARNING
}

# Wait for SQL to be ready
Write-Log "  Waiting for SQL Server to be ready..." INFO
Start-Sleep -Seconds 30

# Step 6: Restore Database
if ($BackupFilePath -ne "" -and (Test-Path $BackupFilePath)) {
    Write-Log "Step 6/10: Restoring database from $BackupFilePath..." INFO
    
    try {
        # Install SqlServer module if not present
        if (!(Get-Module -ListAvailable -Name SqlServer)) {
            Write-Log "  Installing SqlServer PowerShell module..." INFO
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
            Install-Module -Name SqlServer -AllowClobber -Scope CurrentUser -Force | Out-Null
        }
        
        Import-Module SqlServer -ErrorAction Stop
        
        $RestoreScript = @"
USE master;
GO
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'RestroOrder')
BEGIN
    ALTER DATABASE [RestroOrder] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [RestroOrder];
END
GO
RESTORE DATABASE [RestroOrder]
FROM DISK = N'$BackupFilePath'
WITH MOVE 'RestroOrder' TO 'C:\RestroOrder\Database\RestroOrder.mdf',
     MOVE 'RestroOrder_log' TO 'C:\RestroOrder\Database\RestroOrder_log.ldf',
     REPLACE,
     STATS = 10;
GO
"@
        
        $RestoreScript | Out-File -FilePath "C:\RestroOrder\Temp\RestoreDB.sql" -Encoding UTF8
        Invoke-Sqlcmd -ServerInstance "localhost" -InputFile "C:\RestroOrder\Temp\RestoreDB.sql"
        Write-Log "Database restored successfully" SUCCESS
    } catch {
        Write-Log "Failed to restore database: $_" ERROR
        Write-Log "You can restore manually using SSMS" WARNING
    }
} else {
    if ($BackupFilePath -ne "") {
        Write-Log "Step 6/10: Backup file not found: $BackupFilePath" WARNING
    } else {
        Write-Log "Step 6/10: No backup file provided, skipping restore" INFO
    }
}

# Step 7: Run Cleanup Script
if ($CleanupType -ne "None") {
    Write-Log "Step 7/10: Running $CleanupType cleanup script..." INFO
    
    if ($CleanupType -eq "Full") {
        $CleanupScriptPath = "C:\RestroOrder\Scripts\FullCleanup.sql"
    } else {
        $CleanupScriptPath = "C:\RestroOrder\Scripts\SalesOnlyCleanup.sql"
    }
    
    if (Test-Path $CleanupScriptPath) {
        try {
            # First create backup before cleanup
            $PreCleanupBackup = "C:\RestroOrder\Backups\PreCleanup_$((Get-Date).ToString('yyyyMMdd_HHmmss')).bak"
            Backup-SqlDatabase -ServerInstance "localhost" -Database "RestroOrder" -BackupFile $PreCleanupBackup
            Write-Log "Pre-cleanup backup created: $PreCleanupBackup" SUCCESS
            
            Invoke-Sqlcmd -ServerInstance "localhost" -Database "RestroOrder" -InputFile $CleanupScriptPath
            Write-Log "$CleanupType cleanup completed" SUCCESS
        } catch {
            Write-Log "Failed to run cleanup: $_" ERROR
        }
    } else {
        Write-Log "Cleanup script not found: $CleanupScriptPath" WARNING
        Write-Log "Skipping cleanup step" INFO
    }
} else {
    Write-Log "Step 7/10: No cleanup requested, skipping" INFO
}

# Step 8: Setup Google Drive (Optional)
if (!$SkipGoogleDrive) {
    Write-Log "Step 8/10: Setting up Google Drive synchronization..." INFO
    try {
        if (Test-Path "C:\RestroOrder\Setup-GoogleDrive.ps1") {
            & "C:\RestroOrder\Setup-GoogleDrive.ps1"
            Write-Log "Google Drive setup completed" SUCCESS
        } else {
            Write-Log "Google Drive setup script not found, skipping" WARNING
        }
    } catch {
        Write-Log "Google Drive setup failed: $_" ERROR
        Write-Log "You can setup Google Drive manually later" WARNING
    }
} else {
    Write-Log "Step 8/10: Google Drive setup skipped" INFO
}

# Step 9: Configure Automatic Backups
Write-Log "Step 9/10: Configuring automatic backups..." INFO
try {
    $TaskName = "RestroOrder-DailyBackup"
    
    # Remove existing task if present
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-ExecutionPolicy Bypass -File C:\RestroOrder\DatabaseManager.ps1 -Action Backup -Destination 'C:\RestroOrder\Backups'"
    $Trigger = New-ScheduledTaskTrigger -Daily -At 2am
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Force
    Write-Log "Daily backup scheduled task created (runs at 2:00 AM)" SUCCESS
} catch {
    Write-Log "Failed to create backup schedule: $_" WARNING
}

# Step 10: System Cleanup
Write-Log "Step 10/10: Running initial system cleanup..." INFO
try {
    if (Test-Path "C:\RestroOrder\Cleanup-Windows.ps1") {
        & "C:\RestroOrder\Cleanup-Windows.ps1" -CleanTemp -CleanCache -CleanLogs
        Write-Log "System cleanup completed" SUCCESS
    }
} catch {
    Write-Log "System cleanup failed: $_" WARNING
}

# Final Summary
Write-Log "==========================================" SUCCESS
Write-Log "RestroOrder Installation Completed!" SUCCESS
Write-Log "==========================================" SUCCESS
Write-Log "" INFO
Write-Log "Next Steps:" INFO
Write-Log "1. Configure application settings in C:\RestroOrder\Config\appsettings.json" INFO
Write-Log "2. Update database connection string if needed" INFO
Write-Log "3. Test the application at http://localhost" INFO
Write-Log "4. Check logs at C:\RestroOrder\Logs" INFO
Write-Log "5. If Google Drive was installed, login manually to complete setup" INFO
Write-Log "" INFO
Write-Log "Important Paths:" INFO
Write-Log "  Application: C:\RestroOrder" INFO
Write-Log "  Database: C:\RestroOrder\Database" INFO
Write-Log "  Backups: C:\RestroOrder\Backups" INFO
Write-Log "  Logs: C:\RestroOrder\Logs" INFO
Write-Log "  Scripts: C:\RestroOrder\Scripts" INFO
Write-Log "" INFO
Write-Log "Support: support@restroorder.com" INFO
Write-Log "==========================================" SUCCESS
