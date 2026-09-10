# RestroOrder.ReportsApi

Read-only reporting API, decoupled from the POS/SageFrame app pool so it can't
touch billing. Backs the recovered Next.js UI (3 reports: IRD Sales,
Menu Engineering, Cost Centre). Only Cost Centre is wired to real tables today.

## 📌 OS / .NET version notes
- Targets **.NET 8 LTS** (supported through Nov 2026). Needs the
  **ASP.NET Core Hosting Bundle** on the server (installs the module that
  lets IIS proxy to Kestrel).
- **Minimum OS: Windows Server 2012 R2 SP1** (with latest servicing) or
  **Windows 10 1607+**. .NET 8 does **not** run on Server 2008 R2 or
  Windows 7 — if any client machine is still 2008 R2, this API cannot be
  hosted there; it would need to run centrally and be reached over LAN, or
  fall back to .NET Framework 4.8 + a Web API 2 rewrite (ask if that's a
  hard requirement — different codebase, not a config change).
- SQL query in `CostCentreRepository.cs` avoids `STRING_AGG`/`TRIM` — safe
  back to SQL Server **2008 R2**.

## 🔧 One-time server setup (PowerShell, run elevated)

```powershell
# 1. Install ASP.NET Core Hosting Bundle first (download offline installer
#    on air-gapped boxes - https://dotnet.microsoft.com/download/dotnet/8.0
#    -> "Hosting Bundle", copy the .exe over, no internet needed on target)

# 2. Create the site + app pool
Import-Module WebAdministration
New-WebAppPool -Name "RestroOrderReportsApiPool"
Set-ItemProperty IIS:\AppPools\RestroOrderReportsApiPool -Name managedRuntimeVersion -Value ""   # No Managed Code - Kestrel handles it
Set-ItemProperty IIS:\AppPools\RestroOrderReportsApiPool -Name processModel.identity -Value ApplicationPoolIdentity

New-WebSite -Name "RestroOrderReportsApi" `
  -PhysicalPath "C:\inetpub\wwwroot\RestroOrderReportsApi" `
  -ApplicationPool "RestroOrderReportsApiPool" `
  -Port 5080

# 3. Event Log source (Program.cs logging depends on this existing first)
New-EventLog -LogName Application -Source "RestroOrder.ReportsApi"

# 4. Firewall - open the port to LAN only, not public
New-NetFirewallRule -DisplayName "RestroOrder Reports API" -Direction Inbound `
  -LocalPort 5080 -Protocol TCP -Action Allow -Profile Domain,Private

# 5. Grant the app pool identity read access on the SQL login (run in SSMS,
#    Windows Auth / Integrated Security=SSPI relies on this):
#    CREATE LOGIN [DOMAIN\RestroOrderReportsApiPool] FROM WINDOWS;  -- or IIS APPPOOL\RestroOrderReportsApiPool
#    USE RestroOrderDb; CREATE USER [...] FOR LOGIN [...]; EXEC sp_addrolemember 'db_datareader', '...';
```

## ⚠️ Config secrets (no `aspnet_regiis` here — that's Web Forms/.NET Framework only)
ASP.NET Core doesn't use protected `web.config` sections. On-prem options,
cheapest first:
1. Keep `Integrated Security=SSPI` (current setup) — no password in config at
   all, this is the actual best option for a domain-joined on-prem box.
2. If a SQL login *must* be used instead of Windows Auth, set it via an
   environment variable on the App Pool (`ConnectionStrings__RestroOrderDb`)
   rather than in `appsettings.json`, so it's not sitting in plaintext on disk
   inside source control or the deployed folder.

## 📦 Zero-downtime deploy (single server, matches the Web Forms pattern you're
already using elsewhere)

```powershell
$site = "C:\inetpub\wwwroot\RestroOrderReportsApi"
$new  = "$site`_new"
$old  = "$site`_old"

# publish to $new beforehand (dotnet publish -c Release -o $new)
Stop-WebAppPool -Name "RestroOrderReportsApiPool"
if (Test-Path $old) { Remove-Item $old -Recurse -Force }
Rename-Item $site $old
Rename-Item $new $site
Start-WebAppPool -Name "RestroOrderReportsApiPool"

Start-Sleep -Seconds 3
$health = Invoke-RestMethod -Uri "http://localhost:5080/health" -TimeoutSec 10
if ($health.status -ne "ok") {
    Write-Warning "Health check failed - rolling back"
    Stop-WebAppPool -Name "RestroOrderReportsApiPool"
    Rename-Item $site "$site`_failed"
    Rename-Item $old $site
    Start-WebAppPool -Name "RestroOrderReportsApiPool"
}
```

## 🧪 Test steps
- Unit: mock `IConfiguration` to feed `CostCentreRepository` a LocalDB/test
  connection string; assert the `IN @CostCentres` empty-list guard doesn't
  throw (Dapper throws on `IN ()` with zero elements — covered by
  `HasCostCentreFilter`).
- Integration: hit `GET /api/reports/cost-centre?fromDate=...&toDate=...`
  against a restored copy of the DB, diff row count against the raw SQL run
  directly in SSMS.
- Manual: pull the network cable to SQL mid-request, confirm the controller
  returns 500 with the generic message (not a stack trace / connection string
  leak) and that Event Viewer > Application has the real exception.
- Chaos: recycle the app pool mid-request from the Next.js UI, confirm the
  UI's loading skeleton doesn't hang forever (check `ReportLoadingSkeleton.tsx`
  has a timeout/retry — it currently doesn't call any API at all yet, so this
  needs to be added when you wire the `fetch()` calls in).

## Still blocked
- `Branch`/`Status` columns on `RO_GoodsReceivedMain` are **unconfirmed** —
  not in anything you've shared. Run:
  `SELECT name FROM sys.columns WHERE object_id = OBJECT_ID('RO_GoodsReceivedMain');`
  and send the list before trusting this in production.
- IRD Sales Book and Menu Engineering reports have no backend yet — need the
  sales/invoice/bill tables (never sent). Same schema-dump script from
  earlier in this thread works on whatever tables those turn out to be.
