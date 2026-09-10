# RestroOrder Reports - Deployment Guide

## Project Summary
A lean, production-ready .NET 8 Web API focused on 3 core IRD-compliant reports for Nepal restaurants.

---

## Section 1: Files/Folders Removed (Cleanup)

### Services Deleted:
- `/src/ReportingApi/Services/EmailService.cs` - Email functionality not in scope
- `/src/ReportingApi/Services/Backup/` - Entire backup service folder removed
- `/src/ReportingApi/Services/Monitoring/` - Entire monitoring service folder removed

### Package References Removed from .csproj:
- `ClosedXML` (v0.104.1) - Excel export not needed for MVP
- `MailKit` (v4.16.0) - Email sending not in scope
- `System.IO.Packaging` (v8.0.1) - Only used by email/export features

### appsettings.json Sections Removed:
- `Smtp` - Email configuration
- `BackupSettings` - Backup configuration  
- `MonitoringSettings` - System monitoring configuration
- `NotificationSettings` - Alert/notification configuration

### Program.cs Endpoints Removed:
- All backup endpoints (`/api/backup/*`)
- All monitoring endpoints (`/api/monitoring/*`)
- Email endpoint (`/api/reports/email`)
- Export endpoints (`.export`)
- 6+ extra report endpoints (customer, vendor, discount, item sales, etc.)

---

## Section 2: Cleaned Source Files

### Program.cs (Cleaned)
```csharp
using Microsoft.Extensions.Hosting;
using ReportingApi.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Host.UseWindowsService();

// Register core services
builder.Services.AddSingleton<ReportQueries>();
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

var app = builder.Build();
app.UseCors();
app.UseDefaultFiles();
app.UseStaticFiles();

// 1. IRD Nepal Sales Book
app.MapGet("/api/reports/ird-sales-book", async (string from, string to, ReportQueries q) =>
{
    var rows = await q.GetIrdSalesBookAsync(from, to);
    return Results.Ok(rows);
});

// 2. IRD Nepal Sales Return Book
app.MapGet("/api/reports/ird-sales-return-book", async (string from, string to, ReportQueries q) =>
{
    var rows = await q.GetIrdSalesReturnBookAsync(from, to);
    return Results.Ok(rows);
});

// 3. Materialized View Report
app.MapGet("/api/reports/materialized", async (DateTime from, DateTime to, int? valid, string? paymentMode, ReportQueries q) =>
    Results.Ok(await q.GetMaterializedSalesReportAsync(from, to, valid ?? -1, paymentMode)));

app.Run();
```

### ReportQueries.cs (Verified - Contains only 3 target methods + 1 helper)
- `GetIrdSalesBookAsync()` - IRD Sales Book
- `GetIrdSalesReturnBookAsync()` - IRD Sales Return Book
- `GetMaterializedSalesReportAsync()` - Materialized View Report
- `GetFilterableSalesReportAsync()` - Helper method (can be removed if not needed)

---

## Section 3: Premium UI (wwwroot/index.html)

**Features Implemented:**
- ✅ Tailwind CSS styling (CDN)
- ✅ Chart.js for trend visualization
- ✅ Lucide Icons
- ✅ Responsive sidebar navigation for 3 reports
- ✅ BS (Bikram Sambat) date picker support for IRD reports
- ✅ AD date picker for materialized report
- ✅ Payment mode filter for materialized report
- ✅ Data grid with pagination
- ✅ Export to CSV functionality
- ✅ Print support
- ✅ Loading states and toast notifications
- ✅ Dashboard metrics cards (Total Records, Amount, VAT, Avg Bill)
- ✅ Interactive bar chart showing daily sales trends

---

## Section 4: Minimal deploy.sql Script

```sql
-- Indexes created:
- IX_RO_SalesMaster_InvoiceDate
- IX_RO_SalesMaster_BillNo
- IX_RO_SalesDetail_MasterId
- IX_RO_SalesMaster_PaymentMode
- IX_RO_SalesMaster_IsArchived

-- Stored Procedures:
1. usp_ro_GetSalesBook - IRD Sales Book (BS date range)
2. usp_ro_GetReturnedSalesBook - IRD Sales Return Book (BS date range)
3. usp_MaterializedReportView - Filtered Sales Report (AD dates, payment mode filter)
```

---

## Section 5: Final Deployment Checklist

### Step 1: Build & Publish
```bash
cd /workspace/src/ReportingApi

# Restore packages
dotnet restore

# Build Release
dotnet build --configuration Release

# Publish self-contained for Windows x64
dotnet publish --configuration Release \
  --runtime win-x64 \
  --self-contained true \
  --output ./publish
```

### Step 2: Deploy to Windows Server
```powershell
# Copy publish folder to server
xcopy /E /I /Y C:\path\to\publish C:\Apps\RestroReports\

# Navigate to deployment folder
cd C:\Apps\RestroReports
```

### Step 3: Install as Windows Service (Option A: sc.exe)
```cmd
sc create RestroReports binPath="C:\Apps\RestroReports\ReportingApi.exe" start=auto DisplayName="RestroOrder Reports Service"
sc description RestroReports "IRD Compliance Reporting System for Nepal Restaurants"
sc start RestroReports
```

### Step 3: Install as Windows Service (Option B: NSSM)
```cmd
# Download NSSM from https://nssm.cc/download
nssm install RestroReports
# In GUI: Path = C:\Apps\RestroReports\ReportingApi.exe
# Startup directory = C:\Apps\RestroReports\
nssm start RestroReports
```

### Step 4: Verify Installation
```powershell
# Check service status
sc query RestroReports

# Check if port 5080 is listening
netstat -ano | findstr :5080

# Test API endpoints
curl http://localhost:5080/api/reports/ird-sales-book?from=2082.04.01&to=2082.04.30
curl http://localhost:5080/api/reports/materialized?from=2024-01-01&to=2024-12-31

# Access UI in browser
# http://localhost:5080/
```

### Step 5: Configure Firewall (if needed)
```powershell
New-NetFirewallRule -DisplayName "RestroReports" -Direction Inbound -Protocol TCP -LocalPort 5080 -Action Allow
```

---

## Configuration Template (appsettings.json)

```json
{
  "ConnectionStrings": {
    "RestroOrderReadOnly": "Server=YOUR_SERVER;Database=YOUR_DATABASE;User Id=YOUR_USER;Password=YOUR_PASSWORD;TrustServerCertificate=True;"
  },
  "Kestrel": {
    "Endpoints": {
      "Http": { "Url": "http://0.0.0.0:5080" }
    }
  },
  "Logging": {
    "LogLevel": { 
      "Default": "Information",
      "Microsoft": "Warning",
      "System": "Warning"
    }
  }
}
```

---

## API Endpoints Reference

| Endpoint | Method | Parameters | Description |
|----------|--------|------------|-------------|
| `/api/reports/ird-sales-book` | GET | from (BS), to (BS) | IRD Sales Book |
| `/api/reports/ird-sales-return-book` | GET | from (BS), to (BS) | IRD Sales Return Book |
| `/api/reports/materialized` | GET | from (AD), to (AD), valid, paymentMode | Filtered Sales Report |
| `/` | GET | - | Premium Dashboard UI |

---

## Support

For issues or questions about this deployment, contact your DevOps team.
