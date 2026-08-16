-- =============================================
-- FULL DATA CLEANUP SCRIPT - RestroOrder
-- WARNING: IRREVERSIBLE - ALWAYS BACKUP FIRST!
-- =============================================
-- Use Case: New client setup, complete fresh start
-- Keeps: Menu items, categories, ingredients, rates, printer settings, cost centers
-- Clears: ALL transactional data
-- =============================================

USE RestroOrder;
GO

PRINT 'Starting Full Data Cleanup...';
PRINT 'Backup Date: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '===========================================';

BEGIN TRANSACTION;

BEGIN TRY
    PRINT 'Step 1/15: Clearing HouseKeeping Module...';
    TRUNCATE TABLE [dbo].[H_HouseKeeping];
    TRUNCATE TABLE [dbo].[H_HouseKeepingStatus];
    TRUNCATE TABLE [dbo].[H_LostAndFound];

    PRINT 'Step 2/15: Clearing Logs and Miscellaneous...';
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

    PRINT 'Step 3/15: Clearing Loyalty Membership Module...';
    TRUNCATE TABLE RO_LoyaltyMembership;
    TRUNCATE TABLE Roi_CustomerBalance;
    TRUNCATE TABLE [RO_MemberPay];
    TRUNCATE TABLE RO_MemberPaymentMode;
    UPDATE RO_LoyaltyMembership SET RemainingBalance = 0;

    PRINT 'Step 4/15: Clearing Sales Module (COMPLETE)...';
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

    PRINT 'Step 5/15: Clearing Orders Module...';
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

    PRINT 'Step 6/15: Clearing Purchase Module...';
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
    TRUNCATE TABLE [Roi_GroupWithItem];
    TRUNCATE TABLE [Roi_ItemGrouP];
    TRUNCATE TABLE Roi_ItemWithUnit;
    TRUNCATE TABLE RO_Units;

    PRINT 'Step 7/15: Clearing Units & Conversions...';
    TRUNCATE TABLE [dbo].[ROI_Unit1];
    TRUNCATE TABLE [dbo].[ROI_Unit2];
    TRUNCATE TABLE [dbo].[ROI_Unit3];
    TRUNCATE TABLE [dbo].[ROI_Unit4];

    PRINT 'Step 8/15: Clearing Store Module...';
    TRUNCATE TABLE [dbo].[ROI_Store];
    TRUNCATE TABLE [dbo].[StoreItemMinimumStock];
    TRUNCATE TABLE [ROI_ITEMBal];
    UPDATE costcenterinfo SET coDiscount = 0, storeid = 0;

    PRINT 'Step 9/15: Clearing Stock Transactions...';
    TRUNCATE TABLE [dbo].[ROI_AdjustStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_ComplementryStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_SalesReturnStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_IssueStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_OpeningStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_PurchaseStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_SalesStockTransaction];
    TRUNCATE TABLE [dbo].[ROI_StockTransactionMaster];

    PRINT 'Step 10/15: Resetting Tables and Rooms...';
    TRUNCATE TABLE [RO_MergeTable];
    UPDATE RO_restroTable SET restrotablesStatusID = 6;
    -- Note: Keeping RO_Categories, ROI_ITEMMain, ROI_ItemDetails for menu setup
    -- Uncomment below if you want COMPLETE wipe including menu
    -- TRUNCATE TABLE RO_Categories;
    -- TRUNCATE TABLE ROI_ITEMMain;
    -- TRUNCATE TABLE ROI_ItemDetails;
    -- TRUNCATE TABLE ROI_ItemRateHistory;
    -- TRUNCATE TABLE ROI_ItemRate;
    -- TRUNCATE TABLE RO_Combo;
    -- TRUNCATE TABLE RO_ComboDetails;
    -- TRUNCATE TABLE RO_ExtraItem;
    -- TRUNCATE TABLE [Roi_ExtraItemForItem];
    -- TRUNCATE TABLE [dbo].[RO_ExtraIngredient];
    -- TRUNCATE TABLE [dbo].[Ro_Ingredient];

    PRINT 'Step 11/15: Clearing Accounts Module...';
    TRUNCATE TABLE RO_CardProvider;
    TRUNCATE TABLE ac_bankinfo;
    TRUNCATE TABLE ac_temptransaction;
    TRUNCATE TABLE [dbo].[Ac_OpeningBalanceDetail];
    TRUNCATE TABLE ac_temptransactiondetail;
    TRUNCATE TABLE ac_transaction;
    TRUNCATE TABLE ac_transactiondetail;
    UPDATE Ac_VoucherType SET VoucherCount = 0;
    UPDATE Ac_FinancialAc SET openingbalance = 0;
    DELETE FROM Ac_FinancialAc WHERE SystemGenerated IS NULL;

    PRINT 'Step 12/15: Clearing User Accounts (Keeping Admin)...';
    DELETE FROM PortalUser WHERE PortalUserID <> 1;

    PRINT 'Step 13/15: Resetting Bill Numbers...';
    UPDATE dbo.RO_fiscalYear SET FirstSalesMasterID = NULL;

    PRINT 'Step 14/15: Updating Version History...';
    IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DB_VersionHistory')
    BEGIN
        INSERT INTO DB_VersionHistory (VersionNumber, Description, ScriptHash, Success)
        VALUES ('2.0-FULL-CLEANUP', 'Full cleanup executed', '', 1);
    END

    PRINT 'Step 15/15: Cleanup Complete!';
    
    COMMIT TRANSACTION;
    
    PRINT '===========================================';
    PRINT 'FULL CLEANUP COMPLETED SUCCESSFULLY';
    PRINT 'Date: ' + CONVERT(VARCHAR, GETDATE(), 120);
    PRINT '===========================================';
    PRINT '';
    PRINT 'What was cleared:';
    PRINT '✓ All sales transactions';
    PRINT '✓ All orders';
    PRINT '✓ All purchases';
    PRINT '✓ All stock movements';
    PRINT '✓ All logs';
    PRINT '✓ All user accounts (except admin)';
    PRINT '✓ All loyalty data';
    PRINT '✓ All accounting transactions';
    PRINT '';
    PRINT 'What was kept:';
    PRINT '✓ Menu items and categories';
    PRINT '✓ Ingredient definitions';
    PRINT '✓ Printer settings';
    PRINT '✓ Cost centers';
    PRINT '✓ Table and room setup';
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
