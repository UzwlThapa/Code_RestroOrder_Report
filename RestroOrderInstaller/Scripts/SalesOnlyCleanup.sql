-- =============================================
-- SALES AND ORDERS CLEANUP ONLY - RestroOrder
-- WARNING: IRREVERSIBLE - ALWAYS BACKUP FIRST!
-- =============================================
-- Use Case: End of fiscal year, go-live preparation
-- Keeps: Menu, Ingredients, Vendors, Masters, Users
-- Clears: Sales, Orders, Purchases, Stock Transactions
-- =============================================

USE RestroOrder;
GO

PRINT 'Starting Sales & Orders Cleanup...';
PRINT 'Backup Date: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '===========================================';

BEGIN TRANSACTION;

BEGIN TRY
    PRINT 'Step 1/12: Clearing HouseKeeping...';
    TRUNCATE TABLE [dbo].[H_HouseKeeping];
    TRUNCATE TABLE [dbo].[H_HouseKeepingStatus];
    TRUNCATE TABLE [dbo].[H_LostAndFound];

    PRINT 'Step 2/12: Clearing Logs...';
    TRUNCATE TABLE RO_SMS_Message;
    TRUNCATE TABLE WaiterNotificationLog;
    TRUNCATE TABLE [log];
    TRUNCATE TABLE SessionTracker;
    TRUNCATE TABLE DailyChalanIssueDetails;
    TRUNCATE TABLE DailyChalanMaster;
    TRUNCATE TABLE DailyChalanReturnedDetail;
    TRUNCATE TABLE [DailyFinancialReport];
    TRUNCATE TABLE [DailySalesReport];
    TRUNCATE TABLE [DailyStockReport];
    TRUNCATE TABLE [CBMS_BillPostLog];
    TRUNCATE TABLE [CBMS_BillReturnPostLog];
    TRUNCATE TABLE [RO_Sales_View];
    TRUNCATE TABLE CashDenomination;
    TRUNCATE TABLE RO_CustomerBillLog;

    PRINT 'Step 3/12: Resetting Loyalty Balances...';
    TRUNCATE TABLE Roi_CustomerBalance;
    TRUNCATE TABLE [RO_MemberPay];
    TRUNCATE TABLE RO_MemberPaymentMode;
    UPDATE RO_LoyaltyMembership SET RemainingBalance = 0;
    -- Keeping RO_LoyaltyMembership master data

    PRINT 'Step 4/12: Clearing Sales Module...';
    TRUNCATE TABLE RO_SalesPaymentMode;
    TRUNCATE TABLE RO_SalesMaster;
    TRUNCATE TABLE RO_SalesDetail;
    TRUNCATE TABLE RO_CakeSalesDetail;
    DELETE FROM RO_CakeSalesMaster;
    TRUNCATE TABLE [dbo].[Cake_PrintDetail];
    TRUNCATE TABLE RO_CAKE_BillingAmount;
    TRUNCATE TABLE RO_Discount;
    TRUNCATE TABLE RO_AdvancePaymentMode;
    TRUNCATE TABLE RO_CAKE_SalesPaymentMode;
    TRUNCATE TABLE [RO_SalesDetailExtra];
    TRUNCATE TABLE RO_BillingAmount;
    TRUNCATE TABLE [ro_flatandPerDiscount];
    TRUNCATE TABLE PrintDetail;
    TRUNCATE TABLE RO_SalesDetailsIngredient;

    PRINT 'Step 5/12: Clearing Orders...';
    TRUNCATE TABLE RO_Order_Detail;
    TRUNCATE TABLE RO_OrderMasters;
    TRUNCATE TABLE RO_CakeOrder_Detail;
    DELETE FROM RO_CakeOrderMaster;
    TRUNCATE TABLE RO_CakeOrderToken;
    TRUNCATE TABLE Order_Detail_Cancel;
    TRUNCATE TABLE [RO_OrderItemStatus];
    TRUNCATE TABLE ro_order_extraitem;
    TRUNCATE TABLE ro_roombookings;
    TRUNCATE TABLE RO_ItemShiftLog;
    TRUNCATE TABLE [RO_ComplementaryItems];
    TRUNCATE TABLE [tblComplementaryMaster];
    TRUNCATE TABLE [Comp_ExtraItem];
    TRUNCATE TABLE [CompItemStatus];
    TRUNCATE TABLE RO_OrderToken;
    TRUNCATE TABLE RO_GarbageIngredientDetails;
    TRUNCATE TABLE RO_GarbageDetail;

    PRINT 'Step 6/12: Clearing Purchase Transactions...';
    TRUNCATE TABLE Ro_AdjustmentType;
    TRUNCATE TABLE ROI_AdjustmentDetls;
    TRUNCATE TABLE ROI_AdjustmentMain;
    TRUNCATE TABLE ROI_PurchaseDetails;
    TRUNCATE TABLE ROI_PurchaseLotNo;
    TRUNCATE TABLE ROI_PurchaseMain;
    TRUNCATE TABLE RO_PurchaseReturnMain;
    TRUNCATE TABLE RO_PurchasePaymentMode;
    TRUNCATE TABLE RO_PurchaseReturnPaymentMode;
    TRUNCATE TABLE RO_PurchaseReturnDetails;
    TRUNCATE TABLE RO_GoodsReceivedMain;
    TRUNCATE TABLE RO_GoodsReceivedDetls;
    TRUNCATE TABLE ROI_IssueMain;
    TRUNCATE TABLE ROI_IssueDetails;
    TRUNCATE TABLE RO_ProductionDetails;
    TRUNCATE TABLE RO_ProductionMain;
    TRUNCATE TABLE RO_PointScheme;
    TRUNCATE TABLE Req_Recquistion;
    TRUNCATE TABLE Req_RecquistionDetails;
    TRUNCATE TABLE [dbo].[RO_VendorPurchase];
    TRUNCATE TABLE [dbo].[Req_IssueLog];
    -- Keeping vendor master data

    PRINT 'Step 7/12: Resetting Stock Balance...';
    TRUNCATE TABLE [ROI_ITEMBal];
    -- Keeping store and item definitions

    PRINT 'Step 8/12: Clearing Stock Transactions...';
    TRUNCATE TABLE [dbo].[ROI_AdjustStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_ComplementryStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_SalesReturnStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_IssueStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_OpeningStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_PurchaseStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_SalesStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_StockTransactionMaster];

    PRINT 'Step 9/12: Resetting Tables...';
    TRUNCATE TABLE [RO_MergeTable];
    UPDATE RO_restroTable SET restrotablesStatusID = 6;
    -- Keeping table, room, and room type masters

    PRINT 'Step 10/12: Clearing Accounting Transactions...';
    TRUNCATE TABLE ac_bankinfo;
    TRUNCATE TABLE ac_temptransaction;
    TRUNCATE TABLE [dbo].[Ac_OpeningBalanceDetail];
    TRUNCATE TABLE ac_temptransactiondetail;
    TRUNCATE TABLE ac_transaction;
    TRUNCATE TABLE ac_transactiondetail;
    UPDATE Ac_VoucherType SET VoucherCount = 0;
    UPDATE Ac_FinancialAc SET openingbalance = 0;
    DELETE FROM Ac_FinancialAc WHERE SystemGenerated IS NULL;
    -- Keeping chart of accounts structure

    PRINT 'Step 11/12: Resetting Bill Numbers...';
    UPDATE dbo.RO_fiscalYear SET FirstSalesMasterID = NULL;

    PRINT 'Step 12/12: Updating Version History...';
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DB_VersionHistory')
    BEGIN
        INSERT INTO DB_VersionHistory (VersionNumber, Description, ScriptHash, Success)
        VALUES ('2.0-SALES-CLEANUP', 'Sales and orders cleanup executed', '', 1);
    END

    COMMIT TRANSACTION;
    
    PRINT '===========================================';
    PRINT 'SALES & ORDERS CLEANUP COMPLETED SUCCESSFULLY';
    PRINT 'Date: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '===========================================';
    PRINT '';
    PRINT 'What was cleared:';
    PRINT '✓ All sales bills and details';
    PRINT '✓ All orders and tokens';
    PRINT '✓ All purchase transactions';
    PRINT '✓ All stock movements';
    PRINT '✓ All daily reports';
    PRINT '✓ Customer balances (reset to 0)';
    PRINT '✓ Accounting transactions';
    PRINT '';
    PRINT 'What was kept:';
    PRINT '✓ Menu items, categories, recipes';
    PRINT '✓ Ingredient definitions and rates';
    PRINT '✓ Vendor master data';
    PRINT '✓ Cost centers and stores';
    PRINT '✓ User accounts';
    PRINT '✓ Printer configurations';
    PRINT '✓ Table and room setup';
    PRINT '✓ Chart of accounts structure';
    PRINT '===========================================';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    
    PRINT 'ERROR OCCURRED during cleanup!';
    PRINT 'Error Message: ' + @ErrorMessage;
    PRINT 'Transaction rolled back - no changes made';
    
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH;
GO
