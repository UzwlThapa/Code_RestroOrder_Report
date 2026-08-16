using Microsoft.Extensions.Hosting;
using ReportingApi.Services;
using ReportingApi.Services.Backup;
using ReportingApi.Services.Monitoring;

var builder = WebApplication.CreateBuilder(args);
builder.Host.UseWindowsService();

// Register services
builder.Services.AddSingleton<ReportQueries>();
builder.Services.AddSingleton<ExcelExportService>();
builder.Services.AddSingleton<EmailService>();
builder.Services.AddHostedService<BackupService>();
builder.Services.AddHostedService<SystemMonitoringService>();
builder.Services.AddSingleton<BackupService>();
builder.Services.AddSingleton<SystemMonitoringService>();
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

var app = builder.Build();
app.UseCors();
app.UseDefaultFiles();
app.UseStaticFiles();

// Get monitoring service for event handling
var monitoringService = app.Services.GetRequiredService<SystemMonitoringService>();
var backupService = app.Services.GetRequiredService<BackupService>();

// Wire up crash detection to trigger emergency backups
monitoringService.OnCrashDetected += async (sender, incident) =>
{
    await backupService.CreateEmergencyBackupAsync();
};

// ==================== EXISTING ENDPOINTS ====================

// IRD Nepal Sales Book
app.MapGet("/api/reports/ird-sales-book", async (string from, string to, ReportQueries q, ExcelExportService x) =>
{
    var rows = await q.GetIrdSalesBookAsync(from, to);
    var file = x.Export(rows, "Sales Book");
    return Results.File(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "IRD_SalesBook.xlsx");
});

// IRD Nepal Sales Return Book
app.MapGet("/api/reports/ird-sales-return-book", async (string from, string to, ReportQueries q, ExcelExportService x) =>
{
    var rows = await q.GetIrdSalesReturnBookAsync(from, to);
    var file = x.Export(rows, "Sales Return Book");
    return Results.File(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "IRD_SalesReturnBook.xlsx");
});

// Materialized sales report
app.MapGet("/api/reports/materialized", async (DateTime from, DateTime to, int? valid, string? paymentMode, ReportQueries q) =>
    Results.Ok(await q.GetMaterializedSalesReportAsync(from, to, valid ?? -1, paymentMode)));

app.MapGet("/api/reports/materialized/export", async (DateTime from, DateTime to, int? valid, string? paymentMode, ReportQueries q, ExcelExportService x) =>
{
    var rows = await q.GetMaterializedSalesReportAsync(from, to, valid ?? -1, paymentMode);
    var file = x.Export(rows, "Sales Report");
    return Results.File(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "MaterializedSalesReport.xlsx");
});

// Filterable sales report
app.MapGet("/api/reports/sales", async (HttpRequest req, ReportQueries q) =>
    Results.Ok(await q.GetFilterableSalesReportAsync(
        DateTime.Parse(req.Query["from"].ToString()),
        DateTime.Parse(req.Query["to"].ToString()),
        Nullable(req.Query["item"]), Nullable(req.Query["costCenter"]), Nullable(req.Query["unit"]),
        DecimalOrNull(req.Query["rateMin"]), DecimalOrNull(req.Query["rateMax"]),
        Nullable(req.Query["table"]), Nullable(req.Query["paymentMode"]))));

app.MapGet("/api/reports/sales/export", async (HttpRequest req, ReportQueries q, ExcelExportService x) =>
{
    var rows = await q.GetFilterableSalesReportAsync(
        DateTime.Parse(req.Query["from"].ToString()),
        DateTime.Parse(req.Query["to"].ToString()),
        Nullable(req.Query["item"]), Nullable(req.Query["costCenter"]), Nullable(req.Query["unit"]),
        DecimalOrNull(req.Query["rateMin"]), DecimalOrNull(req.Query["rateMax"]),
        Nullable(req.Query["table"]), Nullable(req.Query["paymentMode"]));
    var file = x.Export(rows, "Sales Report");
    return Results.File(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "SalesReport.xlsx");
});

// Email any report
app.MapPost("/api/reports/email", async (EmailRequest body, ReportQueries q, ExcelExportService x, EmailService mail) =>
{
    IEnumerable<dynamic> rows = body.ReportType switch
    {
        "ird-sales-book" => await q.GetIrdSalesBookAsync(body.FromBS ?? "", body.ToBS ?? ""),
        "ird-sales-return-book" => await q.GetIrdSalesReturnBookAsync(body.FromBS ?? "", body.ToBS ?? ""),
        "materialized" => await q.GetMaterializedSalesReportAsync(body.From, body.To, -1, null),
        "sales" => await q.GetFilterableSalesReportAsync(body.From, body.To, body.Item, body.CostCenter, body.Unit, null, null, body.Table, body.PaymentMode),
        _ => throw new ArgumentException("Unknown reportType")
    };
    var file = x.Export(rows, body.ReportType);
    await mail.SendReportAsync(body.ToEmail, $"{body.ReportType} report", "Attached as requested.", file, $"{body.ReportType}.xlsx");
    return Results.Ok(new { sent = true });
});

// ==================== NEW COMPREHENSIVE REPORT ENDPOINTS ====================

// Comprehensive Sales Report
app.MapGet("/api/reports/comprehensive-sales", async (DateTime from, DateTime to, string? customerName, string? paymentMode, string? billType, decimal? minAmount, ReportQueries q) =>
    Results.Ok(await q.GetComprehensiveSalesReportAsync(from, to, customerName, paymentMode, billType, minAmount)));

app.MapGet("/api/reports/comprehensive-sales/export", async (DateTime from, DateTime to, string? customerName, string? paymentMode, string? billType, decimal? minAmount, ReportQueries q, ExcelExportService x) =>
{
    var rows = await q.GetComprehensiveSalesReportAsync(from, to, customerName, paymentMode, billType, minAmount);
    var file = x.Export(rows, "Comprehensive Sales Report");
    return Results.File(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "ComprehensiveSalesReport.xlsx");
});

// Sales Summary
app.MapGet("/api/reports/sales-summary", async (DateTime from, DateTime to, ReportQueries q) =>
    Results.Ok(await q.GetSalesSummaryAsync(from, to)));

// Item Sales Report
app.MapGet("/api/reports/item-sales", async (DateTime from, DateTime to, string? itemName, string? category, string? itemType, ReportQueries q) =>
    Results.Ok(await q.GetItemSalesReportAsync(from, to, itemName, category, itemType)));

app.MapGet("/api/reports/item-sales/export", async (DateTime from, DateTime to, string? itemName, string? category, string? itemType, ReportQueries q, ExcelExportService x) =>
{
    var rows = await q.GetItemSalesReportAsync(from, to, itemName, category, itemType);
    var file = x.Export(rows, "Item Sales Report");
    return Results.File(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "ItemSalesReport.xlsx");
});

// Item Sales Summary (Top Items)
app.MapGet("/api/reports/item-sales-summary", async (DateTime from, DateTime to, int? topN, ReportQueries q) =>
    Results.Ok(await q.GetItemSalesSummaryAsync(from, to, topN)));

// Discount Report
app.MapGet("/api/reports/discount", async (DateTime from, DateTime to, string? discountType, string? appliedBy, ReportQueries q) =>
    Results.Ok(await q.GetDiscountReportAsync(from, to, discountType, appliedBy)));

app.MapGet("/api/reports/discount/export", async (DateTime from, DateTime to, string? discountType, string? appliedBy, ReportQueries q, ExcelExportService x) =>
{
    var rows = await q.GetDiscountReportAsync(from, to, discountType, appliedBy);
    var file = x.Export(rows, "Discount Report");
    return Results.File(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "DiscountReport.xlsx");
});

// Discount Summary
app.MapGet("/api/reports/discount-summary", async (DateTime from, DateTime to, ReportQueries q) =>
    Results.Ok(await q.GetDiscountSummaryAsync(from, to)));

// Customer Report
app.MapGet("/api/reports/customers", async (DateTime from, DateTime to, string? customerName, int? minVisits, ReportQueries q) =>
    Results.Ok(await q.GetCustomerReportAsync(from, to, customerName, minVisits)));

app.MapGet("/api/reports/customers/export", async (DateTime from, DateTime to, string? customerName, int? minVisits, ReportQueries q, ExcelExportService x) =>
{
    var rows = await q.GetCustomerReportAsync(from, to, customerName, minVisits);
    var file = x.Export(rows, "Customer Report");
    return Results.File(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "CustomerReport.xlsx");
});

// Vendor Report
app.MapGet("/api/reports/vendors", async (DateTime from, DateTime to, ReportQueries q) =>
    Results.Ok(await q.GetVendorSummaryAsync(from, to)));

// IRD Daily Summary
app.MapGet("/api/reports/ird-daily-summary", async (string from, string to, ReportQueries q) =>
    Results.Ok(await q.GetIRDDailySummaryAsync(from, to)));

// ==================== BACKUP & RESTORE ENDPOINTS ====================

// Create manual backup
app.MapPost("/api/backup/create", async (string? notes, BackupService backup) =>
    Results.Ok(await backup.CreateFullBackupAsync("Manual", notes)));

// Get available backups
app.MapGet("/api/backup/list", (int? limit, BackupService backup) =>
    Results.Ok(backup.GetAvailableBackups(limit)));

// Get backup statistics
app.MapGet("/api/backup/statistics", (BackupService backup) =>
    Results.Ok(backup.GetBackupStatistics()));

// Restore from backup
app.MapPost("/api/backup/restore", async (RestoreRequest request, BackupService backup) =>
    Results.Ok(await backup.RestoreFromBackupAsync(request)));

// ==================== SYSTEM MONITORING ENDPOINTS ====================

// Get current health status
app.MapGet("/api/monitoring/health", (SystemMonitoringService monitoring) =>
    Results.Ok(monitoring.GetCurrentHealthStatus()));

// Get crash history
app.MapGet("/api/monitoring/crashes", (int? limit, SystemMonitoringService monitoring) =>
    Results.Ok(monitoring.GetCrashHistory(limit)));

// Get audit logs
app.MapGet("/api/monitoring/audit", (DateTime? from, DateTime? to, int? limit, SystemMonitoringService monitoring) =>
    Results.Ok(monitoring.GetAuditLogs(from, to, limit)));

// Manual health check
app.MapGet("/api/monitoring/check", async (SystemMonitoringService monitoring) =>
    Results.Ok(await monitoring.PerformManualHealthCheck()));

// Log custom audit entry
app.MapPost("/api/monitoring/audit", (string userId, string action, string entityType, string? entityId, bool success, string? errorMessage, SystemMonitoringService monitoring) =>
{
    monitoring.LogAudit(userId, action, entityType, entityId, success, errorMessage);
    return Results.Ok(new { logged = true });
});

app.Run();

static string? Nullable(Microsoft.Extensions.Primitives.StringValues v) => v.ToString() is { Length: > 0 } s ? s : null;
static decimal? DecimalOrNull(Microsoft.Extensions.Primitives.StringValues v) => decimal.TryParse(v, out var d) ? d : null;

record EmailRequest(string ReportType, string ToEmail, DateTime From, DateTime To,
    string? FromBS, string? ToBS, string? Item, string? CostCenter, string? Unit, string? Table, string? PaymentMode);
