SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
--sp_helptext usp_ro_itemsalesreport '2017-09-01 00:00','2017-09-16 24:00'
CREATE PROCEDURE [dbo].[USP_RO_ITEMSALESREPORT]

@Start datetime,
@End Datetime
 --@Start DATETIME = '2017-01-02', @End DATETIME  = '2017-01-31'
AS
BEGIN

SELECT 
 CAST(SM.BillDate as date) as BillDate
,CCI.CostCenterName
,IM.ITName
,sum(sd.qty) as QTY 
,sd.rate
--,sum(sd.Amount)  Amount
,sum(sd.qty * sd.rate) NetAmount
,SD.IsCombo 
,ru.Symbol as ITUnit
FROM RO_SalesMaster SM
INNER JOIN RO_SalesDetail SD ON SM.salesMasterId = SD.salesMasterId
INNER JOIN ROI_ITEMMain Im ON IM.ITId = SD.ItemId 
left join CostCenterInfo CCI on CCI.CostCenterId = sd.CostCenterId
left join ROI_ItemDetails itd on Im.ITId=itd.ITId
left join ROI_Unit1 ru on ru.Unit1Id=itd.SmallUnit

WHERE IsCombo = 0 
AND (cast(SM.BillDate as Date) BETWEEN @Start AND @End)
--AND (SM.BillDate >= @Start AND SM.BillDate <= @End)
GROUP BY  CAST(SM.BillDate as date),CCI.CostCenterName ,IM.ITName,sd.rate,SD.IsCombo,ru.Symbol
 union 
 SELECT  
 CAST(SM.BillDate as date) as BillDate
,CCI.CostCenterName
 ,IM.Name
,sum(sd.qty) as QTY 
,sd.rate
--,sum(sd.Amount)  Amount
,sum(sd.qty * sd.rate) NetAmount
,SD.IsCombo 
,'Pack' as ITUnit
FROM RO_SalesMaster SM
INNER JOIN RO_SalesDetail SD ON SM.salesMasterId = SD.salesMasterId
INNER JOIN RO_Combo Im ON IM.ComboID = SD.ItemId 
left join CostCenterInfo CCI on CCI.CostCenterId = sd.CostCenterId
WHERE IsCombo = 1 
AND (CAST(SM.BillDate as date) BETWEEN @Start AND @End)
--AND (SM.BillDate >= @Start AND SM.BillDate <= @End)
GROUP BY CAST(SM.BillDate as date),CCI.CostCenterName , IM.Name,sd.rate,SD.IsCombo 

END


GO



SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
-- USP_SALES_REPORT fix: include fully-advance-paid room bills (PaymentModeID = 0)
-- Deploy to ALL client databases

CREATE PROCEDURE [dbo].[USP_SALES_REPORT]
    @startDate DATETIME = '2026-05-07',
    @endDate DATETIME = '2026-05-07',
    @PaymentMode NVARCHAR(20) = N'',
    @Status INT = -1,
    @OrdertypeID INT = 0,
    @CustName VARCHAR(50) = ''
AS
BEGIN
    DECLARE @StartDateTime DATETIME;
    DECLARE @EndDateTime DATETIME;
    SELECT @StartDateTime = DATEADD(HOUR, 4, @startDate);
    SELECT @EndDateTime = DATEADD(HOUR, 4, @endDate);

    DECLARE @code VARCHAR(10);
    SET @code =
    (
        SELECT TOP (1) Code FROM RO_CompanyInfo
    );

    DECLARE @tempSales AS TABLE
    (
        salesMasterId INT,
        CustomerName VARCHAR(200)
    );

    INSERT INTO @tempSales
    SELECT sm.salesMasterId,
           CASE
               WHEN ISNULL(spm.Customer, '') = '' THEN
                   sm.CusName
               ELSE
                   spm.Customer
           END AS CustomerName
    FROM RO_SalesMaster sm
        LEFT JOIN RO_SalesPaymentMode spm
            ON sm.salesMasterId = spm.salesMasterId
    WHERE (sm.BillDate
          BETWEEN @StartDateTime AND @EndDateTime
          )
          AND
          (
              spm.PaymentModeID >= 0 -- CHANGED: was > 0, now includes PaymentModeID = 0
              -- for fully-advance-paid room bills (NetAmount = 0)
              OR spm.PaymentModeID IS NULL
          )
    GROUP BY sm.salesMasterId,
             CASE
                 WHEN ISNULL(spm.Customer, '') = '' THEN
                     sm.CusName
                 ELSE
                     spm.Customer
             END;

    -- rest of proc unchanged below this point
    SELECT salesMasterId
    INTO #temp
    FROM dbo.RO_SalesMaster sm
    WHERE sm.BillDate
          BETWEEN @StartDateTime AND @EndDateTime
          AND
          (
              @Status = -1
              OR sm.IsUpdated = @Status
          );

    SELECT sm.OrderMasterId,
           sm.salesMasterId,
           CAST(CONVERT(VARCHAR(16), sm.BillDate, 20) AS VARCHAR(120)) AS BillDate,
           @code + fy.fyName + '-' + CAST((sm.InvoiceNo - fy.FirstSalesMasterID) AS VARCHAR(20)) AS billNo,
           sm.Waiter,
           sm.TableId,
           CASE
               WHEN om.OrderTypeID = 4 THEN
                   'Food Delivery'
               WHEN om.OrderTypeID = 3 THEN
                   'Food Court'
           END AS restrotableTitle,
           CASE
               WHEN om.OrderTypeID = 4 THEN
                   'Food Delivery'
               WHEN om.OrderTypeID = 3 THEN
                   'Food Court'
           END AS restroRoom,
           sm.BasicAmount + sm.totaldiscount AS SubTotal,
           sm.totaldiscount,
           sm.BasicAmount AS BasicAmount,
           sm.NetAmount,
           ISNULL(sm.PrintCount, 0) AS PrintCount,
           sm.IsUpdated AS [Status],
           (CASE
                WHEN ISNULL(sm.IsUpdated, 0) = 1
                     AND ISNULL(sm.AdvancePayment, 0) < sm.NetAmount THEN
           (ISNULL(SUM(spm.PayAmount), 0) + ISNULL(sm.AdvancePayment, 0) - sm.NetAmount
            - ISNULL(SUM(spm.ReturnPayment), 0)
           )
                WHEN ISNULL(sm.IsUpdated, 0) = 1
                     AND ISNULL(sm.AdvancePayment, 0) > sm.NetAmount THEN
                    0
                ELSE
                    0
            END
           ) AS SurplusDeficit,
           ISNULL(spm.ReturnPayment, 0) AS ReturnPayment,
           '' AS SalesType,
           ts.CustomerName AS CustomerName,
           om.GuestNo,
           sm.BillCancelled,
           sm.IsArchived
    INTO #temp2
    FROM #temp tmp
        INNER JOIN dbo.RO_SalesMaster sm
            ON sm.salesMasterId = tmp.salesMasterId
        INNER JOIN @tempSales ts
            ON ts.salesMasterId = sm.salesMasterId
        INNER JOIN RO_OrderMasters om
            ON sm.OrderMasterId = om.OrderMasterID
        INNER JOIN CBMS_BillPostLog bp
            ON bp.SalesMasterId = sm.salesMasterId
        INNER JOIN RO_fiscalYear fy
            ON fy.fyId = sm.FiscalYearID
        LEFT JOIN RO_SalesPaymentMode spm
            ON spm.salesMasterId = sm.salesMasterId
    WHERE (
              ISNULL(om.OrderTypeID, 1) = @OrdertypeID
              OR @OrdertypeID = 0
          )
    GROUP BY sm.OrderMasterId,
             sm.salesMasterId,
             sm.Waiter,
             sm.TableId,
             fy.fyName,
             sm.InvoiceNo,
             fy.FirstSalesMasterID,
             sm.totaldiscount,
             sm.BasicAmount,
             sm.BillDate,
             sm.AdvancePayment,
             sm.NetAmount,
             sm.PrintCount,
             sm.IsUpdated,
             om.OrderTypeID,
             spm.ReturnPayment,
             ts.CustomerName,
             om.GuestNo,
             sm.BillCancelled,
             sm.IsArchived;

    SELECT OrderMasterId,
           sm.salesMasterId,
           BillDate,
           billNo,
           Waiter,
           TableId,
           CASE
               WHEN rt.restrotableTitle IS NULL THEN
                   ISNULL(sm.restrotableTitle, 'Take Away')
               ELSE
                   ''
           END AS restrotableTitle,
           ISNULL(sm.restroRoom, rt.restrotableTitle) AS restroRoom,
           SubTotal,
           totaldiscount,
           BasicAmount,
           ISNULL(b1.Amount, 0) AS ServiceCharge,
           ISNULL(b2.Amount, 0) AS Vat,
           NetAmount,
           PrintCount,
           ufn.PaymentModes,
           Status,
           ufn.PaidAmount AS ReceivedAmount,
           SurplusDeficit,
           ReturnPayment,
           SalesType,
           CustomerName,
           GuestNo,
           sm.BillCancelled,
           sm.IsArchived
    INTO #temp3
    FROM #temp2 sm
        CROSS APPLY [dbo].[ufn_sales_getpaymentdata](sm.salesMasterId, @PaymentMode) ufn
        LEFT JOIN RO_BillingAmount b1
            ON b1.SalesMasterID = sm.salesMasterId
               AND b1.BilingID = 62
        LEFT JOIN RO_BillingAmount b2
            ON b2.SalesMasterID = sm.salesMasterId
               AND b2.BilingID = 54
        LEFT JOIN dbo.RO_restroTable rt
            ON rt.restrotableId = sm.TableId
        LEFT JOIN RO_RestroRoom rr
            ON rr.restroRoomId = rt.restroRoomId
    UNION
    SELECT t2.OrderMasterId,
           t2.SalesMasterId,
           t2.BillDate,
           t2.billNo,
           t2.Waiter,
           t2.TableId,
           t2.restrotableTitle,
           t2.restroRoom,
           t2.SubTotal,
           t2.TotalDiscount,
           t2.BasicAmount,
           t2.ServiceCharge,
           t2.Vat,
           t2.NetAmount,
           t2.PrintCount,
           t2.PaymentModes,
           t2.Status,
           t2.ReceivedAmount,
           t2.SurplusDeficit,
           t2.ReturnPayment,
           t2.SalesType,
           t2.CustomerName,
           t2.GuestNo,
           0,
           t2.IsArchived
    FROM [dbo].[vw_CakeSalesReport] t2
    WHERE t2.BillDate
          BETWEEN @StartDateTime AND @EndDateTime
          AND
          (
              (t2.SalesType = CASE @OrdertypeID
                                  WHEN 6 THEN
                                      'cake'
                                  WHEN 7 THEN
                                      'wholesale'
                                  WHEN 8 THEN
                                      'retail'
                              END
              )
              OR @OrdertypeID = 0
          );

    DECLARE @CDate DATETIME = ISNULL(
                              (
                                  SELECT TOP (1)
                                         ClosedTS
                                  FROM [dbo].[DailyFinancialReport]
                                  WHERE IsClosed = 1
                                  ORDER BY FinancialID DESC
                              ),
                              GETDATE() - 100
                                    );

    SELECT *,
           (CASE
                WHEN (CAST(t.BillDate AS DATETIME) >= CAST(@CDate AS DATETIME)) THEN
                    1
                ELSE
                    0
            END
           ) AS EditBill
    FROM #temp3 t
    WHERE t.CustomerName LIKE '%' + @CustName + '%'
          AND
          (
              @PaymentMode = ''
              OR t.PaymentModes LIKE '%' + @PaymentMode + '%'
          )
    ORDER BY t.BillDate ASC;

    DROP TABLE #temp;
    DROP TABLE #temp2;
    DROP TABLE #temp3;
END;
GO


SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[Usp_getPurchaseReport] -- NULL, NULL, 0, ''

    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @VendorID INT = 0,
    @puNo VARCHAR(250) = NULL
AS


if(isnull(@StartDate,''))='' set @StartDate = '2000-01-01' 
if(isnull(@EndDate,''))='' set @EndDate = GETDATE() 

SELECT pm.PurchaseMainID,
       fy.fyName,
       pm.PuNo,
       lm.Fname AS VenderName,
       lm.[Address],
       FORMAT(pm.PbDate, 'yyyy-MM-dd') AS BillDate,
       pm.PostedOn AS PostedOn,
       pm.PostedBy,
       SUM(pd.Total) AS Amount,
       ISNULL(lm.IsVat, 0) IsVat
FROM ROI_PurchaseMain pm
    INNER JOIN ROI_PurchaseDetails pd
        ON pm.PurchaseMainID = pd.PurchaseMainID
    --LEFT JOIN ROI_PurchaseLotNo pln ON pln.PurchaseDetailsID = pd.PurchaseDetailsID
    LEFT JOIN ROI_ITEMMain im
        ON im.ITId = pd.ItemID
    LEFT JOIN ROI_Unit1 u1
        ON u1.Unit1Id = pd.UsedUnitID
    LEFT JOIN RO_LoyaltyMembership lm
        ON lm.MembershipID = pm.Vid
    LEFT JOIN RO_fiscalYear fy
        ON fy.fyId = pm.FyId
WHERE cast(pm.PbDate as date) between cast(@startdate as date) and cast(@enddate as date)
      --(
      --    CAST(pm.PostedOn AS DATE) >= @StartDate
      --    OR @StartDate = 0
      --    OR @StartDate IS NULL
      --    OR @StartDate = ''
      --)
      --AND
      --(
      --    CAST(pm.PostedOn AS DATE) <= @EndDate
      --    OR @EndDate = 0
      --    OR @EndDate IS NULL
      --    OR @EndDate = ''
      --)
      AND
      (
          pm.Vid = @VendorID
          OR @VendorID = 0
      )
      AND
      (
          pm.PuNo = @puNo
          OR @puNo = ''
          OR @puNo IS NULL
      )
GROUP BY pm.PurchaseMainID,
         fy.fyName,
         pm.PuNo,
         lm.Fname,
         lm.[Address],
         pm.PbDate,
         pm.PostedBy,
         pm.PostedOn,
         lm.IsVat
ORDER BY pm.PurchaseMainID DESC;

GO

SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[usp_ro_GetSalesBook]
    @FromDate NVARCHAR(256),
    @ToDate NVARCHAR(256)
AS
SELECT cbpl.LogID,
       cbpl.seller_pan,
       cbpl.buyer_pan,
       cbpl.fiscal_year,
       CASE
           WHEN NULLIF(RTRIM(LTRIM(cbpl.buyer_name)), '') IS NULL THEN
               -- Concatenate all payment modes with comma separator
               STUFF((
                   SELECT ', ' + 
                       CASE
                           WHEN LOWER(pm2.PaymentMode) = 'credit' THEN
                               pm2.PaymentMode + '/' + ISNULL(spm2.Customer, '')
                           ELSE
                               pm2.PaymentMode
                       END
                   FROM dbo.RO_SalesPaymentMode spm2
                   INNER JOIN dbo.RO_PaymentModes pm2
                       ON pm2.PaymentModeID = spm2.PaymentModeID
                   WHERE spm2.salesMasterId = cbpl.SalesMasterId
                   FOR XML PATH('')
               ), 1, 2, '')  -- Removes first 2 chars: ', '
           ELSE
               cbpl.buyer_name
       END AS buyer_name,
       cbpl.invoice_number,
       cbpl.invoice_date,
       cbpl.total_sales,
       cbpl.taxable_sales_vat,
       cbpl.vat,
       cbpl.excisable_amount,
       cbpl.excise,
       cbpl.taxable_sales_hst,
       cbpl.hst,
       cbpl.amount_for_esf,
       cbpl.esf,
       cbpl.export_sales,
       cbpl.tax_exempted_sales,
       cbpl.isrealtime,
       cbpl.datetimeClient,
       cbpl.BillPostDateTime,
       cbpl.StatusCode,
       cbpl.StatusDetails,
       cbpl.SalesMasterId,
       cbpl.EnglishInvDate,
       cbpl.SalesType,
       ISNULL([dbo].[ufn_getsalesbillquantity](cbpl.SalesMasterId), 0) AS Qty
FROM CBMS_BillPostLog cbpl
WHERE invoice_date BETWEEN REPLACE(@FromDate, '-', '.') AND REPLACE(@ToDate, '-', '.');
GO


SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO

--USP_PurchaseBook  '2023/09/01','2023/09/01'
CREATE PROCEDURE [dbo].[USP_PurchaseBook] 
@StartDate datetime
,@EndDate datetime
as
BEGIN

----=================TEMP TABLE TO STORE VATABLE DATA======================
IF (OBJECT_ID('tempdb..#TempTable') is not null)
drop table #TempTable

select GM.GMID, GM.InvoiceNo, GM.vendorId, isnull(sum(GD.Discount), 0) as Discount
,isnull(SUM(GD.Total),0) as VatTotal, 1 as IsVat, GM.InvoiceDate into  #TempTable
from RO_GoodsReceivedMain  GM 
	Inner JOIN RO_GoodsReceivedDetls  GD ON GM.GMId = GD.GMId
	LEFT JOIN ROI_PurchaseDetails PD ON PD.PurchaseDetailsID = GD.PDId
	INNER JOIN DBO.ROI_PurchaseMain PM ON PM.PurchaseMainID = PD.PurchaseMainID
	LEFT JOIN RO_LoyaltyMembership lm ON lm.MembershipId = GM.vendorId
	where 
	(cast(GM.InvoiceDate AS DATE) >= CAST(@StartDate as date) OR @StartDate=0 OR @StartDate IS NULL OR @StartDate='')
		AND (cast(GM.InvoiceDate  AS DATE)<= CAST(@EndDate as date) OR @EndDate=0 OR @EndDate IS NULL OR @EndDate='')
	--( DATEPART(YEAR,GM.InvoiceDate) = cast(@year as int) AND DATEPART(MONTH,GM.InvoiceDate) = cast(@month as int))
		AND GD.IsVat = 1 
GROUP BY GM.GMID, GM.InvoiceNo, GM.vendorId,GD.Discount, GM.ExtraDiscount, GM.InvoiceDate


----=================TEMP TABLE TO STORE NON VATABLE DATA======================
IF (OBJECT_ID('tempdb..#TempTable1') is not null)
drop table #TempTable1

select GM.GMID, GM.InvoiceNo, GM.vendorId, isnull(sum(GD.Discount), 0) as Discount
,isnull(SUM(GD.Total),0) as Total, 0 as IsVat, GM.InvoiceDate into  #TempTable1
from RO_GoodsReceivedMain  GM 
	Inner JOIN RO_GoodsReceivedDetls  GD ON GM.GMId = GD.GMId
	LEFT JOIN ROI_PurchaseDetails PD ON PD.PurchaseDetailsID = GD.PDId
	INNER JOIN DBO.ROI_PurchaseMain PM ON PM.PurchaseMainID = PD.PurchaseMainID
	LEFT JOIN RO_LoyaltyMembership lm ON lm.MembershipId = GM.vendorId
	where 
	(cast(GM.InvoiceDate AS DATE) >= CAST(@StartDate as date) OR @StartDate=0 OR @StartDate IS NULL OR @StartDate='')
		AND (cast(GM.InvoiceDate  AS DATE)<= CAST(@EndDate as date) OR @EndDate=0 OR @EndDate IS NULL OR @EndDate='')
	--( DATEPART(YEAR,GM.InvoiceDate) = cast(@year as int) AND DATEPART(MONTH,GM.InvoiceDate) = cast(@month as int))
		AND ISNULL(GD.IsVat,0) = 0
GROUP BY GM.GMID, GM.InvoiceNo, GM.vendorId,GD.Discount, GM.ExtraDiscount, GM.InvoiceDate


----=================RESULT TO DISPLAY VATABLE AND NON-VATABLE DATA======================

 select distinct GM.GMID, GM.GMNo,PM.PuNo, GM.InvoiceNo, GM.PostedOn, GM.InvoiceDate
,isnull((select isnull(tmp1.Discount, 0) from #TempTable1 tmp1 where tmp1.GMId = GD.GMId),0)  as Discount
,isnull((select isnull(tmp1.Total, 0) from #TempTable1 tmp1 where tmp1.GMId = GD.GMId),0) as Total 
, lm.Fname, lm.PAN, isnull(GM.ExtraDiscount,0) as ExtraDiscount
,isnull((select isnull(tmp.VatTotal, 0) from #TempTable tmp where tmp.GMId = GD.GMId),0) as VatTotal
,isnull((select isnull(tmp.IsVat, 0) from #TempTable tmp where tmp.GMId = GD.GMId),0) as vat
,isnull((select isnull(tmp.Discount, 0) from #TempTable tmp where tmp.GMId = GD.GMId),0) as vatdiscount
from RO_GoodsReceivedMain  GM 
	Inner JOIN RO_GoodsReceivedDetls  GD ON GM.GMId = GD.GMId 
		inner JOIN ROI_PurchaseDetails PD ON PD.PurchaseDetailsID = GD.PDId
	inner JOIN DBO.ROI_PurchaseMain PM ON PM.PurchaseMainID = PD.PurchaseMainID
	inner JOIN RO_LoyaltyMembership lm ON lm.MembershipId = GM.vendorId	
	where 
	(cast(GM.InvoiceDate AS DATE) >= cast(@StartDate as date) OR @StartDate=0 OR @StartDate IS NULL OR @StartDate='')
		AND (cast(GM.InvoiceDate  AS DATE)<= cast(@EndDate as date) OR @EndDate=0 OR @EndDate IS NULL OR @EndDate='')



END
GO



sales and purchase clear script
-- Clear HouseKeeping
TRUNCATE TABLE [dbo].[H_HouseKeeping]
TRUNCATE TABLE [dbo].[H_HouseKeepingStatus]
TRUNCATE TABLE [dbo].[H_LostAndFound]

-- Clear Logs and Misc
TRUNCATE TABLE RO_SMS_Message
TRUNCATE TABLE WaiterNotificationLog
TRUNCATE TABLE [log]
TRUNCATE TABLE SessionTracker
TRUNCATE TABLE DailyChalanIssueDetails
TRUNCATE TABLE DailyChalanMaster
TRUNCATE TABLE DailyChalanReturnedDetail
TRUNCATE TABLE [DailyFinancialReport]
TRUNCATE TABLE [DailySalesReport]
TRUNCATE TABLE [DailyStockReport]
TRUNCATE TABLE [CBMS_BillPostLog]
TRUNCATE TABLE [CBMS_BillReturnPostLog]
TRUNCATE TABLE [RO_Sales_View]
TRUNCATE TABLE CashDenomination
TRUNCATE TABLE RO_CustomerBillLog

-- Loyalty Membership Module
TRUNCATE TABLE Roi_CustomerBalance
TRUNCATE TABLE [RO_MemberPay]
TRUNCATE TABLE RO_MemberPaymentMode
UPDATE RO_LoyaltyMembership SET RemainingBalance = 0

-- Sales Module
TRUNCATE TABLE RO_SalesPaymentMode
TRUNCATE TABLE RO_SalesMaster
TRUNCATE TABLE RO_SalesDetail
TRUNCATE TABLE RO_CakeSalesDetail
DELETE FROM RO_CakeSalesMaster
TRUNCATE TABLE [dbo].[Cake_PrintDetail]
TRUNCATE TABLE RO_CAKE_BillingAmount
TRUNCATE TABLE RO_Discount
TRUNCATE TABLE RO_AdvancePaymentMode
TRUNCATE TABLE RO_CAKE_SalesPaymentMode
TRUNCATE TABLE [RO_SalesDetailExtra]
TRUNCATE TABLE RO_BillingAmount
TRUNCATE TABLE [ro_flatandPerDiscount]
TRUNCATE TABLE PrintDetail
TRUNCATE TABLE RO_SalesDetailsIngredient

-- Orders
TRUNCATE TABLE RO_Order_Detail
TRUNCATE TABLE RO_OrderMasters
TRUNCATE TABLE RO_CakeOrder_Detail
DELETE FROM RO_CakeOrderMaster
TRUNCATE TABLE RO_CakeOrderToken
TRUNCATE TABLE Order_Detail_Cancel
TRUNCATE TABLE [RO_OrderItemStatus]
TRUNCATE TABLE ro_order_extraitem
TRUNCATE TABLE ro_roombookings
TRUNCATE TABLE RO_ItemShiftLog
TRUNCATE TABLE [RO_ComplementaryItems]
TRUNCATE TABLE [tblComplementaryMaster]
TRUNCATE TABLE [Comp_ExtraItem]
TRUNCATE TABLE [CompItemStatus]
TRUNCATE TABLE RO_OrderToken
TRUNCATE TABLE RO_GarbageIngredientDetails
TRUNCATE TABLE RO_GarbageDetail

-- Purchase Module
TRUNCATE TABLE Ro_AdjustmentType
TRUNCATE TABLE ROI_AdjustmentDetls
TRUNCATE TABLE ROI_AdjustmentMain
TRUNCATE TABLE ROI_PurchaseDetails
TRUNCATE TABLE ROI_PurchaseLotNo
TRUNCATE TABLE ROI_PurchaseMain
TRUNCATE TABLE RO_PurchaseReturnMain
TRUNCATE TABLE RO_PurchasePaymentMode
TRUNCATE TABLE RO_PurchaseReturnPaymentMode
TRUNCATE TABLE RO_PurchaseReturnDetails
TRUNCATE TABLE RO_GoodsReceivedMain
TRUNCATE TABLE RO_GoodsReceivedDetls
TRUNCATE TABLE ROI_IssueMain
TRUNCATE TABLE ROI_IssueDetails
TRUNCATE TABLE RO_ProductionDetails
TRUNCATE TABLE RO_ProductionMain
TRUNCATE TABLE RO_PointScheme
TRUNCATE TABLE Req_Recquistion
TRUNCATE TABLE Req_RecquistionDetails
TRUNCATE TABLE [dbo].[RO_VendorPurchase]
TRUNCATE TABLE [dbo].[Req_IssueLog]



-- Store Module
TRUNCATE TABLE [ROI_ITEMBal]

-- Stock Module
TRUNCATE TABLE [dbo].[ROI_AdjustStockTransaction]
TRUNCATE TABLE [dbo].[ROI_ComplementryStockTransaction]
TRUNCATE TABLE [dbo].[ROI_SalesReturnStockTransaction]
TRUNCATE TABLE [dbo].[ROI_IssueStockTransaction]
TRUNCATE TABLE [dbo].[ROI_OpeningStockTransaction]
TRUNCATE TABLE [dbo].[ROI_PurchaseStockTransaction]
TRUNCATE TABLE [dbo].[ROI_SalesStockTransaction]
TRUNCATE TABLE [dbo].[ROI_StockTransactionMaster]

--reset table
TRUNCATE TABLE [RO_MergeTable]
UPDATE RO_restroTable SET restrotablesStatusID = 6

-- Accounts Module
TRUNCATE TABLE ac_bankinfo
TRUNCATE TABLE ac_temptransaction
TRUNCATE TABLE [dbo].[Ac_OpeningBalanceDetail]
TRUNCATE TABLE ac_temptransactiondetail
TRUNCATE TABLE ac_transaction
TRUNCATE TABLE ac_transactiondetail
UPDATE Ac_VoucherType SET VoucherCount = 0
UPDATE Ac_FinancialAc SET openingbalance = 0
DELETE FROM Ac_FinancialAc WHERE SystemGenerated IS NULL

-- START BILL FROM bILL NO 1
UPDATE dbo.RO_fiscalYear SET FirstSalesMasterID = NULL



-- Clear HouseKeeping
TRUNCATE TABLE [dbo].[H_HouseKeeping]
TRUNCATE TABLE [dbo].[H_HouseKeepingStatus]
TRUNCATE TABLE [dbo].[H_LostAndFound]

-- Clear Logs and Misc
TRUNCATE TABLE RO_SMS_Message
TRUNCATE TABLE WaiterNotificationLog
TRUNCATE TABLE [log]
TRUNCATE TABLE SessionTracker
TRUNCATE TABLE DailyChalanIssueDetails
TRUNCATE TABLE DailyChalanMaster
TRUNCATE TABLE DailyChalanReturnedDetail
TRUNCATE TABLE [DailyFinancialReport]
TRUNCATE TABLE [DailySalesReport]
TRUNCATE TABLE [DailyStockReport]
TRUNCATE TABLE [CBMS_BillPostLog]
TRUNCATE TABLE [CBMS_BillReturnPostLog]
TRUNCATE TABLE [RO_Sales_View]
TRUNCATE TABLE CashDenomination
TRUNCATE TABLE RO_CustomerBillLog

-- Loyalty Membership Module
TRUNCATE TABLE RO_LoyaltyMembership
TRUNCATE TABLE Roi_CustomerBalance
TRUNCATE TABLE [RO_MemberPay]
TRUNCATE TABLE RO_MemberPaymentMode
UPDATE RO_LoyaltyMembership SET RemainingBalance = 0

-- Sales Module
TRUNCATE TABLE RO_SalesPaymentMode
TRUNCATE TABLE RO_SalesMaster
TRUNCATE TABLE RO_SalesDetail
TRUNCATE TABLE RO_CakeSalesDetail
DELETE FROM RO_CakeSalesMaster
TRUNCATE TABLE [dbo].[Cake_PrintDetail]
TRUNCATE TABLE RO_CAKE_BillingAmount
TRUNCATE TABLE RO_Discount
TRUNCATE TABLE RO_AdvancePaymentMode
TRUNCATE TABLE RO_CAKE_SalesPaymentMode
TRUNCATE TABLE [RO_SalesDetailExtra]
TRUNCATE TABLE RO_BillingAmount
TRUNCATE TABLE [ro_flatandPerDiscount]
TRUNCATE TABLE PrintDetail
TRUNCATE TABLE RO_SalesDetailsIngredient

-- Orders
TRUNCATE TABLE RO_Order_Detail
TRUNCATE TABLE RO_OrderMasters
TRUNCATE TABLE RO_CakeOrder_Detail
DELETE FROM RO_CakeOrderMaster
TRUNCATE TABLE RO_CakeOrderToken
TRUNCATE TABLE Order_Detail_Cancel
TRUNCATE TABLE [RO_OrderItemStatus]
TRUNCATE TABLE ro_order_extraitem
TRUNCATE TABLE ro_roombookings
TRUNCATE TABLE RO_ItemShiftLog
TRUNCATE TABLE [RO_ComplementaryItems]
TRUNCATE TABLE [tblComplementaryMaster]
TRUNCATE TABLE [Comp_ExtraItem]
TRUNCATE TABLE [CompItemStatus]
TRUNCATE TABLE RO_OrderToken
TRUNCATE TABLE RO_GarbageIngredientDetails
TRUNCATE TABLE RO_GarbageDetail

-- Purchase Module
TRUNCATE TABLE Ro_AdjustmentType
TRUNCATE TABLE ROI_AdjustmentDetls
TRUNCATE TABLE ROI_AdjustmentMain
TRUNCATE TABLE ROI_PurchaseDetails
TRUNCATE TABLE ROI_PurchaseLotNo
TRUNCATE TABLE ROI_PurchaseMain
TRUNCATE TABLE RO_PurchaseReturnMain
TRUNCATE TABLE RO_PurchasePaymentMode
TRUNCATE TABLE RO_PurchaseReturnPaymentMode
TRUNCATE TABLE RO_PurchaseReturnDetails
TRUNCATE TABLE RO_GoodsReceivedMain
TRUNCATE TABLE RO_GoodsReceivedDetls
TRUNCATE TABLE ROI_IssueMain
TRUNCATE TABLE ROI_IssueDetails
TRUNCATE TABLE RO_ProductionDetails
TRUNCATE TABLE RO_ProductionMain
TRUNCATE TABLE RO_PointScheme
TRUNCATE TABLE Req_Recquistion
TRUNCATE TABLE Req_RecquistionDetails
TRUNCATE TABLE [dbo].[RO_VendorPurchase]
TRUNCATE TABLE [dbo].[Req_IssueLog]
TRUNCATE TABLE [Roi_GroupWithItem]
TRUNCATE TABLE [Roi_ItemGrouP]
TRUNCATE TABLE Roi_ItemWithUnit
TRUNCATE TABLE RO_Units

-- Units & Conversions
TRUNCATE TABLE [dbo].[ROI_Unit1]
TRUNCATE TABLE [dbo].[ROI_Unit2]
TRUNCATE TABLE [dbo].[ROI_Unit3]
TRUNCATE TABLE [dbo].[ROI_Unit4]

-- Store Module
TRUNCATE TABLE [dbo].[ROI_Store]
TRUNCATE TABLE [dbo].[StoreItemMinimumStock]
TRUNCATE TABLE [ROI_ITEMBal]
UPDATE costcenterinfo SET coDiscount = 0, storeid = 0

-- Stock Module
TRUNCATE TABLE [dbo].[ROI_AdjustStockTransaction]
TRUNCATE TABLE [dbo].[ROI_ComplementryStockTransaction]
TRUNCATE TABLE [dbo].[ROI_SalesReturnStockTransaction]
TRUNCATE TABLE [dbo].[ROI_IssueStockTransaction]
TRUNCATE TABLE [dbo].[ROI_OpeningStockTransaction]
TRUNCATE TABLE [dbo].[ROI_PurchaseStockTransaction]
TRUNCATE TABLE [dbo].[ROI_SalesStockTransaction]
TRUNCATE TABLE [dbo].[ROI_StockTransactionMaster]

-- Menu Items & Ingredients
TRUNCATE TABLE RO_Categories
TRUNCATE TABLE ROI_ITEMMain
TRUNCATE TABLE ROI_ItemDetails
TRUNCATE TABLE ROI_ItemRateHistory
TRUNCATE TABLE ROI_ItemRate
TRUNCATE TABLE RO_Combo
TRUNCATE TABLE RO_ComboDetails
TRUNCATE TABLE RO_ExtraItem
TRUNCATE TABLE [Roi_ExtraItemForItem]
TRUNCATE TABLE [dbo].[RO_ExtraIngredient]
TRUNCATE TABLE [dbo].[Ro_Ingredient]
TRUNCATE TABLE RO_restroTable
TRUNCATE TABLE RO_RestroRoom
TRUNCATE TABLE Ro_RoomType
TRUNCATE TABLE [RO_MergeTable]
UPDATE RO_restroTable SET restrotablesStatusID = 6

-- Accounts Module
TRUNCATE TABLE RO_CardProvider
TRUNCATE TABLE ac_bankinfo
TRUNCATE TABLE ac_temptransaction
TRUNCATE TABLE [dbo].[Ac_OpeningBalanceDetail]
TRUNCATE TABLE ac_temptransactiondetail
TRUNCATE TABLE ac_transaction
TRUNCATE TABLE ac_transactiondetail
UPDATE Ac_VoucherType SET VoucherCount = 0
UPDATE Ac_FinancialAc SET openingbalance = 0
DELETE FROM Ac_FinancialAc WHERE SystemGenerated IS NULL

-- Users
DELETE FROM PortalUser WHERE PortalUserID <> 1

-- START BILL FROM bILL NO 1
UPDATE dbo.RO_fiscalYear SET FirstSalesMasterID = NULL

