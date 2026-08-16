/* ============================================================
   02_reporting_objects.sql
   Only ONE new object needed. Everything else (IRD Sales Book,
   IRD Sales Return Book, materialized sales report) already
   exists and is correct — see README for how the API calls them
   directly with EXEC, no wrapping SQL required.

   This proc extends the logic already proven in
   USP_RO_ITEMSALESREPORT / usp_ro_dailyItemSalesForMail with the
   filters you asked for (item, unit, rate range, cost center,
   table, payment mode) that neither existing proc takes.

   CONFIRMED from the real repo (not guessed):
   - RO_SalesDetail.ItemId -> ROI_ITEMMain.ITId (NOT RO_Items —
     that catalog is used at order/KOT time, not billing time)
   - "Category" in every existing report = Cost Center
     (CostCenterInfo), not RO_Categories
   - Unit comes from ROI_ItemDetails.SmallUnit -> ROI_Unit1.Symbol
   - Combo items are a separate union branch against RO_Combo
   ============================================================ */

-- USE [ProdCityescapeRO_IRD];  -- <-- set per client
-- GO

CREATE OR ALTER PROCEDURE dbo.usp_RO_Reports_FilterableSalesReport
    @From        DATE,
    @To          DATE,
    @Item        NVARCHAR(128) = NULL,
    @CostCenter  NVARCHAR(128) = NULL,
    @Unit        NVARCHAR(50)  = NULL,
    @RateMin     DECIMAL(18,2) = NULL,
    @RateMax     DECIMAL(18,2) = NULL,
    @Table       NVARCHAR(50)  = NULL,
    @PaymentMode NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Lines AS (
        -- Non-combo items
        SELECT
            CAST(SM.BillDate AS DATE) AS BillDate,
            SM.billNo,
            SM.TableId,
            CCI.CostCenterName        AS Category,
            IM.ITName                 AS ItemName,
            SD.qty                    AS Qty,
            SD.rate                   AS Rate,
            SD.qty * SD.rate          AS NetAmount,
            U.Symbol                  AS Unit,
            SM.salesMasterId
        FROM RO_SalesMaster SM
        INNER JOIN RO_SalesDetail SD ON SM.salesMasterId = SD.salesMasterId
        INNER JOIN ROI_ITEMMain IM   ON IM.ITId = SD.ItemId
        LEFT JOIN CostCenterInfo CCI ON CCI.CostCenterId = SD.CostCenterId
        LEFT JOIN ROI_ItemDetails ID ON ID.ITId = IM.ITId
        LEFT JOIN ROI_Unit1 U        ON U.Unit1Id = ID.SmallUnit
        WHERE SD.IsCombo = 0
          AND CAST(SM.BillDate AS DATE) BETWEEN @From AND @To

        UNION ALL

        -- Combo items
        SELECT
            CAST(SM.BillDate AS DATE) AS BillDate,
            SM.billNo,
            SM.TableId,
            CCI.CostCenterName        AS Category,
            C.Name                    AS ItemName,
            SD.qty                    AS Qty,
            SD.rate                   AS Rate,
            SD.qty * SD.rate          AS NetAmount,
            'Pack'                    AS Unit,
            SM.salesMasterId
        FROM RO_SalesMaster SM
        INNER JOIN RO_SalesDetail SD ON SM.salesMasterId = SD.salesMasterId
        INNER JOIN RO_Combo C        ON C.ComboID = SD.ItemId
        LEFT JOIN CostCenterInfo CCI ON CCI.CostCenterId = SD.CostCenterId
        WHERE SD.IsCombo = 1
          AND CAST(SM.BillDate AS DATE) BETWEEN @From AND @To
    )
    SELECT L.*,
           pm.PaymentMode
    FROM Lines L
    LEFT JOIN RO_SalesPaymentMode spm ON spm.salesMasterId = L.salesMasterId
    LEFT JOIN RO_PaymentModes pm      ON pm.PaymentModeID = spm.PaymentModeID
    WHERE (@Item IS NULL OR L.ItemName LIKE '%' + @Item + '%')
      AND (@CostCenter IS NULL OR L.Category = @CostCenter)
      AND (@Unit IS NULL OR L.Unit = @Unit)
      AND (@RateMin IS NULL OR L.Rate >= @RateMin)
      AND (@RateMax IS NULL OR L.Rate <= @RateMax)
      AND (@Table IS NULL OR L.TableId = @Table)
      AND (@PaymentMode IS NULL OR pm.PaymentMode = @PaymentMode)
    ORDER BY L.BillDate, L.billNo;
END
GO
