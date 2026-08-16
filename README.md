# RestroOrder Reports

Standalone reporting app — reads via a read-only SQL login that can only
EXEC specific reporting stored procedures, so it can never write to or
lock RestroOrder's live tables, at any date range, at any time.

## What's actually new here vs. what already existed

Pulled the real schema and stored procedures from
github.com/UzwlThapa/Master_RestroOrder before writing anything. Result:

- **IRD Sales Book** — already exists (`usp_ro_GetSalesBook`, reads
  `CBMS_BillPostLog`, populated by your IRD-Sync service). Not rebuilt —
  just wrapped and exported to Excel.
- **IRD Sales Return Book** — already exists (`usp_ro_GetReturnedSalesBook`,
  reads `CBMS_BillReturnPostLog`). Same — wrapped, not rebuilt.
- **"Materialized view" sales report** — already exists
  (`usp_MaterializedReportView`): bill no, customer, PAN, taxable amount,
  discount, service charge, VAT, payment modes, print status. Wrapped.
- **Filterable sales report (item/unit/rate/cost-center/table/payment
  mode wise)** — this one's genuinely new:
  `sql/02_reporting_objects.sql` → `usp_RO_Reports_FilterableSalesReport`.
  Built on the exact join pattern already proven in your own
  `USP_RO_ITEMSALESREPORT` and `usp_ro_dailyItemSalesForMail` procs
  (`RO_SalesDetail.ItemId → ROI_ITEMMain`, not `RO_Items` — that catalog
  is for order/KOT time, not billing time), extended with the filters
  neither existing proc takes.

## Important things confirmed from the real schema (not guessed)

- `usp_ro_GetSalesBook` / `usp_ro_GetReturnedSalesBook` take **BS
  (Bikram Sambat) calendar date strings**, dot-separated
  (e.g. `2082.04.01`), not AD dates — they do a string `BETWEEN` on
  `invoice_date`/`credit_note_date`. Pass whatever format the rest of
  RestroOrder already uses for this proc.
- "Category" everywhere in existing reports means **Cost Center**
  (`CostCenterInfo`), not the menu `RO_Categories` table.
- Combo items are billed through `RO_Combo`, a separate branch from
  regular items — both are unioned in the new proc, same as the
  existing ones.

## Still open (genuinely missing from the schema, not something I can fabricate)

The original Tally Export spec (delivered earlier as a separate
skeleton) asked for Transaction Status types beyond Paid/Cancelled —
Complimentary/FOC, Staff Use, Owner Use, Promotion, Wastage — and
Approved By / Reason fields, and a liquor/beer ML pack-size conversion.
None of these exist in the current schema (`RO_OrderMasters`,
`RO_SalesMaster`, `RO_Items`, `ROI_ITEMMain`). `RO_ComplementaryItems`
exists as a separate table for complimentary items specifically, which
is a start, but a full status taxonomy isn't there yet. That's a
billing/void-UI change, not a reporting one — flagging it rather than
inventing data that doesn't exist.

## One-command deployment (auto-detects RestroOrder's DB credentials)

Copy this whole `tally-reports` folder onto the SAME server as
RestroOrder, then either:

- **Double-click** `installer\install.bat` (auto-requests admin), or
- Run in an elevated PowerShell: `.\installer\install.ps1`

What it does automatically, with zero typing in the common case:

1. Finds RestroOrder's own `SageFrame\connectionstring.config` (or
   `web.config`) on disk and reads the real Server/Database/User/Password
   straight out of it — this is literally how RestroOrder itself connects,
   so there's nothing to misconfigure.
2. If it can't find that file, it prompts for Server / Database, and
   for username/password with `sa` / `saa` as the default — matching
   RestroOrder's own standing default across your client installs
   (confirmed from the real configs in your repo).
3. Uses those (admin) credentials ONE TIME to create a dedicated
   low-privilege `ro_reports_reader` SQL login with a freshly
   generated random password — the app itself never runs as `sa`.
4. Publishes the API, writes `appsettings.json`, installs it as a
   Windows Service via NSSM (same tool you already use for IRD-Sync),
   starts it, and opens the report UI in your browser.

**Prerequisites on the target server** (same as what IRD-Sync already
needs, so if that's running here, most of this is already true):
- .NET 8 SDK (for `dotnet publish` during install — the runtime alone
  isn't enough for the publish step)
- `sqlcmd` (ships with SQL Server / SQL Server tools, usually already
  present next to your SQL Server install)
- `nssm.exe` on PATH (same as your IRD-Sync setup — if missing, the
  installer tells you and gives you the two commands to run once
  it's installed)

To deploy the same package to a different client server, just re-run
the installer there — it re-detects that server's own RestroOrder
config and database automatically, no per-client editing needed.

## Deploy (same pattern as IRD-Sync)


```bash
dotnet publish -c Release -r win-x64 --self-contained -o C:\Apps\RestroReports
nssm install RestroReports "C:\Apps\RestroReports\ReportingApi.exe"
nssm start RestroReports
```

Browse to `http://localhost:5080` (or the client's LAN IP) — UI is
served straight from `wwwroot/`, no separate build/deploy step.

## Endpoints

| Purpose | Route |
|---|---|
| IRD Sales Book (.xlsx) | `GET /api/reports/ird-sales-book?from=<BS date>&to=<BS date>` |
| IRD Sales Return Book (.xlsx) | `GET /api/reports/ird-sales-return-book?from=<BS date>&to=<BS date>` |
| Materialized report (JSON) | `GET /api/reports/materialized?from=&to=&valid=&paymentMode=` |
| Materialized report (.xlsx) | `GET /api/reports/materialized/export?...` |
| Filterable sales report (JSON) | `GET /api/reports/sales?from=&to=&item=&costCenter=&unit=&rateMin=&rateMax=&table=&paymentMode=` |
| Filterable sales report (.xlsx) | `GET /api/reports/sales/export?...` |
| Email any report to owner | `POST /api/reports/email` `{ reportType, toEmail, from, to, fromBS, toBS, item, costCenter, unit, table, paymentMode }` |
