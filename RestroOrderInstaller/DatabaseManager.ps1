<#
.SYNOPSIS
    Comprehensive Database Management for RestroOrder
.DESCRIPTION
    Backup, Restore, Cleanup, Version Tracking, Health Checks
.PARAMETER Action
    Action to perform: Backup, Restore, Cleanup, HealthCheck, VersionTrack
.PARAMETER DatabaseName
    Name of the database (default: RestroOrder)
.PARAMETER ServerInstance
    SQL Server instance (default: localhost)
.PARAMETER Destination
    Backup destination folder
.PARAMETER BackupFile
    Specific backup file for restore operation
.PARAMETER CleanupType
    Type of cleanup: Full, SalesOnly, LogsOnly
.EXAMPLE
    .\DatabaseManager.ps1 -Action Backup -Destination "C:\RestroOrder\Backups"
.EXAMPLE
    .\DatabaseManager.ps1 -Action HealthCheck
.EXAMPLE
    .\DatabaseManager.ps1 -Action Restore -BackupFile "D:\Backups\RestroOrder.bak"
.EXAMPLE
    .\DatabaseManager.ps1 -Action Cleanup -CleanupType "SalesOnly"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Backup", "Restore", "Cleanup", "HealthCheck", "VersionTrack")]
    [string]$Action,
    
    [string]$DatabaseName = "RestroOrder",
    [string]$ServerInstance = "localhost",
    [string]$Destination = "C:\RestroOrder\Backups",
    [string]$BackupFile = "",
    [ValidateSet("Full", "SalesOnly", "LogsOnly")]
    [string]$CleanupType = "Full"
)

$LogPath = "C:\RestroOrder\Logs\DBManager_$((Get-Date).ToString('yyyyMMdd_HHmmss')).log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    if (!(Test-Path (Split-Path $LogPath))) {
        New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null
    }
    Add-Content -Path $LogPath -Value $logEntry
    
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    Write-Host $Message -ForegroundColor $color
}

function Backup-Database {
    param([string]$DbName, [string]$Dest)
    
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $BackupFileName = "${DbName}_${Timestamp}.bak"
    $BackupPath = Join-Path $Dest $BackupFileName
    
    Write-Log "Starting backup of $DbName to $BackupPath..." INFO
    
    try {
        # Ensure SqlServer module is available
        if (!(Get-Module -ListAvailable -Name SqlServer)) {
            Write-Log "Installing SqlServer PowerShell module..." INFO
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
            Install-Module -Name SqlServer -AllowClobber -Scope CurrentUser -Force | Out-Null
        }
        
        Import-Module SqlServer -ErrorAction Stop
        
        # Perform backup with compression
        Backup-SqlDatabase -ServerInstance $ServerInstance -Database $DbName `
            -BackupFile $BackupPath -CompressionOption On -Verbose:$false
        
        Write-Log "Backup completed successfully: $BackupFileName" SUCCESS
        
        # Verify backup and get size
        if (Test-Path $BackupPath) {
            $BackupSize = (Get-Item $BackupPath).Length / 1MB
            Write-Log "Backup size: $([math]::Round($BackupSize, 2)) MB" INFO
            
            # Create SHA256 checksum
            $Hash = Get-FileHash -Path $BackupPath -Algorithm SHA256
            $HashInfo = @{
                FileName = $BackupFileName
                Hash = $Hash.Hash
                Algorithm = "SHA256"
                Created = Get-Date
                SizeMB = [math]::Round($BackupSize, 2)
            } | ConvertTo-Json
            
            $HashInfo | Out-File -FilePath "${BackupPath}.sha256" -Encoding UTF8
            Write-Log "SHA256 checksum created and saved" SUCCESS
        }
        
        # Cleanup old backups (keep last 30 days locally)
        Write-Log "Cleaning up old backups (keeping last 30 days)..." INFO
        $CutoffDate = (Get-Date).AddDays(-30)
        $OldBackups = Get-ChildItem -Path $Dest -Filter "*.bak" | 
            Where-Object { $_.LastWriteTime -lt $CutoffDate }
        
        foreach ($oldBackup in $OldBackups) {
            Remove-Item -Path $oldBackup.FullName -Force
            Remove-Item -Path "${oldBackup.FullName}.sha256" -Force -ErrorAction SilentlyContinue
            Write-Log "  Deleted old backup: $($oldBackup.Name)" INFO
        }
        
        return $BackupPath
        
    } catch {
        Write-Log "Backup failed: $_" ERROR
        throw
    }
}

function Restore-Database {
    param([string]$DbName, [string]$BackupPath)
    
    Write-Log "Starting restore of $DbName from $BackupPath..." WARNING
    Write-Log "This will OVERWRITE existing database!" WARNING
    
    try {
        # Verify backup file exists
        if (!(Test-Path $BackupPath)) {
            throw "Backup file not found: $BackupPath"
        }
        
        # Verify checksum if available
        $ChecksumFile = "${BackupPath}.sha256"
        if (Test-Path $ChecksumFile) {
            Write-Log "Verifying backup integrity..." INFO
            $StoredHash = (Get-Content $ChecksumFile | ConvertFrom-Json).Hash
            $CurrentHash = (Get-FileHash -Path $BackupPath -Algorithm SHA256).Hash
            
            if ($StoredHash -eq $CurrentHash) {
                Write-Log "Backup integrity verified ✓" SUCCESS
            } else {
                Write-Log "WARNING: Backup file may be corrupted!" ERROR
                Write-Log "Stored hash:   $StoredHash" WARNING
                Write-Log "Current hash:  $CurrentHash" WARNING
                Write-Log "Proceeding anyway... Use at your own risk!" WARNING
            }
        }
        
        # Create backup before restore (safety measure)
        $PreRestoreBackup = "C:\RestroOrder\Backups\PreRestore_$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"
        Write-Log "Creating pre-restore backup: $PreRestoreBackup" INFO
        try {
            Backup-SqlDatabase -ServerInstance $ServerInstance -Database $DbName `
                -BackupFile $PreRestoreBackup -CompressionOption On -ErrorAction SilentlyContinue
            Write-Log "Pre-restore backup created" SUCCESS
        } catch {
            Write-Log "Could not create pre-restore backup (database may not exist)" WARNING
        }
        
        # Restore database
        $RestoreScript = @"
USE master;
GO
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'$DbName')
BEGIN
    ALTER DATABASE [$DbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$DbName];
END
GO
RESTORE DATABASE [$DbName]
FROM DISK = N'$BackupPath'
WITH MOVE '$DbName' TO 'C:\RestroOrder\Database\$DbName.mdf',
     MOVE '${DbName}_log' TO 'C:\RestroOrder\Database\$DbName_log.ldf',
     REPLACE,
     STATS = 10;
GO
"@
        
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $RestoreScript
        Write-Log "Database restored successfully" SUCCESS
        
        # Verify integrity
        Write-Log "Running database integrity check..." INFO
        $CheckResult = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DbName `
            -Query "DBCC CHECKDB('$DbName') WITH NO_INFOMSGS" -Verbose:$false
        
        $Errors = $CheckResult | Where-Object { $_.Message -like "*error*" -or $_.Message -like "*corrupt*" }
        if ($Errors.Count -eq 0) {
            Write-Log "Database integrity verified ✓" SUCCESS
        } else {
            Write-Log "WARNING: Database integrity issues detected!" WARNING
            $Errors | ForEach-Object { Write-Log "  $($_.Message)" WARNING }
        }
        
    } catch {
        Write-Log "Restore failed: $_" ERROR
        throw
    }
}

function Cleanup-Database {
    param([string]$DbName, [string]$Type)
    
    Write-Log "Starting $Type cleanup on $DbName..." WARNING
    Write-Log "===========================================" WARNING
    Write-Log "IRREVERSIBLE ACTION - All selected data will be PERMANENTLY deleted!" ERROR
    Write-Log "===========================================" WARNING
    
    # Always backup before cleanup
    Write-Log "Creating pre-cleanup backup..." INFO
    $PreBackup = Backup-Database -DbName $DbName -Dest $Destination
    Write-Log "Pre-cleanup backup saved at: $PreBackup" SUCCESS
    
    # Determine script path
    $ScriptFile = switch ($Type) {
        "Full" { "C:\RestroOrder\Scripts\FullCleanup.sql" }
        "SalesOnly" { "C:\RestroOrder\Scripts\SalesOnlyCleanup.sql" }
        "LogsOnly" { "C:\RestroOrder\Scripts\LogsCleanup.sql" }
    }
    
    if (!(Test-Path $ScriptFile)) {
        throw "Cleanup script not found: $ScriptFile"
    }
    
    Write-Log "Executing cleanup script: $ScriptFile" INFO
    
    try {
        $Result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DbName `
            -InputFile $ScriptFile -Verbose:$false
        
        # Display any output from the script
        if ($Result) {
            $Result | ForEach-Object { Write-Log $_.Message INFO }
        }
        
        Write-Log "$Type cleanup completed successfully" SUCCESS
        Write-Log "Pre-cleanup backup available at: $PreBackup" INFO
        Write-Log "If you need to restore, run:" INFO
        Write-Log "  .\DatabaseManager.ps1 -Action Restore -BackupFile '$PreBackup'" INFO
        
    } catch {
        Write-Log "Cleanup failed: $_" ERROR
        Write-Log "You can restore from: $PreBackup" WARNING
        throw
    }
}

function HealthCheck-Database {
    param([string]$DbName)
    
    Write-Log "Running comprehensive health check on $DbName..." INFO
    Write-Log "===========================================" INFO
    
    $Results = @{
        DatabaseExists = $false
        State = $null
        SizeMB = 0
        LastBackup = $null
        IntegrityOK = $false
        ActiveConnections = 0
        GrowthSettings = $null
        RecoveryModel = $null
        CompatibilityLevel = 0
        Issues = @()
    }
    
    try {
        Import-Module SqlServer -ErrorAction SilentlyContinue
        
        # Check if database exists and get basic info
        $DbInfo = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query @"
SELECT 
    name,
    state_desc,
    recovery_model_desc,
    compatibility_level,
    (SELECT SUM(size) * 8 / 1024 FROM sys.master_files WHERE database_id = DB_ID('$DbName')) as SizeMB
FROM sys.databases 
WHERE name = '$DbName'
"@
        
        if ($DbInfo) {
            $Results.DatabaseExists = $true
            $Results.State = $DbInfo.state_desc
            $Results.SizeMB = [math]::Round($DbInfo.SizeMB, 2)
            $Results.RecoveryModel = $DbInfo.recovery_model_desc
            $Results.CompatibilityLevel = $DbInfo.compatibility_level
            
            Write-Log "✓ Database exists" SUCCESS
            Write-Log "  State: $($DbInfo.state_desc)" INFO
            Write-Log "  Size: $([math]::Round($DbInfo.SizeMB, 2)) MB" INFO
            Write-Log "  Recovery Model: $($DbInfo.recovery_model_desc)" INFO
        } else {
            $Results.Issures += "Database does not exist"
            Write-Log "✗ Database does not exist" ERROR
        }
        
        # Check last backup
        $LastBackup = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query @"
SELECT TOP 1 
    backup_finish_date,
    type,
    physical_device_name
FROM msdb.dbo.backupset 
WHERE database_name = '$DbName' 
ORDER BY backup_finish_date DESC
"@
        
        if ($LastBackup) {
            $Results.LastBackup = $LastBackup.backup_finish_date
            $BackupAge = (New-TimeSpan -Start $LastBackup.backup_finish_date -End (Get-Date)).TotalHours
            Write-Log "✓ Last backup: $($LastBackup.backup_finish_date)" INFO
            Write-Log "  Backup age: $([math]::Round($BackupAge, 1)) hours" INFO
            
            if ($BackupAge -gt 24) {
                $Results.Issues += "Backup is older than 24 hours"
                Write-Log "⚠ WARNING: Backup is older than 24 hours!" WARNING
            }
        } else {
            $Results.Issues += "No backup found"
            Write-Log "✗ No backup found" ERROR
        }
        
        # Check integrity
        Write-Log "Running integrity check (DBCC CHECKDB)..." INFO
        try {
            $Integrity = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DbName `
                -Query "DBCC CHECKDB('$DbName') WITH NO_INFOMSGS" -Verbose:$false
            
            $Errors = $Integrity | Where-Object { 
                $_.Message -like "*error*" -or $_.Message -like "*corrupt*" -or $_.Message -like "*alloc*"
            }
            
            if ($Errors.Count -eq 0) {
                $Results.IntegrityOK = $true
                Write-Log "✓ Database integrity OK" SUCCESS
            } else {
                $Results.Issues += "Database integrity issues detected"
                Write-Log "✗ Database integrity issues found!" ERROR
                $Errors | ForEach-Object { Write-Log "  $($_.Message)" ERROR }
            }
        } catch {
            $Results.Issues += "Could not run integrity check"
            Write-Log "⚠ Could not run integrity check" WARNING
        }
        
        # Check active connections
        $Connections = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query @"
SELECT COUNT(*) as ActiveConnections 
FROM sys.dm_exec_sessions 
WHERE database_id = DB_ID('$DbName')
"@
        $Results.ActiveConnections = $Connections.ActiveConnections
        Write-Log "Active connections: $($Connections.ActiveConnections)" INFO
        
        # Summary
        Write-Log "===========================================" INFO
        Write-Log "HEALTH CHECK SUMMARY" INFO
        Write-Log "===========================================" INFO
        
        if ($Results.Issues.Count -eq 0) {
            Write-Log "✓ Database is HEALTHY" SUCCESS
        } else {
            Write-Log "⚠ Database has ISSUES that need attention:" WARNING
            $Results.Issues | ForEach-Object { Write-Log "  - $_" WARNING }
        }
        
        Write-Log "" INFO
        Write-Log "Recommendations:" INFO
        if ($Results.LastBackup -eq $null -or $BackupAge -gt 24) {
            Write-Log "  • Run backup immediately" WARNING
        }
        if (!$Results.IntegrityOK) {
            Write-Log "  • Investigate integrity issues" ERROR
        }
        if ($Results.SizeMB -gt 10000) {
            Write-Log "  • Consider database maintenance (shrink/archive)" INFO
        }
        
    } catch {
        Write-Log "Health check failed: $_" ERROR
        $Results.Issues += "Health check failed: $_"
    }
    
    return $Results
}

function Track-DatabaseVersion {
    param([string]$DbName)
    
    Write-Log "Setting up database version tracking..." INFO
    
    try {
        $VersionScript = @"
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DB_VersionHistory')
BEGIN
    CREATE TABLE DB_VersionHistory (
        VersionID INT IDENTITY(1,1) PRIMARY KEY,
        VersionNumber VARCHAR(50) NOT NULL,
        AppliedDate DATETIME DEFAULT GETDATE(),
        Description NVARCHAR(500),
        ScriptHash VARCHAR(64),
        Success BIT DEFAULT 1,
        ExecutedBy NVARCHAR(100) DEFAULT SYSTEM_USER
    );
    PRINT 'Created DB_VersionHistory table';
END

-- Insert current version record
INSERT INTO DB_VersionHistory (VersionNumber, Description, ScriptHash, Success)
VALUES ('2.0-INITIAL', 'Initial version tracking setup', '', 1);

-- Show version history
SELECT TOP 10 
    VersionNumber,
    AppliedDate,
    Description,
    CASE WHEN Success = 1 THEN 'Success' ELSE 'Failed' END as Status,
    ExecutedBy
FROM DB_VersionHistory
ORDER BY AppliedDate DESC;
"@
        
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DbName -Query $VersionScript
        Write-Log "Version tracking initialized successfully" SUCCESS
        Write-Log "Table created: DB_VersionHistory" INFO
        Write-Log "Use this table to track all schema changes and cleanup scripts" INFO
        
    } catch {
        Write-Log "Failed to setup version tracking: $_" ERROR
    }
}

# Main execution
Write-Log "==========================================" INFO
Write-Log "RestroOrder Database Manager" INFO
Write-Log "Action: $Action" INFO
Write-Log "Database: $DatabaseName" INFO
Write-Log "Server: $ServerInstance" INFO
Write-Log "==========================================" INFO

try {
    switch ($Action) {
        "Backup" {
            $BackupPath = Backup-Database -DbName $DatabaseName -Dest $Destination
            Write-Log "==========================================" SUCCESS
            Write-Log "BACKUP COMPLETED" SUCCESS
            Write-Log "Location: $BackupPath" INFO
            Write-Log "==========================================" SUCCESS
        }
        
        "Restore" {
            if ([string]::IsNullOrEmpty($BackupFile)) {
                throw "BackupFile parameter is required for Restore action. Usage: -BackupFile 'C:\Path\To\Backup.bak'"
            }
            Restore-Database -DbName $DatabaseName -BackupPath $BackupFile
            Write-Log "==========================================" SUCCESS
            Write-Log "RESTORE COMPLETED" SUCCESS
            Write-Log "==========================================" SUCCESS
        }
        
        "Cleanup" {
            Cleanup-Database -DbName $DatabaseName -Type $CleanupType
            Write-Log "==========================================" SUCCESS
            Write-Log "CLEANUP COMPLETED" SUCCESS
            Write-Log "Type: $CleanupType" INFO
            Write-Log "==========================================" SUCCESS
        }
        
        "HealthCheck" {
            $Results = HealthCheck-Database -DbName $DatabaseName
            Write-Log "==========================================" INFO
            Write-Log "Health check results saved to: $LogPath" INFO
            Write-Log "==========================================" INFO
        }
        
        "VersionTrack" {
            Track-DatabaseVersion -DbName $DatabaseName
            Write-Log "==========================================" SUCCESS
            Write-Log "VERSION TRACKING SETUP COMPLETE" SUCCESS
            Write-Log "==========================================" SUCCESS
        }
    }
} catch {
    Write-Log "==========================================" ERROR
    Write-Log "OPERATION FAILED" ERROR
    Write-Log "Error: $_" ERROR
    Write-Log "Check logs at: $LogPath" ERROR
    Write-Log "==========================================" ERROR
    exit 1
}
