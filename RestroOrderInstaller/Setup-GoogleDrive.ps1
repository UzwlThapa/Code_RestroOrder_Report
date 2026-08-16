<#
.SYNOPSIS
    Automated Google Drive Setup for RestroOrder Backups
.DESCRIPTION
    Installs Google Drive for Desktop, configures sync folders, sets up backup automation
.PARAMETER GoogleEmail
    Optional: Pre-configure Google email (user still needs to login)
.PARAMETER BackupFolder
    Source backup folder to sync
.PARAMETER SyncPath
    Google Drive sync destination path
.EXAMPLE
    .\Setup-GoogleDrive.ps1
.EXAMPLE
    .\Setup-GoogleDrive.ps1 -BackupFolder "D:\Backups"
#>

[CmdletBinding()]
param(
    [string]$GoogleEmail = "",
    [string]$BackupFolder = "C:\RestroOrder\Backups",
    [string]$SyncPath = "C:\Users\$env:USERNAME\Google Drive\RestroOrder"
)

$LogPath = "C:\RestroOrder\Logs\GoogleDrive_$((Get-Date).ToString('yyyyMMdd_HHmmss')).log"

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

Write-Log "==========================================" INFO
Write-Log "Google Drive Setup Started" INFO
Write-Log "==========================================" INFO

# Step 1: Check if Google Drive is already installed
Write-Log "Checking for existing Google Drive installation..." INFO
$GDriveInstalled = Get-Process -Name "GoogleDrive" -ErrorAction SilentlyContinue
$GDriveExe = "$env:ProgramFiles\Google\Drive File Stream\GoogleDrive.exe"

if ($GDriveInstalled -or (Test-Path $GDriveExe)) {
    Write-Log "Google Drive already installed" SUCCESS
} else {
    # Step 2: Download Google Drive for Desktop
    Write-Log "Downloading Google Drive for Desktop..." INFO
    $GDriveUrl = "https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe"
    $GDrivePath = "C:\RestroOrder\Temp\GoogleDriveSetup.exe"
    
    try {
        if (!(Test-Path $GDrivePath)) {
            Invoke-WebRequest -Uri $GDriveUrl -OutFile $GDrivePath -UseBasicParsing
        }
        
        # Step 3: Install Google Drive
        Write-Log "Installing Google Drive for Desktop..." INFO
        Start-Process -FilePath $GDrivePath -ArgumentList "/silent" -Wait
        
        Write-Log "Google Drive installed successfully" SUCCESS
    } catch {
        Write-Log "Failed to download/install Google Drive: $_" ERROR
        Write-Log "Please install manually from https://www.google.com/drive/download/" WARNING
        exit 1
    }
}

# Step 4: Create Sync Directory
Write-Log "Creating sync directory structure..." INFO
try {
    if (!(Test-Path $SyncPath)) {
        New-Item -ItemType Directory -Path $SyncPath -Force | Out-Null
        Write-Log "Created sync directory: $SyncPath" SUCCESS
    }
    
    # Create subfolders
    $SubFolders = @("Backups", "Logs", "Config", "Database")
    foreach ($folder in $SubFolders) {
        $FolderPath = Join-Path $SyncPath $folder
        if (!(Test-Path $FolderPath)) {
            New-Item -ItemType Directory -Path $FolderPath -Force | Out-Null
        }
    }
    Write-Log "Created subfolders: Backups, Logs, Config, Database" SUCCESS
} catch {
    Write-Log "Failed to create directories: $_" WARNING
}

# Step 5: Create Symbolic Link for Auto-Sync
Write-Log "Setting up automatic backup synchronization..." INFO
try {
    $BackupLinkPath = "$SyncPath\Backups"
    
    # Remove existing link if present
    if (Test-Path $BackupLinkPath) {
        Remove-Item -Path $BackupLinkPath -Force -ErrorAction SilentlyContinue
    }
    
    # Create symbolic link
    if (Test-Path $BackupFolder) {
        New-Item -ItemType SymbolicLink -Path $BackupLinkPath -Target $BackupFolder -Force | Out-Null
        Write-Log "Created symbolic link: $BackupFolder -> $BackupLinkPath" SUCCESS
    } else {
        Write-Log "Backup folder not found: $BackupFolder" WARNING
    }
} catch {
    Write-Log "Failed to create symbolic link: $_" WARNING
    Write-Log "You can manually copy backups to: $SyncPath\Backups" INFO
}

# Step 6: Configure Google Drive Settings
Write-Log "Configuring Google Drive preferences..." INFO

$GDriveConfig = @{
    BackupEnabled = $true
    SyncPath = $SyncPath
    BackupSource = $BackupFolder
    AutoSync = $true
    RetentionDays = 90
    CompressionEnabled = $true
    EncryptionEnabled = $false
    LastSyncCheck = Get-Date
} | ConvertTo-Json -Depth 5

$ConfigPath = "C:\RestroOrder\Config\google-drive-config.json"
$GDriveConfig | Out-File -FilePath $ConfigPath -Encoding UTF8
Write-Log "Configuration saved to: $ConfigPath" SUCCESS

# Step 7: Setup Scheduled Sync Check
Write-Log "Setting up hourly sync verification..." INFO
try {
    $TaskName = "RestroOrder-GDriveSyncCheck"
    
    # Remove existing task
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    
    $SyncScript = @"
`$SourcePath = '$BackupFolder'
`$DestPath = '$SyncPath\Backups'
`$RecentFiles = Get-ChildItem `\$SourcePath -File | Where-Object { `$_.LastWriteTime -gt (Get-Date).AddHours(-1) }

foreach (`$file in `$RecentFiles) {
    Copy-Item `$file.FullName -Destination `$DestPath -Force
}

# Compress old backups (>7 days)
`$OldBackups = Get-ChildItem `\$DestPath -Filter *.bak | Where-Object { `$_.LastWriteTime -lt (Get-Date).AddDays(-7) }
foreach (`$backup in `$OldBackups) {
    if (!(Test-Path "`$(`$backup.FullName).zip")) {
        Compress-Archive -Path `$backup.FullName -DestinationPath "`$(`$backup.FullName).zip"
        Remove-Item `$backup.FullName
    }
}
"@
    
    $SyncScriptPath = "C:\RestroOrder\Sync-GoogleDrive.ps1"
    $SyncScript | Out-File -FilePath $SyncScriptPath -Encoding UTF8
    
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-ExecutionPolicy Bypass -File $SyncScriptPath"
    $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Hours 1)
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal -Force
    Write-Log "Hourly sync check scheduled" SUCCESS
} catch {
    Write-Log "Failed to create scheduled task: $_" WARNING
}

# Step 8: Create Initial Test Backup
Write-Log "Creating initial test file..." INFO
try {
    $TestFile = "$BackupFolder\GoogleDrive_Test_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    @"
RestroOrder Google Drive Sync Test
===================================
Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Computer: $env:COMPUTERNAME
User: $env:USERNAME

This file confirms that Google Drive sync is working correctly.
If you see this file in your Google Drive web interface, sync is active!

Next Steps:
1. Open Google Drive from system tray
2. Login with your Google account
3. Verify files are syncing to cloud
4. Check https://drive.google.com for uploaded files
"@ | Out-File -FilePath $TestFile -Encoding UTF8
    
    Write-Log "Test file created: $TestFile" SUCCESS
} catch {
    Write-Log "Failed to create test file: $_" WARNING
}

# Step 9: Verify Installation
Write-Log "Verifying Google Drive installation..." INFO
Start-Sleep -Seconds 10

$GDriveRunning = Get-Process -Name "GoogleDrive" -ErrorAction SilentlyContinue
if ($GDriveRunning) {
    Write-Log "✓ Google Drive is running" SUCCESS
} else {
    Write-Log "⚠ Google Drive may need manual startup" WARNING
    Write-Log "  Action: Open Google Drive from Start Menu or System Tray" INFO
}

# Check if logged in
$GDriveUserDataPath = "$env:LOCALAPPDATA\Google\DriveFS"
if (Test-Path $GDriveUserDataPath) {
    $Accounts = Get-ChildItem -Path $GDriveUserDataPath -Directory -ErrorAction SilentlyContinue
    if ($Accounts.Count -gt 0) {
        Write-Log "✓ Google Drive has $($Accounts.Count) configured account(s)" SUCCESS
    } else {
        Write-Log "⚠ No Google accounts configured yet" WARNING
        Write-Log "  Action: Open Google Drive and login with your account" INFO
    }
}

# Step 10: Display Summary
Write-Log "==========================================" SUCCESS
Write-Log "Google Drive Setup Completed!" SUCCESS
Write-Log "==========================================" SUCCESS
Write-Log "" INFO
Write-Log "Important Information:" INFO
Write-Log "  Sync Path: $SyncPath" INFO
Write-Log "  Backup Folder: $BackupFolder" INFO
Write-Log "  Config File: $ConfigPath" INFO
Write-Log "" INFO
Write-Log "Required Manual Steps:" INFO
Write-Log "  1. Open Google Drive from system tray" INFO
Write-Log "  2. Login with your Google account" INFO
Write-Log "  3. Wait for initial sync to complete" INFO
Write-Log "  4. Verify files at https://drive.google.com" INFO
Write-Log "" INFO
Write-Log "Automatic Features Enabled:" INFO
Write-Log "  ✓ Hourly sync checks" INFO
Write-Log "  ✓ Automatic backup compression (after 7 days)" INFO
Write-Log "  ✓ Symbolic link for seamless sync" INFO
Write-Log "  ✓ Test file created for verification" INFO
Write-Log "" INFO
Write-Log "Storage Recommendations:" INFO
Write-Log "  - Free Google Drive tier: 15 GB" INFO
Write-Log "  - Estimated monthly backup size: 2-5 GB" INFO
Write-Log "  - Consider upgrading to 100 GB (₹130/month) for multiple clients" INFO
Write-Log "" INFO
Write-Log "Troubleshooting:" INFO
Write-Log "  - If sync fails, check internet connection" INFO
Write-Log "  - Ensure sufficient Google Drive storage" INFO
Write-Log "  - Restart Google Drive from system tray" INFO
Write-Log "  - Check logs: C:\RestroOrder\Logs\GoogleDrive_*.log" INFO
Write-Log "==========================================" SUCCESS
