using Microsoft.Extensions.Hosting;
using ReportingApi.Services;

var builder = WebApplication.CreateBuilder(args);
builder.Host.UseWindowsService(); // same deploy pattern as IRD-Sync (NSSM)

builder.Services.AddSingleton<ReportQueries>();
builder.Services.AddSingleton<ExcelExportService>();
builder.Services.AddSingleton<EmailService>();
builder.Services.AddCors(o => o.AddDefaultPolicy(p => p.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

var app = builder.Build();
app.UseCors();
app.UseDefaultFiles();
app.UseStaticFiles(); // wwwroot/index.html - the whole UI, no build step

// ---- 1) IRD Nepal Sales Book (wraps existing usp_ro_GetSalesBook) ----
// from/to are BS date strings e.g. 2082.04.01 - matches what the proc expects
app.MapGet("/api/reports/ird-sales-book", async (string from, string to, ReportQueries q, ExcelExportService x) =>
{
    var rows = await q.GetIrdSalesBookAsync(from, to);
    var file = x.Export(rows, "Sales Book");
    return Results.File(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "IRD_SalesBook.xlsx");
});

// ---- 2) IRD Nepal Sales Return Book (wraps existing usp_ro_GetReturnedSalesBook) ----
app.MapGet("/api/reports/ird-sales-return-book", async (string from, string to, ReportQueries q, ExcelExportService x) =>
{
    var rows = await q.GetIrdSalesReturnBookAsync(from, to);
    var file = x.Export(rows, "Sales Return Book");
    return Results.File(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "IRD_SalesReturnBook.xlsx");
});

// ---- 3) Materialized sales report (wraps existing usp_MaterializedReportView) ----
app.MapGet("/api/reports/materialized", async (DateTime from, DateTime to, int? valid, string? paymentMode, ReportQueries q) =>
    Results.Ok(await q.GetMaterializedSalesReportAsync(from, to, valid ?? -1, paymentMode)));

app.MapGet("/api/reports/materialized/export", async (DateTime from, DateTime to, int? valid, string? paymentMode, ReportQueries q, ExcelExportService x) =>
{
    var rows = await q.GetMaterializedSalesReportAsync(from, to, valid ?? -1, paymentMode);
    var file = x.Export(rows, "Sales Report");
    return Results.File(file, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "MaterializedSalesReport.xlsx");
});

// ---- 4) Filterable sales report - item/unit/rate/cost-center/table/payment-mode ----
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

// ---- 5) Email any of the above to the owner ----
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

app.Run();

static string? Nullable(Microsoft.Extensions.Primitives.StringValues v) => v.ToString() is { Length: > 0 } s ? s : null;
static decimal? DecimalOrNull(Microsoft.Extensions.Primitives.StringValues v) => decimal.TryParse(v, out var d) ? d : null;

record EmailRequest(string ReportType, string ToEmail, DateTime From, DateTime To,
    string? FromBS, string? ToBS, string? Item, string? CostCenter, string? Unit, string? Table, string? PaymentMode);
