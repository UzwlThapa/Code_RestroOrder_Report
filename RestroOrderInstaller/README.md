# RestroOrder Complete Installation & Maintenance Suite

## 🚀 One-Click Automated Installer for New Clients

### Features
- **Auto-enables IIS** with all required features
- **Downloads & installs SQL Server 2019 Developer Edition**
- **Downloads & installs SSMS (SQL Server Management Studio)**
- **Installs all required .NET packages and dependencies**
- **Automated database restore from backup**
- **Runs initial cleanup scripts**
- **Configures Google Drive sync automatically**
- **Sets up scheduled backups to Google Drive**
- **Total installation time: < 15 minutes**

---

## 📦 Package Structure

```
RestroOrderInstaller/
├── Install-RestroOrder.ps1          # Main installer script
├── Cleanup-Windows.ps1              # System cleanup utility
├── Setup-GoogleDrive.ps1            # Google Drive automation
├── DatabaseManager.ps1              # DB backup/restore/cleanup
├── Scripts/
│   ├── FullCleanup.sql              # Complete data wipe
│   ├── SalesOnlyCleanup.sql         # Sales/orders only wipe
│   ├── InitDatabase.sql             # Initial DB setup
│   └── VersionTracking.sql          # DB version tracking
├── Config/
│   ├── appsettings.json.template
│   └── google-drive-config.json
├── Backups/                         # Local backup storage
└── Logs/                            # Installation logs
```

---

## 🔧 Which Cleanup Script to Use?

### **FullCleanup.sql** - COMPLETE DATA WIPE
**Use When:**
- Setting up a brand new client
- Starting completely fresh after demo/testing
- End of business, handing over to new owner
- Major system reset needed

**What It Clears:**
- ✅ ALL sales transactions
- ✅ ALL orders
- ✅ ALL purchases
- ✅ ALL stock movements
- ✅ ALL logs
- ✅ ALL user accounts (except admin)
- ✅ ALL loyalty data
- ✅ ALL housekeeping records
- ✅ ALL accounting transactions
- ⚠️ **KEEPS**: Menu items, categories, ingredients, rates, printer settings, cost centers

**Warning:** This is IRREVERSIBLE. Always backup first!

---

### **SalesOnlyCleanup.sql** - TRANSACTIONAL DATA ONLY
**Use When:**
- End of fiscal year (Nepal FY: Shrawan 1 - Ashad 32)
- Want to keep menu setup but clear transactions
- Testing environment reset
- Go-live preparation after training

**What It Clears:**
- ✅ Sales bills and details
- ✅ Orders and order tokens
- ✅ Purchase transactions
- ✅ Stock transaction history
- ✅ Daily reports
- ✅ Customer balances (resets to 0)
- ✅ Account transactions
- ⚠️ **KEEPS**: 
  - Menu items, categories, recipes
  - Ingredient definitions and rates
  - Vendor master data
  - Cost centers and stores
  - User accounts
  - Printer configurations
  - Table and room setup

**Benefit:** Client can start new fiscal year without rebuilding entire menu!

---

### **LogsOnly Cleanup** - MAINTENANCE
**Use When:**
- System running slow
- Disk space low on 256GB SSD
- Regular monthly maintenance

**What It Clears:**
- ✅ SMS logs
- ✅ Notification logs
- ✅ Session trackers
- ✅ Old daily reports (>30 days)
- ✅ Windows temp files
- ✅ Browser caches
- ✅ SQL temp files

**Safe to run anytime** - no data loss!

---

## 💾 Database Management Options

### FREE Cross-Platform Version Tracking

#### Option 1: Git + SQL Scripts (RECOMMENDED)
**Works on:** Windows, Mac, Linux
**Cost:** FREE
**Setup:**
```bash
# Initialize git repo for database scripts
cd RestroOrder/Scripts
git init
git add *.sql
git commit -m "Initial database schema"

# Track changes
git add FullCleanup.sql
git commit -m "Updated cleanup script for FY 2083"
git push origin main
```

**Benefits:**
- ✅ Complete history of all changes
- ✅ Works on any OS
- ✅ Free forever
- ✅ Can rollback to any version
- ✅ Team collaboration

---

#### Option 2: DbUp (.NET Migration Tool)
**Works on:** Windows, Mac, Linux
**Cost:** FREE (Open Source)
**Best for:** Automated deployments

```csharp
// Automatically tracks which scripts ran
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

#### Option 3: Liquibase
**Works on:** Windows, Mac, Linux
**Cost:** FREE (Community Edition)
**Best for:** Enterprise teams

```yaml
# changelog.yaml
databaseChangeLog:
  - changeSet:
      id: 2024-01-15-cleanup-update
      author: Ujjwal
      changes:
        - sqlFile:
            path: Scripts/FullCleanup_v2.sql
```

---

## ☁️ FREE File Servers & Cloud Storage

| Service | Free Storage | Best For | Sync Speed | Encryption |
|---------|-------------|----------|------------|------------|
| **Google Drive** | 15 GB | Backup sync, easy setup | ⭐⭐⭐⭐⭐ | Yes |
| **OneDrive** | 5 GB | Windows integration | ⭐⭐⭐⭐⭐ | Yes |
| **MEGA** | 20 GB | Encrypted backups | ⭐⭐⭐⭐ | End-to-end |
| **pCloud** | 10 GB | Lifetime plans | ⭐⭐⭐⭐ | Yes |
| **Nextcloud** | Self-hosted | Complete control | ⭐⭐⭐⭐⭐ | Yes |
| **Syncthing** | Unlimited* | P2P sync, no cloud | ⭐⭐⭐⭐⭐ | End-to-end |

\* Limited by your own storage

### **RECOMMENDED: Google Drive** (for most clients)
- Easy automated setup
- 15GB free (enough for years of backups)
- Reliable sync
- Already trusted by businesses

### **RECOMMENDED: Nextcloud** (for large chains)
- Self-hosted on own server
- Unlimited storage (your HDD)
- Complete privacy
- One-time hardware cost

---

## 🚀 Quick Start Commands

### **New Client Installation (15 minutes)**
```powershell
# Run as Administrator
.\Install-RestroOrder.ps1 `
  -BackupFilePath "D:\Backups\RestroOrder_Latest.bak" `
  -CleanupType "Full" `
  -SkipGoogleDrive:$false
```

This will:
1. ✅ Enable IIS with all features
2. ✅ Download & install SQL Server 2019 Dev
3. ✅ Download & install SSMS
4. ✅ Install .NET 8 Hosting Bundle
5. ✅ Restore your database
6. ✅ Run full cleanup (fresh start)
7. ✅ Setup Google Drive sync
8. ✅ Schedule daily backups
9. ✅ Clean Windows temp files

---

### **Daily Maintenance (Automated)**
```powershell
# Morning check (run at 8 AM)
.\DatabaseManager.ps1 -Action HealthCheck

# Evening backup (run at 10 PM)
.\DatabaseManager.ps1 -Action Backup -Destination "C:\RestroOrder\Backups"

# Weekly cleanup (run Sunday 2 AM)
.\Cleanup-Windows.ps1 -CleanTemp -CleanCache -CleanLogs
```

---

### **Emergency Scenarios**

#### **System Crashed, Need to Restore**
```powershell
# Find latest backup
$LatestBackup = Get-ChildItem "C:\RestroOrder\Backups\*.bak" | 
  Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Restore
.\DatabaseManager.ps1 -Action Restore -BackupFile $LatestBackup.FullName
```

#### **Disk Space Critical (<10GB free)**
```powershell
# Emergency cleanup
.\Cleanup-Windows.ps1 -CleanTemp -CleanCache -CleanLogs -CleanWindowsUpdate -DryRun:$false

# Check space saved
Get-PSDrive C | Select-Object Used, Free
```

#### **Database Corrupted**
```powershell
# Run integrity check
.\DatabaseManager.ps1 -Action HealthCheck

# If failed, restore from last good backup
.\DatabaseManager.ps1 -Action Restore -BackupFile "C:\RestroOrder\Backups\RestroOrder_20240115_020000.bak"
```

---

## 📊 Storage Management for 256GB SSD Clients

### **Recommended Partition Scheme**
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

### **Automatic Cleanup Rules**
1. **Keep last 30 days** of local backups
2. **Sync to Google Drive** immediately
3. **Delete local backups >7 days** if synced
4. **Clear temp files** daily
5. **Compress old logs** weekly

### **Monitoring Alerts**
```powershell
# Add to scheduled task (hourly)
$FreeSpace = (Get-PSDrive C).Free / 1GB
if ($FreeSpace -lt 20) {
    Send-MailMessage -To "admin@restroorder.com" `
      -Subject "LOW DISPACE WARNING" `
      -Body "Only $FreeSpace GB free on C:"
}
```

---

## 🇳🇵 Nepal IRD 2026 Compliance Notes

### **Fiscal Year Management**
- Nepal FY: **Shrawan 1** to **Ashad 32** (BS)
- Use `SalesOnlyCleanup.sql` at year end
- Keep all sales data for 7 years (IRD requirement)
- Backup before ANY cleanup

### **VAT Reconciliation**
```sql
-- Monthly VAT report (keep forever)
SELECT 
    CONVERT(varchar, BillDate, 103) as Miti,
    SUM(BillAmount) as TotalSales,
    SUM(VATAmount) as VATCollected
FROM RO_SalesMaster
WHERE BillDate BETWEEN '2083-04-01' AND '2083-04-30'
GROUP BY CONVERT(varchar, BillDate, 103)
```

### **PAN Tracking**
- Never truncate customer tables with PAN
- Keep billing records for IRD audit
- Use `SalesOnlyCleanup.sql` carefully

---

## 📞 Support & Troubleshooting

### **Common Issues**

#### **Installation Fails at SQL Server Step**
```powershell
# Check if previous SQL installation exists
Get-WindowsFeature | Where-Object Name -like "*SQL*"

# Remove completely and retry
.\Install-RestroOrder.ps1 -SkipGoogleDrive
```

#### **Google Drive Not Syncing**
1. Open Google Drive manually
2. Login with client's account
3. Verify sync folder permissions
4. Check internet connection

#### **Backup Taking Too Long**
```powershell
# Compress backups
$BackupPath = "C:\RestroOrder\Backups\Latest.bak"
Compress-Archive -Path $BackupPath -DestinationPath "${BackupPath}.zip"
Remove-Item $BackupPath
```

### **Log Locations**
- Installation: `C:\RestroOrder\Logs\Install_*.log`
- Cleanup: `C:\RestroOrder\Logs\Cleanup_*.log`
- Database: `C:\RestroOrder\Logs\DBManager_*.log`
- Google Drive: `C:\RestroOrder\Logs\GoogleDrive_*.log`

---

## ✅ Pre-Installation Checklist

Before running installer on client machine:

- [ ] **Backup existing data** (if upgrading)
- [ ] **Check disk space** (minimum 50GB free)
- [ ] **Internet connection** (for downloads)
- [ ] **Administrator access**
- [ ] **Google account credentials** (for Drive setup)
- [ ] **Client's latest .bak file**
- [ ] **License keys** (if applicable)

---

## 🎯 Post-Installation Verification

After installation completes:

- [ ] **IIS Running**: Open http://localhost
- [ ] **SQL Server**: Check Services → MSSQLSERVER
- [ ] **SSMS Installed**: Search in Start Menu
- [ ] **Database Restored**: Connect via SSMS
- [ ] **Google Drive**: Verify sync icon in taskbar
- [ ] **Backup Scheduled**: Check Task Scheduler
- [ ] **Test Bill Creation**: Create test bill
- [ ] **Test Report Generation**: Run sales report

---

**Last Updated:** 2026 (2083 BS)  
**Version:** 2.0  
**Author:** RestroOrder Development Team  
**Support:** support@restroorder.com
