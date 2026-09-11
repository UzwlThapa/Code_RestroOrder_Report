# RestroOrder Reports

Separate reporting app for RestroOrder POS — reads the same SQL Server database
in **read-only** mode so billing stays untouched.

## Project layout

```
Code_RestroOrder_Report/
├── ui/                      # Next.js dashboard (Rocket AI UI)
├── RestroOrder.ReportsApi/  # .NET 8 read-only API
└── sql/                     # DB setup scripts (readonly login + procs)
```

## Quick start

### 1. Database (one-time)

Run in SSMS against the RestroOrder database:

- `sql/01_setup_readonly_login.sql`
- `sql/02_reporting_objects.sql`
- `sql/03_supporting_indexes.sql`

### 2. API

```bash
cd RestroOrder.ReportsApi
dotnet run
```

Health check: http://localhost:5080/health  
Cost Centre report: `GET /api/reports/cost-centre?fromDate=2026-09-01&toDate=2026-09-10`

See [RestroOrder.ReportsApi/README.md](RestroOrder.ReportsApi/README.md) for IIS deployment.

### 3. UI

```bash
cd ui
npm install
npm run dev
```

Open http://localhost:3000

## Current status

| Report            | UI | API |
|-------------------|----|-----|
| Cost Centre       | ✅ | ✅  |
| IRD Sales Book    | ✅ (sample data) | ❌ |
| Menu Engineering  | ✅ (sample data) | ❌ |

Next step: wire the UI to the API and add the remaining report endpoints.
