# RestroOrder Complete Installation & Maintenance Suite

## 🚀 Quick Start Guide

### For New Client Installation (15 minutes)

**Run as Administrator:**
```powershell
cd C:\Path\To\RestroOrderInstaller
.\Install-RestroOrder.ps1 -BackupFilePath "D:\Backups\RestroOrder_Latest.bak" -CleanupType "Full"
```

This will automatically:
1. ✅ Enable IIS with all required features
2. ✅ Download & install SQL Server 2019 Developer
3. ✅ Download & install SSMS
4. ✅ Install .NET 8 Hosting Bundle
5. ✅ Restore your database
6. ✅ Run cleanup script (fresh start)
7. ✅ Setup Google Drive sync
8. ✅ Schedule daily backups
9. ✅ Clean Windows temp files

---

## 📁 Package Contents

| File | Purpose |
|------|---------|
| `Install-RestroOrder.ps1` | Main installer (IIS, SQL, SSMS, DB restore) |
| `Cleanup-Windows.ps1` | System cleanup (temp files, caches, logs) |
| `Setup-GoogleDrive.ps1` | Google Drive automation |
| `DatabaseManager.ps1` | Backup, restore, cleanup, health checks |
| `Scripts/FullCleanup.sql` | Complete data wipe (new clients) |
| `Scripts/SalesOnlyCleanup.sql` | Sales/orders only (fiscal year end) |
| `README.md` | This comprehensive guide |

---

## 🔧 Which Cleanup Script to Use?

### **FullCleanup.sql** - COMPLETE DATA WIPE

**Use When:**
- Setting up a brand new client
- Starting completely fresh after demo/testing
- End of business, handing over to new owner

**What It Clears:**
- ✅ ALL sales transactions
- ✅ ALL orders
- ✅ ALL purchases
- ✅ ALL stock movements
- ✅ ALL logs
- ✅ ALL user accounts (except admin)
- ✅ ALL loyalty data
- ✅ ALL accounting transactions

**What It KEEPS:**
- ⚠️ Menu items, categories, ingredients
- ⚠️ Printer settings
- ⚠️ Cost centers
- ⚠️ Table and room setup

**⚠️ WARNING:** IRREVERSIBLE! Always backup first!

---

### **SalesOnlyCleanup.sql** - TRANSACTIONAL DATA ONLY

**Use When:**
- End of fiscal year (Nepal FY: Shrawan 1 - Ashad 32)
- Want to keep menu setup but clear transactions
- Go-live preparation after training

**What It Clears:**
- ✅ Sales bills and details
- ✅ Orders and order tokens
- ✅ Purchase transactions
- ✅ Stock transaction history
- ✅ Daily reports
- ✅ Customer balances (resets to 0)
- ✅ Account transactions

**What It KEEPS:**
- ⚠️ Menu items, categories, recipes
- ⚠️ Ingredient definitions and rates
- ⚠️ Vendor master data
- ⚠️ User accounts
- ⚠️ Printer configurations
- ⚠️ Table and room setup

**✅ BENEFIT:** Client can start new fiscal year without rebuilding menu!

---

## 💾 Database Management Commands

### Create Backup
```powershell
.\DatabaseManager.ps1 -Action Backup -Destination "C:\RestroOrder\Backups"
```

### Restore from Backup
```powershell
.\DatabaseManager.ps1 -Action Restore -BackupFile "C:\RestroOrder\Backups\RestroOrder_20240115_020000.bak"
```

### Run Health Check
```powershell
.\DatabaseManager.ps1 -Action HealthCheck
```

### Cleanup Database (with automatic backup first!)
```powershell
# Full cleanup
.\DatabaseManager.ps1 -Action Cleanup -CleanupType "Full"

# Sales only cleanup
.\DatabaseManager.ps1 -Action Cleanup -CleanupType "SalesOnly"
```

### Setup Version Tracking
```powershell
.\DatabaseManager.ps1 -Action VersionTrack
```

---

## 🧹 System Cleanup Commands

### Full System Cleanup
```powershell
.\Cleanup-Windows.ps1 -CleanTemp -CleanCache -CleanLogs -CleanWindowsUpdate
```

### Dry Run (See what would be cleaned)
```powershell
.\Cleanup-Windows.ps1 -DryRun
```

### Clean Specific Items
```powershell
# Only browser cache
.\Cleanup-Windows.ps1 -CleanBrowserCache

# Only temp files
.\Cleanup-Windows.ps1 -CleanTemp

# Only old logs
.\Cleanup-Windows.ps1 -CleanLogs
```

---

## ☁️ Google Drive Setup

### Automated Setup
```powershell
.\Setup-GoogleDrive.ps1
```

### With Custom Paths
```powershell
.\Setup-GoogleDrive.ps1 -BackupFolder "D:\Backups" -SyncPath "C:\Users\Admin\Google Drive\RestroOrder"
```

**After running:**
1. Open Google Drive from system tray
2. Login with your Google account
3. Verify files are syncing to https://drive.google.com

---

## 🆓 FREE Cloud Storage Options

| Service | Free Tier | Best For | Notes |
|---------|-----------|----------|-------|
| **Google Drive** | 15 GB | Most clients | Easy setup, reliable |
| **OneDrive** | 5 GB | Windows integration | Built into Windows |
| **MEGA** | 20 GB | Encrypted backups | End-to-end encryption |
| **pCloud** | 10 GB | Lifetime plans | One-time payment option |
| **Nextcloud** | Self-hosted | Large chains | Complete control |
| **Syncthing** | Unlimited* | P2P sync | No cloud needed |

*Limited by your own storage

**Recommendation:** Use Google Drive for most clients (15GB free = ~6 months of daily backups)

---

## 🗄️ Database Version Tracking (FREE, Cross-Platform)

### Option 1: Git + SQL Scripts (RECOMMENDED)

**Works on:** Windows, Mac, Linux  
**Cost:** FREE

```bash
# Initialize git repo
cd RestroOrder/Scripts
git init
git add *.sql
git commit -m "Initial database scripts"

# Track changes
git add FullCleanup.sql
git commit -m "Updated for FY 2083 BS"
git push origin main
```

**Benefits:**
- ✅ Complete history of all changes
- ✅ Works on any OS
- ✅ Free forever
- ✅ Can rollback to any version
- ✅ Team collaboration

---

### Option 2: DbUp (.NET Migration Tool)

**Works on:** Windows, Mac, Linux  
**Cost:** FREE (Open Source)

```csharp
var upgrader = DeployChanges.To
    .SqlDatabase(connectionString)
    .WithScriptsEmbeddedInAssembly(Assembly.GetExecutingAssembly())
    .LogToConsole()
    .Build();

upgrader.PerformUpgrade(); // Only runs new scripts
```

**Benefits:**
- ✅ Automatic version tracking in database
- ✅ Never runs same script twice
- ✅ Rollback support
- ✅ CI/CD integration

---

### Option 3: Liquibase

**Works on:** Windows, Mac, Linux  
**Cost:** FREE (Community Edition)

```yaml
# changelog.yaml
databaseChangeLog:
  - changeSet:
      id: 2024-01-15-cleanup
      author: YourName
      changes:
        - sqlFile:
            path: Scripts/FullCleanup_v2.sql
```

---

## 🇳🇵 Nepal IRD 2026 Compliance

### Fiscal Year Management
- Nepal FY: **Shrawan 1** to **Ashad 32** (BS)
- Use `SalesOnlyCleanup.sql` at year end
- Keep all sales data for 7 years (IRD requirement)
- **ALWAYS backup before ANY cleanup**

### VAT Reconciliation Query
```sql
SELECT 
    CONVERT(varchar, BillDate, 103) as Miti,
    SUM(BillAmount) as TotalSales,
    SUM(VATAmount) as VATCollected
FROM RO_SalesMaster
WHERE BillDate BETWEEN '2083-04-01' AND '2083-04-30'
GROUP BY CONVERT(varchar, BillDate, 103)
ORDER BY BillDate
```

### PAN Tracking Rules
- ⚠️ Never truncate customer tables with PAN
- ⚠️ Keep billing records for IRD audit (7 years minimum)
- ⚠️ Use `SalesOnlyCleanup.sql` carefully for existing clients

---

## 📊 Storage Management for 256GB SSD

### Recommended Partition Scheme
```
C: Drive (256GB SSD)
├── Windows (80 GB)
├── Program Files (40 GB)
├── RestroOrder (20 GB)
│   ├── Application (5 GB)
│   ├── Database (10 GB)
│   └── Backups (5 GB, rotating)
└── Free Space (116 GB for growth)
```

### Automatic Cleanup Rules
1. ✅ Keep last 30 days of local backups
2. ✅ Sync to Google Drive immediately
3. ✅ Delete local backups >7 days if synced to cloud
4. ✅ Clear temp files daily
5. ✅ Compress old logs weekly

### Low Disk Space Alerts
```powershell
# Add to Task Scheduler (hourly check)
$FreeSpace = (Get-PSDrive C).Free / 1GB
if ($FreeSpace -lt 20) {
    # Send email/notification
    Write-Host "WARNING: Only $FreeSpace GB free!"
}
```

---

## 🚨 Emergency Procedures

### System Crashed - Need to Restore
```powershell
# Find latest backup
$LatestBackup = Get-ChildItem "C:\RestroOrder\Backups\*.bak" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

# Restore
.\DatabaseManager.ps1 -Action Restore -BackupFile $LatestBackup.FullName
```

### Disk Space Critical (<10GB free)
```powershell
# Emergency cleanup
.\Cleanup-Windows.ps1 -CleanTemp -CleanCache -CleanLogs -CleanWindowsUpdate

# Check results
Get-PSDrive C | Select-Object Used, Free
```

### Database Corrupted
```powershell
# Run health check
.\DatabaseManager.ps1 -Action HealthCheck

# If failed, restore from last good backup
.\DatabaseManager.ps1 -Action Restore -BackupFile "C:\RestroOrder\Backups\RestroOrder_YYYYMMDD_HHMMSS.bak"
```

---

## ✅ Pre-Installation Checklist

Before running installer on client machine:

- [ ] Backup existing data (if upgrading)
- [ ] Check disk space (minimum 50GB free)
- [ ] Ensure internet connection (for downloads)
- [ ] Have Administrator access
- [ ] Get Google account credentials (for Drive setup)
- [ ] Prepare client's latest .bak file
- [ ] Have license keys ready (if applicable)

---

## 🎯 Post-Installation Verification

After installation completes:

- [ ] IIS Running: Open http://localhost
- [ ] SQL Server: Check Services → MSSQLSERVER
- [ ] SSMS Installed: Search in Start Menu
- [ ] Database Restored: Connect via SSMS
- [ ] Google Drive: Verify sync icon in taskbar
- [ ] Backup Scheduled: Check Task Scheduler
- [ ] Test Bill Creation: Create test bill
- [ ] Test Report Generation: Run sales report

---

## 📞 Support & Troubleshooting

### Common Issues

#### Installation Fails at SQL Server Step
```powershell
# Check for existing SQL installation
Get-WindowsFeature | Where-Object Name -like "*SQL*"

# Remove and retry
.\Install-RestroOrder.ps1 -SkipGoogleDrive
```

#### Google Drive Not Syncing
1. Open Google Drive manually from system tray
2. Login with client's Google account
3. Verify sync folder permissions
4. Check internet connection
5. Restart Google Drive

#### Backup Taking Too Long
```powershell
# Compress old backups
$BackupPath = "C:\RestroOrder\Backups\Latest.bak"
Compress-Archive -Path $BackupPath -DestinationPath "${BackupPath}.zip"
Remove-Item $BackupPath
```

### Log Locations
- Installation: `C:\RestroOrder\Logs\Install_*.log`
- Cleanup: `C:\RestroOrder\Logs\Cleanup_*.log`
- Database: `C:\RestroOrder\Logs\DBManager_*.log`
- Google Drive: `C:\RestroOrder\Logs\GoogleDrive_*.log`

---

## 📚 Additional Resources

### Official Documentation
- [SQL Server 2019 Docs](https://docs.microsoft.com/sql/sql-server/)
- [IIS Documentation](https://docs.microsoft.com/iis/)
- [Google Drive Help](https://support.google.com/drive/)

### Community Support
- GitHub Issues (for this package)
- Stack Overflow (tag: restroorder)
- Nepal Developers Forum

---

**Last Updated:** 2026 (2083 BS)  
**Version:** 2.0  
**Author:** RestroOrder Development Team  
**License:** Proprietary - RestroOrder Clients Only  
**Support:** support@restroorder.com
