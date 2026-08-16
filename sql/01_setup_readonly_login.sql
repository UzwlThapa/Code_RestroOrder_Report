/* ============================================================
   01_setup_readonly_login.sql  (REVISED — based on real schema
   pulled from github.com/UzwlThapa/Master_RestroOrder)
   Grants EXEC only on read-only reporting procs. No table access
   at all, so this login can never touch RestroOrder's write path,
   and can't even SELECT tables directly if a query goes wrong.
   ============================================================ */

USE master;
GO
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ro_reports_reader')
    CREATE LOGIN ro_reports_reader WITH PASSWORD = 'CHANGE_ME_STRONG_PASSWORD!';
GO

-- USE [ProdCityescapeRO_IRD];  -- <-- set per client
-- GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'ro_reports_reader')
    CREATE USER ro_reports_reader FOR LOGIN ro_reports_reader;
GO

-- Existing, already-correct procs (built by your IRD-Sync / CBMS pipeline):
GRANT EXECUTE ON dbo.usp_ro_GetSalesBook          TO ro_reports_reader;
GRANT EXECUTE ON dbo.usp_ro_GetReturnedSalesBook  TO ro_reports_reader;
GRANT EXECUTE ON dbo.usp_MaterializedReportView   TO ro_reports_reader;

-- New proc added in 02_reporting_objects.sql (item/unit/rate-wise filters):
GRANT EXECUTE ON dbo.usp_RO_Reports_FilterableSalesReport TO ro_reports_reader;

ALTER DATABASE CURRENT SET READ_COMMITTED_SNAPSHOT ON;
GO
