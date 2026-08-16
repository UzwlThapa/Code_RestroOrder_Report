/* ============================================================
   03_supporting_indexes.sql  (REVISED — real table names)
   Keeps any date-range query fast against the actual billing
   tables (RO_SalesMaster/RO_SalesDetail), not the guessed ones.
   ============================================================ */

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RO_SalesMaster_BillDate_Reports')
    CREATE NONCLUSTERED INDEX IX_RO_SalesMaster_BillDate_Reports
    ON RO_SalesMaster (BillDate)
    INCLUDE (billNo, TableId, CusName, BasicAmount, NetAmount, totaldiscount,
             FiscalYearID, InvoiceNo, PrintDate, PrintCount, IsArchived, Reasons, AddedBy);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_RO_SalesDetail_salesMasterId_Reports')
    CREATE NONCLUSTERED INDEX IX_RO_SalesDetail_salesMasterId_Reports
    ON RO_SalesDetail (salesMasterId)
    INCLUDE (ItemId, qty, rate, Amount, CostCenterId, IsCombo);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CBMS_BillPostLog_InvoiceDate')
    CREATE NONCLUSTERED INDEX IX_CBMS_BillPostLog_InvoiceDate
    ON CBMS_BillPostLog (invoice_date);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CBMS_BillReturnPostLog_CreditNoteDate')
    CREATE NONCLUSTERED INDEX IX_CBMS_BillReturnPostLog_CreditNoteDate
    ON CBMS_BillReturnPostLog (credit_note_date);

-- Note: invoice_date / credit_note_date are NVARCHAR (BS calendar strings,
-- e.g. '2082.04.01'), filtered with a string BETWEEN in the existing procs.
-- A plain nonclustered index still helps this since it's a sargable
-- range predicate on a consistently-formatted zero-padded string.
