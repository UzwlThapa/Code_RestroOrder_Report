using Microsoft.Extensions.Hosting;
using ReportingApi.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Host.UseWindowsService();

// Register core services
builder.Services.AddSingleton<ReportQueries>();
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

var app = builder.Build();
app.UseCors();
app.UseDefaultFiles();
app.UseStaticFiles();

// ==================== CORE REPORT ENDPOINTS ====================

// 1. IRD Nepal Sales Book - Tax Compliance Report
app.MapGet("/api/reports/ird-sales-book", async (string from, string to, ReportQueries q) =>
{
    var rows = await q.GetIrdSalesBookAsync(from, to);
    return Results.Ok(rows);
});

// 2. IRD Nepal Sales Return Book - Tax Compliance Report  
app.MapGet("/api/reports/ird-sales-return-book", async (string from, string to, ReportQueries q) =>
{
    var rows = await q.GetIrdSalesReturnBookAsync(from, to);
    return Results.Ok(rows);
});

// 3. Materialized View Report - Filtered Sales Report
app.MapGet("/api/reports/materialized", async (DateTime from, DateTime to, int? valid, string? paymentMode, ReportQueries q) =>
    Results.Ok(await q.GetMaterializedSalesReportAsync(from, to, valid ?? -1, paymentMode)));

// 4. Item Sales Report - Menu Engineering (Top/Least/Non-Selling)
app.MapGet("/api/reports/item-sales", async (DateTime from, DateTime to, string? category, string? branch, ReportQueries q) =>
    Results.Ok(await q.GetItemSalesReportAsync(from, to, category, branch)));

// 5. Cost Centre Purchase Report - Kitchen/Bar/Bakery etc.
app.MapGet("/api/reports/cost-centre", async (DateTime from, DateTime to, string? costCentre, string? branch, ReportQueries q) =>
    Results.Ok(await q.GetCostCentrePurchaseReportAsync(from, to, costCentre, branch)));

app.Run();
