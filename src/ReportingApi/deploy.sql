-- ============================================================
-- RestroOrder Reports - SQL Deployment Script
-- Complete deployment for 5 Core Reports:
-- 1. IRD Sales Book (usp_ro_GetSalesBook)
-- 2. IRD Sales Return Book (usp_ro_GetReturnedSalesBook)  
-- 3. Materialized View Report (usp_MaterializedReportView)
-- 4. Item Sales Report - Menu Engineering (usp_RO_ItemSalesReport)
-- 5. Cost Centre Purchase Report (usp_RO_CostCentrePurchaseReport)
-- ============================================================

-- Create indexes for optimal report performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RO_SalesMaster_InvoiceDate')
BEGIN
    CREATE INDEX IX_RO_SalesMaster_InvoiceDate ON RO_SalesMaster(InvoiceDate);
    PRINT 'Created index IX_RO_SalesMaster_InvoiceDate';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RO_SalesMaster_BillNo')
BEGIN
    CREATE INDEX IX_RO_SalesMaster_BillNo ON RO_SalesMaster(BillNo);
    PRINT 'Created index IX_RO_SalesMaster_BillNo';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RO_SalesDetail_MasterId')
BEGIN
    CREATE INDEX IX_RO_SalesDetail_MasterId ON RO_SalesDetail(SalesMasterId);
    PRINT 'Created index IX_RO_SalesDetail_MasterId';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RO_SalesMaster_PaymentMode')
BEGIN
    CREATE INDEX IX_RO_SalesMaster_PaymentMode ON RO_SalesMaster(PaymentMode);
    PRINT 'Created index IX_RO_SalesMaster_PaymentMode';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RO_SalesMaster_IsArchived')
BEGIN
    CREATE INDEX IX_RO_SalesMaster_IsArchived ON RO_SalesMaster(IsArchived) INCLUDE (NetAmount, VATAmount);
    PRINT 'Created index IX_RO_SalesMaster_IsArchived';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RO_SalesDetail_ItemId')
BEGIN
    CREATE INDEX IX_RO_SalesDetail_ItemId ON RO_SalesDetail(ItemId);
    PRINT 'Created index IX_RO_SalesDetail_ItemId';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RO_SalesDetail_CostCenterId')
BEGIN
    CREATE INDEX IX_RO_SalesDetail_CostCenterId ON RO_SalesDetail(CostCenterId);
    PRINT 'Created index IX_RO_SalesDetail_CostCenterId';
END

GO

-- ============================================================
-- Stored Procedure: usp_ro_GetSalesBook
-- Returns IRD-compliant sales book for given BS date range
-- ============================================================
IF OBJECT_ID('usp_ro_GetSalesBook', 'P') IS NOT NULL
    DROP PROCEDURE usp_ro_GetSalesBook;
GO

CREATE PROCEDURE usp_ro_GetSalesBook
    @FromDate NVARCHAR(20),  -- BS Date format: "2082.04.01"
    @ToDate NVARCHAR(20)     -- BS Date format: "2082.04.30"
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sm.InvoiceNo,
        sm.BillNo,
        sm.BillDate AS InvoiceDate,
        sm.CustomerName AS BuyerName,
        sm.CustomerPAN AS BuyerPAN,
        sm.BasicAmount AS TotalSaleValue,
        sm.DiscountAmount,
        sm.TaxableAmount,
        sm.VATAmount AS vataMount,
        sm.NetAmount AS TotalWithVAT,
        sm.PaymentMode,
        sm.IsArchived,
        sm.IsPrinted,
        sm.FiscalYear,
        'Sales' AS TransactionType
    FROM RO_SalesMaster sm
    WHERE sm.IsArchived = 0
      AND sm.BSDate BETWEEN @FromDate AND @ToDate
    ORDER BY sm.BillDate, sm.BillNo;
END
GO

-- ============================================================
-- Stored Procedure: usp_ro_GetReturnedSalesBook
-- Returns IRD-compliant sales return book for given BS date range
-- ============================================================
IF OBJECT_ID('usp_ro_GetReturnedSalesBook', 'P') IS NOT NULL
    DROP PROCEDURE usp_ro_GetReturnedSalesBook;
GO

CREATE PROCEDURE usp_ro_GetReturnedSalesBook
    @FromDate NVARCHAR(20),  -- BS Date format: "2082.04.01"
    @ToDate NVARCHAR(20)     -- BS Date format: "2082.04.30"
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sm.CreditNoteNo,
        sm.CreditNoteDate,
        sm.OriginalInvoiceNo,
        sm.OriginalInvoiceDate,
        sm.CustomerName AS BuyerName,
        sm.CustomerPAN AS BuyerPAN,
        sm.TaxableAmount AS ReturnTaxableAmount,
        sm.VATAmount AS ReturnVATAmount,
        sm.NetAmount AS TotalReturnAmount,
        sm.ReturnReason,
        sm.VoidedBy AS ApprovedBy,
        0 AS IsPostedToIRD
    FROM RO_SalesMaster sm
    WHERE sm.IsArchived = 1  -- Archived = returned/voided
      AND sm.CreditNoteDate BETWEEN @FromDate AND @ToDate
    ORDER BY sm.CreditNoteDate, sm.CreditNoteNo;
END
GO

-- ============================================================
-- Stored Procedure: usp_MaterializedReportView
-- Returns filtered sales report with payment mode analysis
-- @Valid: -1 = both, 0 = active only, 1 = archived only
-- ============================================================
IF OBJECT_ID('usp_MaterializedReportView', 'P') IS NOT NULL
    DROP PROCEDURE usp_MaterializedReportView;
GO

CREATE PROCEDURE usp_MaterializedReportView
    @StartDate DATETIME,
    @EndDate DATETIME,
    @Valid INT = -1,         -- -1 = both, 0 = active, 1 = archived
    @PaymentMode NVARCHAR(50) = ''
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sm.BillNo,
        sm.InvoiceNo,
        sm.BillDate,
        sm.CustomerName,
        sm.CustomerPAN,
        sm.BasicAmount AS TaxableAmount,
        sm.DiscountAmount,
        sm.ServiceCharge,
        sm.VATAmount AS vataMount,
        sm.NetAmount,
        sm.PaymentMode,
        sm.IsArchived,
        sm.IsPrinted,
        sm.PrintDate,
        sm.PrintCount,
        sm.FiscalYear,
        sm.AddedBy,
        sm.BSDate
    FROM RO_SalesMaster sm
    WHERE sm.BillDate BETWEEN @StartDate AND @EndDate
      AND (@Valid = -1 OR (@Valid = 0 AND sm.IsArchived = 0) OR (@Valid = 1 AND sm.IsArchived = 1))
      AND (@PaymentMode = '' OR sm.PaymentMode = @PaymentMode)
    ORDER BY sm.BillDate, sm.BillNo;
END
GO

-- ============================================================
-- Stored Procedure: usp_RO_ItemSalesReport
-- Menu Engineering Report - Top/Least/Non-Selling Items
-- Returns item-wise sales with category classification
-- Supports filtering by category (cost center) and branch
-- ============================================================
IF OBJECT_ID('usp_RO_ItemSalesReport', 'P') IS NOT NULL
    DROP PROCEDURE usp_RO_ItemSalesReport;
GO

CREATE PROCEDURE usp_RO_ItemSalesReport
    @FromDate DATETIME,
    @ToDate DATETIME,
    @Category NVARCHAR(128) = NULL,   -- Cost Center filter (Kitchen, Bar, etc.)
    @Branch NVARCHAR(128) = NULL       -- Branch filter
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ItemSales AS (
        -- Non-combo items
        SELECT
            IM.ITName AS ItemName,
            CCI.CostCenterName AS Category,
            B.BranchName AS Branch,
            SUM(SD.qty) AS QtySold,
            SUM(SD.qty * SD.rate) AS Revenue,
            AVG(SD.rate) AS AvgSellingPrice,
            MIN(CCI.CostCenterId) AS CostCenterId
        FROM RO_SalesMaster SM
        INNER JOIN RO_SalesDetail SD ON SM.salesMasterId = SD.salesMasterId
        INNER JOIN ROI_ITEMMain IM ON IM.ITId = SD.ItemId
        LEFT JOIN CostCenterInfo CCI ON CCI.CostCenterId = SD.CostCenterId
        LEFT JOIN BranchInfo B ON B.BranchId = SM.BranchId
        WHERE SD.IsCombo = 0
          AND CAST(SM.BillDate AS DATE) BETWEEN @FromDate AND @ToDate
          AND (@Category IS NULL OR CCI.CostCenterName = @Category)
          AND (@Branch IS NULL OR B.BranchName = @Branch)
        GROUP BY IM.ITName, CCI.CostCenterName, B.BranchName

        UNION ALL

        -- Combo items
        SELECT
            C.Name AS ItemName,
            CCI.CostCenterName AS Category,
            B.BranchName AS Branch,
            SUM(SD.qty) AS QtySold,
            SUM(SD.qty * SD.rate) AS Revenue,
            AVG(SD.rate) AS AvgSellingPrice,
            MIN(CCI.CostCenterId) AS CostCenterId
        FROM RO_SalesMaster SM
        INNER JOIN RO_SalesDetail SD ON SM.salesMasterId = SD.salesMasterId
        INNER JOIN RO_Combo C ON C.ComboID = SD.ItemId
        LEFT JOIN CostCenterInfo CCI ON CCI.CostCenterId = SD.CostCenterId
        LEFT JOIN BranchInfo B ON B.BranchId = SM.BranchId
        WHERE SD.IsCombo = 1
          AND CAST(SM.BillDate AS DATE) BETWEEN @FromDate AND @ToDate
          AND (@Category IS NULL OR CCI.CostCenterName = @Category)
          AND (@Branch IS NULL OR B.BranchName = @Branch)
        GROUP BY C.Name, CCI.CostCenterName, B.BranchName
    ),
    RankedItems AS (
        SELECT *,
            NTILE(3) OVER (ORDER BY QtySold DESC) AS PopularityRank
        FROM ItemSales
    )
    SELECT 
        ItemName,
        Category,
        Branch,
        QtySold,
        Revenue,
        AvgSellingPrice,
        CASE 
            WHEN PopularityRank = 1 THEN 'Top'
            WHEN PopularityRank = 2 THEN 'Low'
            ELSE 'Dead'
        END AS CategoryType,
        CASE 
            WHEN PopularityRank = 1 THEN 'Retain — high performer'
            WHEN PopularityRank = 2 THEN 'Review — consider promotion or pricing'
            ELSE 'Remove or reposition — low demand'
        END AS Recommendation
    FROM RankedItems
    ORDER BY QtySold DESC;
END
GO

-- ============================================================
-- Stored Procedure: usp_RO_CostCentrePurchaseReport
-- Purchase Report by Cost Centre (Kitchen, Bar, Bakery, etc.)
-- Returns purchase orders grouped by cost centre
-- ============================================================
IF OBJECT_ID('usp_RO_CostCentrePurchaseReport', 'P') IS NOT NULL
    DROP PROCEDURE usp_RO_CostCentrePurchaseReport;
GO

CREATE PROCEDURE usp_RO_CostCentrePurchaseReport
    @FromDate DATETIME,
    @ToDate DATETIME,
    @CostCentre NVARCHAR(128) = NULL,
    @Branch NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CAST(PO.OrderDate AS DATE) AS Date,
        PO.PONo AS InvoiceNo,
        S.SupplierName AS Supplier,
        POD.ItemDescription AS Description,
        CCI.CostCenterName AS CostCentre,
        B.BranchName AS Branch,
        POD.Qty,
        POD.Rate AS UnitRate,
        POD.Qty * POD.Rate AS TotalAmount,
        PO.Status
    FROM RO_PurchaseOrder PO
    INNER JOIN RO_PurchaseOrderDetail POD ON PO.POID = POD.POID
    INNER JOIN CostCenterInfo CCI ON CCI.CostCenterId = PO.CostCenterId
    INNER JOIN BranchInfo B ON B.BranchId = PO.BranchId
    INNER JOIN RO_Supplier S ON S.SupplierId = PO.SupplierId
    WHERE CAST(PO.OrderDate AS DATE) BETWEEN @FromDate AND @ToDate
      AND (@CostCentre IS NULL OR CCI.CostCenterName = @CostCentre)
      AND (@Branch IS NULL OR B.BranchName = @Branch)
    ORDER BY PO.OrderDate, PO.PONo;
END
GO

PRINT 'Deployment completed successfully.';
