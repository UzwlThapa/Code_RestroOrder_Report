# RestroOrder Reports - Complete Modern POS Reporting System 2026

Enterprise-grade reporting solution for RestroOrder POS with **Nepal IRD 2026 compliance**, 
**automatic backup & restore**, **crash detection**, and **comprehensive analytics**.

## 🚀 What's New - Complete Feature Set

### Core Reports (Enhanced)
- **IRD Nepal Sales Book** - Existing (`usp_ro_GetSalesBook`)
- **IRD Nepal Sales Return Book** - Existing (`usp_ro_GetReturnedSalesBook`)
- **Materialized Sales Report** - Existing (`usp_MaterializedReportView`)
- **Filterable Sales Report** - Item/Unit/Rate/Cost-Center/Table/Payment-Mode wise

### NEW: Comprehensive Reports
- **Comprehensive Sales Report** - Full bill details with customer info, payment breakdown, audit trail
- **Sales Summary** - Aggregated stats by payment mode, category, with min/max/avg analysis
- **Item Sales Report** - Detailed item-wise sales with profit margins, cost analysis
- **Item Sales Summary** - Top-selling items, profitability analysis
- **Discount Report** - All discounts given, by type (Member/Corporate/Manager/Owner)
- **Discount Summary** - Discount analytics by type and user
- **Customer Report** - Complete customer analytics with visit history, spending patterns
- **Vendor Report** - Purchase history, outstanding balances (when vendor tables exist)
- **IRD Daily Summary** - Nepal IRD 2026 compliant daily reconciliation

### NEW: Backup & Restore System
- **Automatic Scheduled Backups** - Daily/hourly configurable
- **Manual On-Demand Backups** - Via API or UI
- **Emergency Crash Backups** - Auto-triggered on system anomalies
- **SHA-256 Checksum Verification** - Ensures backup integrity
- **RESTORE VERIFYONLY** - Validates backups before use
- **Retention Policy** - Auto-cleanup of old backups (configurable days)
- **Backup Statistics** - Size, count, success rate tracking

### NEW: System Monitoring & Crash Detection
- **Real-time Health Monitoring** - CPU, Memory, Disk, Database connectivity
- **Automatic Crash Detection** - Detects system degradation
- **Emergency Backup on Crash** - Preserves data before failure
- **Audit Logging** - Complete action trail for compliance
- **Alert Notifications** - Email alerts on critical events
- **Health Dashboard API** - Real-time system status

### NEW: Nepal IRD 2026 Compliance
- **BS (Bikram Sambat) Date Support** - Native Nepali calendar
- **Fiscal Year Tracking** - Proper FY alignment
- **VAT Reconciliation** - Collected vs Returned
- **Credit Note Handling** - Sales returns properly tracked
- **PAN Tracking** - Customer/vendor PAN recording
- **Invoice Numbering** - Sequential as per IRD requirements

## 📊 Report Categories

### Sales Reports
| Endpoint | Description | Export |
|----------|-------------|--------|
| `GET /api/reports/ird-sales-book` | IRD Sales Book (BS dates) | Excel |
| `GET /api/reports/ird-sales-return-book` | IRD Sales Return Book | Excel |
| `GET /api/reports/materialized` | Materialized view report | JSON/Excel |
| `GET /api/reports/sales` | Filterable sales report | JSON/Excel |
| `GET /api/reports/comprehensive-sales` | Full sales with customer details | JSON/Excel |
| `GET /api/reports/sales-summary` | Sales statistics & aggregations | JSON |

### Item Reports
| Endpoint | Description | Export |
|----------|-------------|--------|
| `GET /api/reports/item-sales` | Item-wise detailed sales | JSON/Excel |
| `GET /api/reports/item-sales-summary` | Top items with profitability | JSON |

### Discount Reports
| Endpoint | Description | Export |
|----------|-------------|--------|
| `GET /api/reports/discount` | Detailed discount log | JSON/Excel |
| `GET /api/reports/discount-summary` | Discount analytics by type | JSON |

### Customer Reports
| Endpoint | Description | Export |
|----------|-------------|--------|
| `GET /api/reports/customers` | Customer analytics & history | JSON/Excel |

### Vendor Reports
| Endpoint | Description | Export |
|----------|-------------|--------|
| `GET /api/reports/vendors` | Vendor purchase summary | JSON |

### IRD Compliance
| Endpoint | Description | Export |
|----------|-------------|--------|
| `GET /api/reports/ird-daily-summary` | Daily IRD reconciliation | JSON |

### Backup & Restore
| Endpoint | Method | Description |
|----------|--------|-------------|
| `POST /api/backup/create` | POST | Create manual backup |
| `GET /api/backup/list` | GET | List available backups |
| `GET /api/backup/statistics` | GET | Backup statistics |
| `POST /api/backup/restore` | POST | Restore from backup |

### System Monitoring
| Endpoint | Method | Description |
|----------|--------|-------------|
| `GET /api/monitoring/health` | GET | Current system health |
| `GET /api/monitoring/crashes` | GET | Crash history |
| `GET /api/monitoring/audit` | GET | Audit logs |
| `GET /api/monitoring/check` | GET | Manual health check |
| `POST /api/monitoring/audit` | POST | Log custom audit entry |

## 🔧 Configuration

### appsettings.json
```json
{
  "BackupSettings": {
    "Directory": "C:\\Apps\\RestroReports\\Backups",
    "RetentionDays": 30,
    "ScheduledInterval": "24:00:00"
  },
  "MonitoringSettings": {
    "CheckIntervalSeconds": 30,
    "AlertThresholds": {
      "CPULoadPercent": 90,
      "MemoryLoadPercent": 85,
      "MinDiskSpaceGB": 1
    }
  },
  "NotificationSettings": {
    "EmailEnabled": true,
    "AdminEmail": "admin@restaurant.com",
    "NotifyOnCrash": true,
    "NotifyOnBackupFailure": true
  }
}
```

## 🛡️ Safety Features

### Data Protection
1. **Read-Only Database Access** - App never writes to production tables
2. **Encrypted Backups** - SHA-256 checksums verify integrity
3. **Auto-Verification** - Every backup verified after creation
4. **Crash-Safe Operations** - Emergency backups on detected anomalies

### Crash Detection
- Monitors CPU, Memory, Disk in real-time
- Detects database connectivity loss
- Triggers emergency backup on 3 consecutive failures
- Logs all incidents with stack traces
- Sends alerts to administrators

### Audit Trail
- Every report generation logged
- Backup/restore operations tracked
- User actions recorded with timestamps
- IP addresses and machine names captured

## 📦 Installation

Same as existing IRD-Sync deployment:

```bash
dotnet publish -c Release -r win-x64 --self-contained -o C:\Apps\RestroReports
nssm install RestroReports "C:\Apps\RestroReports\ReportingApi.exe"
nssm start RestroReports
```

Browse to `http://localhost:5080`

## 🔌 Integration Points

### Event Handlers
```csharp
// Crash detection triggers emergency backup
monitoringService.OnCrashDetected += async (sender, incident) =>
{
    await backupService.CreateEmergencyBackupAsync();
};

// Backup completion notifications
backupService.OnBackupCompleted += (sender, record) =>
{
    // Send notification, update dashboard, etc.
};
```

### Email Notifications
- Daily reports at configured time
- Crash alerts immediately
- Backup failure warnings
- IRD posting failures

## 📋 IRD Nepal 2026 Compliance Checklist

- ✅ BS Date support in all reports
- ✅ Fiscal year tracking
- ✅ VAT calculation (13%)
- ✅ Credit note handling
- ✅ PAN recording for customers
- ✅ Sequential invoice numbering
- ✅ Daily reconciliation summaries
- ✅ Audit trail for all transactions
- ✅ Backup retention (minimum 7 years recommended)

## 📞 Support

For issues or feature requests, check the comprehensive API documentation
via `GET /api/monitoring/health` for system status.
