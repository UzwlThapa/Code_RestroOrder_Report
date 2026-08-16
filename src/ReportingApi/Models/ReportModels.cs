using System.ComponentModel.DataAnnotations;

namespace ReportingApi.Models;

/// <summary>
/// Comprehensive report models for RestroOrder POS - Nepal IRD 2026 Standard
/// Includes Sales, Customer, Vendor, Item, Discount, and complete audit trails
/// </summary>

// ==================== SALES REPORT MODELS ====================

public class SalesReportRecord
{
    public DateTime BillDate { get; set; }
    public string BillNo { get; set; } = string.Empty;
    public string InvoiceNo { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerPAN { get; set; }
    public string? CustomerPhone { get; set; }
    public string? CustomerEmail { get; set; }
    public string TableId { get; set; } = string.Empty;
    public string WaiterName { get; set; } = string.Empty;
    public decimal BasicAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal ServiceCharge { get; set; }
    public decimal TaxableAmount { get; set; }
    public decimal VAT { get; set; }
    public decimal NetAmount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public bool IsArchived { get; set; }
    public bool IsPrinted { get; set; }
    public DateTime? PrintDate { get; set; }
    public int PrintCount { get; set; }
    public string FiscalYear { get; set; } = string.Empty;
    public string AddedBy { get; set; } = string.Empty;
    public string? VoidReason { get; set; }
    public string? VoidedBy { get; set; }
    public DateTime? VoidedAt { get; set; }
    public string BillType { get; set; } = "Regular"; // Regular, Complimentary, Staff, Owner, Promotional, Wastage
    public string? ApprovedBy { get; set; }
    public string BSDate { get; set; } = string.Empty; // Bikram Sambat date
}

public class SalesSummaryReport
{
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public string FromBS { get; set; } = string.Empty;
    public string ToBS { get; set; } = string.Empty;
    public int TotalBills { get; set; }
    public int PrintedBills { get; set; }
    public int VoidedBills { get; set; }
    public int ComplimentaryBills { get; set; }
    public decimal GrossSales { get; set; }
    public decimal TotalDiscount { get; set; }
    public decimal TotalServiceCharge { get; set; }
    public decimal TotalTaxable { get; set; }
    public decimal TotalVAT { get; set; }
    public decimal NetSales { get; set; }
    public Dictionary<string, decimal> PaymentModeBreakdown { get; set; } = new();
    public Dictionary<string, decimal> CategoryWiseSales { get; set; } = new();
    public decimal AverageBillValue { get; set; }
    public decimal HighestBill { get; set; }
    public decimal LowestBill { get; set; }
}

// ==================== ITEM SALES REPORT MODELS ====================

public class ItemSalesReportRecord
{
    public DateTime BillDate { get; set; }
    public string BillNo { get; set; } = string.Empty;
    public string ItemName { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty; // Cost Center
    public string Unit { get; set; } = string.Empty;
    public decimal Qty { get; set; }
    public decimal Rate { get; set; }
    public decimal NetAmount { get; set; }
    public decimal CostPrice { get; set; }
    public decimal Profit { get; set; }
    public decimal ProfitMarginPercent { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string TableId { get; set; } = string.Empty;
    public bool IsCombo { get; set; }
    public string? ComboName { get; set; }
    public string BatchNo { get; set; } = string.Empty; // For liquor ML tracking
    public decimal? MLPackSize { get; set; } // For IRD liquor reporting
    public string HSNCode { get; set; } = string.Empty; // For tax classification
    public string ItemType { get; set; } = "Regular"; // Regular, Liquor, Beer, Food, Package
}

public class ItemSalesSummary
{
    public string ItemName { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string Unit { get; set; } = string.Empty;
    public decimal TotalQty { get; set; }
    public decimal AvgRate { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal TotalCost { get; set; }
    public decimal TotalProfit { get; set; }
    public decimal ProfitMarginPercent { get; set; }
    public int TimesOrdered { get; set; }
    public string ItemType { get; set; } = string.Empty;
    public string HSNCode { get; set; } = string.Empty;
    public decimal? TotalML { get; set; } // For liquor tracking
}

// ==================== DISCOUNT REPORT MODELS ====================

public class DiscountReportRecord
{
    public DateTime BillDate { get; set; }
    public string BillNo { get; set; } = string.Empty;
    public string InvoiceNo { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerPAN { get; set; }
    public decimal BasicAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal DiscountPercent { get; set; }
    public string DiscountType { get; set; } = string.Empty; // Member, Corporate, Promotional, Manager, Owner, Happy Hour
    public string? DiscountReason { get; set; }
    public string AppliedBy { get; set; } = string.Empty;
    public string? ApprovedBy { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public decimal NetAmount { get; set; }
    public string BSDate { get; set; } = string.Empty;
}

public class DiscountSummary
{
    public string DiscountType { get; set; } = string.Empty;
    public int BillCount { get; set; }
    public decimal TotalBasicAmount { get; set; }
    public decimal TotalDiscountGiven { get; set; }
    public decimal AvgDiscountPercent { get; set; }
    public decimal TotalNetAmount { get; set; }
    public Dictionary<string, decimal> UserWiseDiscount { get; set; } = new();
}

// ==================== CUSTOMER REPORT MODELS ====================

public class CustomerReportRecord
{
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerPAN { get; set; }
    public string? CustomerPhone { get; set; }
    public string? CustomerEmail { get; set; }
    public string? CustomerAddress { get; set; }
    public DateTime FirstVisit { get; set; }
    public DateTime LastVisit { get; set; }
    public int TotalVisits { get; set; }
    public decimal TotalSpent { get; set; }
    public decimal AvgBillValue { get; set; }
    public string PreferredPaymentMode { get; set; } = string.Empty;
    public string? PreferredTable { get; set; }
    public List<CustomerBillHistory> BillHistory { get; set; } = new();
    public string CustomerType { get; set; } = "Walk-in"; // Walk-in, Regular, VIP, Corporate, Member
    public string? MembershipId { get; set; }
    public DateTime? MembershipExpiry { get; set; }
    public decimal LifetimeDiscountReceived { get; set; }
    public int LoyaltyPoints { get; set; }
}

public class CustomerBillHistory
{
    public DateTime BillDate { get; set; }
    public string BillNo { get; set; } = string.Empty;
    public string InvoiceNo { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string PaymentMode { get; set; } = string.Empty;
    public string TableId { get; set; } = string.Empty;
    public string ItemsOrdered { get; set; } = string.Empty;
    public string BSDate { get; set; } = string.Empty;
}

public class CustomerSegmentation
{
    public string Segment { get; set; } = string.Empty; // New, Occasional, Regular, VIP, Lost
    public int CustomerCount { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal AvgRevenuePerCustomer { get; set; }
    public int AvgVisitsPerCustomer { get; set; }
}

// ==================== VENDOR/PURCHASE REPORT MODELS ====================

public class VendorReportRecord
{
    public string VendorName { get; set; } = string.Empty;
    public string? VendorPAN { get; set; }
    public string? VendorPhone { get; set; }
    public string? VendorEmail { get; set; }
    public string? VendorAddress { get; set; }
    public string VendorType { get; set; } = string.Empty; // Supplier, Distributor, Importer
    public DateTime FirstPurchase { get; set; }
    public DateTime LastPurchase { get; set; }
    public int TotalPurchases { get; set; }
    public decimal TotalPurchaseAmount { get; set; }
    public decimal TotalPaid { get; set; }
    public decimal OutstandingAmount { get; set; }
    public List<VendorPurchaseHistory> PurchaseHistory { get; set; } = new();
    public string? LicenseNo { get; set; } // For IRD vendor compliance
    public string? RegistrationNo { get; set; }
}

public class VendorPurchaseHistory
{
    public DateTime PurchaseDate { get; set; }
    public string PurchaseOrderNo { get; set; } = string.Empty;
    public string InvoiceNo { get; set; } = string.Empty;
    public string ItemName { get; set; } = string.Empty;
    public decimal Qty { get; set; }
    public decimal Rate { get; set; }
    public decimal Amount { get; set; }
    public decimal VAT { get; set; }
    public string PaymentStatus { get; set; } = string.Empty; // Paid, Partial, Pending
    public string BSDate { get; set; } = string.Empty;
}

public class VendorSummary
{
    public string VendorName { get; set; } = string.Empty;
    public string VendorType { get; set; } = string.Empty;
    public int TotalInvoices { get; set; }
    public decimal TotalPurchaseValue { get; set; }
    public decimal TotalVATClaimable { get; set; }
    public decimal TotalPaid { get; set; }
    public decimal OutstandingBalance { get; set; }
    public string PaymentTerms { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

// ==================== IRD NEPAL 2026 COMPLIANT MODELS ====================

public class IRDSalesBookRecord
{
    [Required]
    public string InvoiceNo { get; set; } = string.Empty;
    [Required]
    public string InvoiceDate { get; set; } = string.Empty; // BS Date
    [Required]
    public string BuyerName { get; set; } = string.Empty;
    public string? BuyerPAN { get; set; }
    public string? BuyerAddress { get; set; }
    public decimal TotalSaleValue { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal TaxableAmount { get; set; }
    public decimal VATRate { get; set; } = 13.0m;
    public decimal VATAmount { get; set; }
    public decimal TotalWithVAT { get; set; }
    public string FiscalYear { get; set; } = string.Empty;
    public string TransactionType { get; set; } = "Sales"; // Sales, Return, Credit Note, Debit Note
    public string? CreditNoteNo { get; set; }
    public string? CreditNoteDate { get; set; } // BS Date
    public bool IsPostedToIRD { get; set; }
    public DateTime? PostedAt { get; set; }
    public string? PostingReference { get; set; }
    public string? ReturnReason { get; set; }
    public string BillType { get; set; } = string.Empty; // Regular, Tax Invoice, Simplified Invoice
}

public class IRDSalesReturnBookRecord
{
    [Required]
    public string CreditNoteNo { get; set; } = string.Empty;
    [Required]
    public string CreditNoteDate { get; set; } = string.Empty; // BS Date
    [Required]
    public string OriginalInvoiceNo { get; set; } = string.Empty;
    [Required]
    public string OriginalInvoiceDate { get; set; } = string.Empty; // BS Date
    public string BuyerName { get; set; } = string.Empty;
    public string? BuyerPAN { get; set; }
    public decimal ReturnTaxableAmount { get; set; }
    public decimal ReturnVATAmount { get; set; }
    public decimal TotalReturnAmount { get; set; }
    public string ReturnReason { get; set; } = string.Empty;
    public string ApprovedBy { get; set; } = string.Empty;
    public bool IsPostedToIRD { get; set; }
    public DateTime? PostedAt { get; set; }
    public string? PostingReference { get; set; }
}

public class IRDDailySummary
{
    public string DateAD { get; set; } = string.Empty;
    public string DateBS { get; set; } = string.Empty;
    public string FiscalYear { get; set; } = string.Empty;
    public int TotalInvoices { get; set; }
    public int TotalCreditNotes { get; set; }
    public decimal GrossSales { get; set; }
    public decimal TotalDiscount { get; set; }
    public decimal NetTaxableSales { get; set; }
    public decimal TotalVATCollected { get; set; }
    public decimal TotalVATReturned { get; set; }
    public decimal NetVATPayable { get; set; }
    public bool IsReconciled { get; set; }
    public string? ReconciledBy { get; set; }
    public DateTime? ReconciledAt { get; set; }
    public string IRDPostStatus { get; set; } = string.Empty; // Pending, Posted, Failed, Reconciled
}

// ==================== BACKUP & RESTORE MODELS ====================

public class BackupRecord
{
    public Guid BackupId { get; set; }
    public string BackupPath { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public long SizeBytes { get; set; }
    public string BackupType { get; set; } = string.Empty; // Full, Incremental, Emergency
    public string Status { get; set; } = string.Empty; // Success, Failed, InProgress
    public string? ErrorMessage { get; set; }
    public string ChecksumSHA256 { get; set; } = string.Empty;
    public bool IsVerified { get; set; }
    public string DatabaseName { get; set; } = string.Empty;
    public string ServerName { get; set; } = string.Empty;
    public int RecordsBackedUp { get; set; }
    public string TriggerType { get; set; } = string.Empty; // Scheduled, Manual, PreUpdate, Emergency
    public string? Notes { get; set; }
}

public class RestoreRequest
{
    public Guid BackupId { get; set; }
    public string TargetDatabase { get; set; } = string.Empty;
    public bool OverwriteExisting { get; set; }
    public bool VerifyAfterRestore { get; set; } = true;
    public string? Notes { get; set; }
}

public class RestoreResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public DateTime RestoredAt { get; set; }
    public int RecordsRestored { get; set; }
    public bool VerificationPassed { get; set; }
    public string? ErrorMessage { get; set; }
}

// ==================== SYSTEM MONITORING & CRASH DETECTION MODELS ====================

public class SystemHealthStatus
{
    public DateTime CheckedAt { get; set; }
    public bool IsHealthy { get; set; }
    public string Status { get; set; } = string.Empty; // Healthy, Degraded, Critical
    public double CPULoadPercent { get; set; }
    public double MemoryLoadPercent { get; set; }
    public long AvailableDiskSpaceBytes { get; set; }
    public bool DatabaseConnected { get; set; }
    public int ActiveConnections { get; set; }
    public int PendingBackupCount { get; set; }
    public DateTime? LastSuccessfulBackup { get; set; }
    public DateTime? LastIRDPost { get; set; }
    public List<string> Warnings { get; set; } = new();
    public List<string> Errors { get; set; } = new();
}

public class CrashIncident
{
    public Guid IncidentId { get; set; }
    public DateTime OccurredAt { get; set; }
    public DateTime DetectedAt { get; set; }
    public string CrashType { get; set; } = string.Empty; // AppCrash, DBDisconnect, PowerFailure, UnhandledException
    public string? ErrorMessage { get; set; }
    public string? StackTrace { get; set; }
    public string AffectedComponent { get; set; } = string.Empty;
    public bool AutoRecovered { get; set; }
    public DateTime? RecoveredAt { get; set; }
    public string RecoveryAction { get; set; } = string.Empty;
    public bool DataIntegrityCompromised { get; set; }
    public List<string> AffectedTables { get; set; } = new();
    public Guid? RelatedBackupId { get; set; }
    public string Severity { get; set; } = string.Empty; // Low, Medium, High, Critical
}

public class AuditLog
{
    public long Id { get; set; }
    public DateTime Timestamp { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string EntityType { get; set; } = string.Empty;
    public string? EntityId { get; set; }
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public string IPAddress { get; set; } = string.Empty;
    public string MachineName { get; set; } = string.Empty;
    public bool Success { get; set; }
    public string? ErrorMessage { get; set; }
}

// ==================== EMAIL & NOTIFICATION MODELS ====================

public record EmailRequest(
    string ReportType, 
    string ToEmail, 
    DateTime From, 
    DateTime To,
    string? FromBS = null, 
    string? ToBS = null, 
    string? Item = null, 
    string? CostCenter = null, 
    string? Unit = null, 
    string? Table = null, 
    string? PaymentMode = null,
    string? CustomerName = null,
    string? VendorName = null,
    bool IncludeAttachments = true,
    string? CustomSubject = null,
    string? CustomBody = null
);

public class NotificationConfig
{
    public bool EmailEnabled { get; set; } = true;
    public bool SMSEnabled { get; set; } = false;
    public bool WhatsAppEnabled { get; set; } = false;
    public string AdminEmail { get; set; } = string.Empty;
    public string[] AlertRecipients { get; set; } = Array.Empty<string>();
    public bool NotifyOnCrash { get; set; } = true;
    public bool NotifyOnBackupFailure { get; set; } = true;
    public bool NotifyOnIRDFailure { get; set; } = true;
    public bool DailyReportEnabled { get; set; } = true;
    public TimeSpan DailyReportTime { get; set; } = TimeSpan.FromHours(22); // 10 PM
}
