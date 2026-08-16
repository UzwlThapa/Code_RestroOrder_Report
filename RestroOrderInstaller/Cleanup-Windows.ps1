<#
.SYNOPSIS
    Automated Windows Cleanup for RestroOrder Client Systems
.DESCRIPTION
    Removes temporary files, caches, logs, and unnecessary data to keep 256GB SSD systems clean
.PARAMETER CleanTemp
    Clean temporary files
.PARAMETER CleanCache
    Clean browser and system caches
.PARAMETER CleanLogs
    Clean old log files
.PARAMETER CleanWindowsUpdate
    Clean Windows Update cache
.PARAMETER CleanBrowserCache
    Clean browser caches specifically
.PARAMETER CleanSQLTemp
    Clean SQL Server temp files
.PARAMETER DryRun
    Show what would be cleaned without actually deleting
.EXAMPLE
    .\Cleanup-Windows.ps1 -CleanTemp -CleanCache -CleanLogs
.EXAMPLE
    .\Cleanup-Windows.ps1 -DryRun
#>

[CmdletBinding()]
param(
    [switch]$CleanTemp,
    [switch]$CleanCache,
    [switch]$CleanLogs,
    [switch]$CleanWindowsUpdate,
    [switch]$CleanBrowserCache,
    [switch]$CleanSQLTemp,
    [switch]$DryRun
)

$LogPath = "C:\RestroOrder\Logs\Cleanup_$((Get-Date).ToString('yyyyMMdd_HHmmss')).log"

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

function Get-FolderSize {
    param([string]$Path)
    if (Test-Path $Path) {
        try {
            $size = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | 
                     Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            return [math]::Round($size / 1MB, 2)
        } catch {
            return 0
        }
    }
    return 0
}

Write-Log "==========================================" INFO
Write-Log "Windows Cleanup Started" INFO
Write-Log "Mode: $(if ($DryRun) { 'DRY RUN - No changes will be made' } else { 'LIVE - Files will be deleted' })" INFO
Write-Log "==========================================" INFO

$TotalSaved = 0
$StartTime = Get-Date

# If no specific switches provided, run all cleanups
$RunAll = !$PSBoundParameters.Keys

# Clean Temp Files
if ($CleanTemp -or $RunAll) {
    Write-Log "Cleaning Temporary Files..." INFO
    
    $TempPaths = @(
        "$env:TEMP\*",
        "$env:TMP\*",
        "C:\Windows\Temp\*",
        "C:\RestroOrder\Temp\*"
    )
    
    foreach ($path in $TempPaths) {
        if (Test-Path $path) {
            $sizeBefore = Get-FolderSize $path
            if (!$DryRun) {
                try {
                    Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | 
                        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                } catch {
                    Write-Log "  Could not clean: $path" WARNING
                }
            }
            $TotalSaved += $sizeBefore
            Write-Log "  Cleaned: $path ($sizeBefore MB)" INFO
        }
    }
}

# Clean Browser Caches
if ($CleanBrowserCache -or $CleanCache -or $RunAll) {
    Write-Log "Cleaning Browser Caches..." INFO
    
    $BrowserCachePaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*",
        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\entries\*",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Service Worker\CacheStorage\*",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage\*"
    )
    
    foreach ($path in $BrowserCachePaths) {
        if (Test-Path $path) {
            $sizeBefore = Get-FolderSize $path
            if (!$DryRun) {
                try {
                    Get-ChildItem -Path $path -ErrorAction SilentlyContinue | 
                        Remove-Item -Force -ErrorAction SilentlyContinue
                } catch {
                    Write-Log "  Could not clean: $path (browser may be running)" WARNING
                }
            }
            $TotalSaved += $sizeBefore
            Write-Log "  Cleaned: $path ($sizeBefore MB)" INFO
        }
    }
}

# Clean Windows Update Cache
if ($CleanWindowsUpdate -or $RunAll) {
    Write-Log "Cleaning Windows Update Cache..." INFO
    
    $WinUpdatePath = "C:\Windows\SoftwareDistribution\Download\*"
    if (Test-Path $WinUpdatePath) {
        $sizeBefore = Get-FolderSize $WinUpdatePath
        if (!$DryRun) {
            try {
                Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
                Get-ChildItem -Path $WinUpdatePath -Recurse -Force -ErrorAction SilentlyContinue | 
                    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
            } catch {
                Write-Log "  Could not stop Windows Update service" WARNING
            }
        }
        $TotalSaved += $sizeBefore
        Write-Log "  Cleaned: $WinUpdatePath ($sizeBefore MB)" INFO
    }
}

# Clean SQL Server Temp
if ($CleanSQLTemp -or $RunAll) {
    Write-Log "Checking SQL Server Temporary Files..." INFO
    
    $SQLPaths = @(
        "C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Data\tempdb*",
        "C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\Log\*.trn"
    )
    
    foreach ($path in $SQLPaths) {
        if (Test-Path $path) {
            $sizeBefore = Get-FolderSize $path
            Write-Log "  Found SQL temp: $path ($sizeBefore MB)" INFO
            Write-Log "  Note: SQL temp files managed by SQL Server automatically" WARNING
        }
    }
}

# Clean Old Log Files (keep last 30 days)
if ($CleanLogs -or $RunAll) {
    Write-Log "Cleaning Old Log Files (keeping last 30 days)..." INFO
    
    $LogPaths = @(
        "C:\RestroOrder\Logs",
        "C:\Windows\Logs",
        "$env:LOCALAPPDATA\Temp"
    )
    
    foreach ($path in $LogPaths) {
        if (Test-Path $path) {
            $cutoffDate = (Get-Date).AddDays(-30)
            $oldFiles = Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | 
                Where-Object { $_.LastWriteTime -lt $cutoffDate -and $_.Extension -in @('.log', '.txt', '.bak') }
            
            $sizeBefore = ($oldFiles | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB
            if (!$DryRun) {
                $oldFiles | Remove-Item -Force -ErrorAction SilentlyContinue
            }
            if ($sizeBefore -gt 0) {
                $TotalSaved += $sizeBefore
                Write-Log "  Cleaned old logs from: $path ($sizeBefore MB)" INFO
            }
        }
    }
}

# Clean Recycle Bin
Write-Log "Emptying Recycle Bin..." INFO
if (!$DryRun) {
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Log "  Recycle Bin emptied" INFO
    } catch {
        Write-Log "  Could not empty Recycle Bin" WARNING
    }
}

# Run Disk Cleanup utility
Write-Log "Running Windows Disk Cleanup utility..." INFO
if (!$DryRun) {
    try {
        # Use cleanmgr with silent mode
        $cleanMgrArgs = "/d C: /VERYLOWDISKSPACE /AUTOCLEAN"
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList $cleanMgrArgs -Wait -NoNewWindow
        Write-Log "  Disk Cleanup completed" INFO
    } catch {
        Write-Log "  Disk Cleanup utility not available" WARNING
    }
}

# Clean IIS Logs (keep last 7 days)
Write-Log "Cleaning Old IIS Logs (keeping last 7 days)..." INFO
$IISLogPath = "C:\inetpub\logs\LogFiles\W3SVC1"
if (Test-Path $IISLogPath) {
    $cutoffDate = (Get-Date).AddDays(-7)
    $oldLogs = Get-ChildItem -Path $IISLogPath -File -ErrorAction SilentlyContinue | 
        Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    $sizeBefore = ($oldLogs | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB
    if (!$DryRun) {
        $oldLogs | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    if ($sizeBefore -gt 0) {
        $TotalSaved += $sizeBefore
        Write-Log "  Cleaned IIS logs: $sizeBefore MB" INFO
    }
}

# Calculate time taken
$EndTime = Get-Date
$Duration = New-TimeSpan -Start $StartTime -End $EndTime

Write-Log "==========================================" SUCCESS
Write-Log "Cleanup Completed!" SUCCESS
Write-Log "Total Space Saved: $([math]::Round($TotalSaved, 2)) MB ($([math]::Round($TotalSaved / 1024, 2)) GB)" INFO
Write-Log "Time Taken: $($Duration.Minutes)m $($Duration.Seconds)s" INFO
Write-Log "==========================================" SUCCESS

# Show disk space summary
Write-Log "" INFO
Write-Log "Current Disk Space:" INFO
$DiskInfo = Get-PSDrive C
Write-Log "  Used: $([math]::Round($DiskInfo.Used / 1GB, 2)) GB" INFO
Write-Log "  Free: $([math]::Round($DiskInfo.Free / 1GB, 2)) GB" INFO
Write-Log "  Total: $([math]::Round(($DiskInfo.Used + $DiskInfo.Free) / 1GB, 2)) GB" INFO
Write-Log "" INFO

if ($DiskInfo.Free / 1GB -lt 20) {
    Write-Log "WARNING: Less than 20GB free! Consider additional cleanup." WARNING
} elseif ($DiskInfo.Free / 1GB -lt 10) {
    Write-Log "CRITICAL: Less than 10GB free! Immediate action required!" ERROR
}
