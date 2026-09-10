using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;

namespace ReportingApi.Services;

/// <summary>
/// Report queries for RestroOrder Reports - Nepal IRD 2026 Standard
/// Supports 5 core reports:
/// 1. IRD Sales Book (Tax Compliance)
/// 2. IRD Sales Return Book (Tax Compliance)
/// 3. Materialized View Report (Filtered Sales)
/// 4. Item Sales Report (Menu Engineering - Top/Least/Non-Selling)
/// 5. Cost Centre Purchase Report (Kitchen/Bar/Bakery etc.)
/// </summary>
public class ReportQueries
{
    private readonly string _connectionString;

    public ReportQueries(IConfiguration config)
    {
        _connectionString = config.GetConnectionString("RestroOrderReadOnly")
            ?? throw new InvalidOperationException("Missing ConnectionStrings:RestroOrderReadOnly");
    }

    private SqlConnection Open() => new(_connectionString);

    /// <summary>
    /// IRD Nepal Sales Book. NOTE: FromDate/ToDate are BS (Bikram Sambat)
    /// calendar date strings, dot-separated, e.g. "2082.04.01" — matching
    /// exactly what usp_ro_GetSalesBook expects.
    /// </summary>
    public async Task<IEnumerable<dynamic>> GetIrdSalesBookAsync(string fromDateBS, string toDateBS)
    {
        using var conn = Open();
        return await conn.QueryAsync(
            "usp_ro_GetSalesBook",
            new { FromDate = fromDateBS, ToDate = toDateBS },
            commandType: CommandType.StoredProcedure, commandTimeout: 60);
    }

    /// <summary>IRD Nepal Sales Return Book. Same BS date-string format as above.</summary>
    public async Task<IEnumerable<dynamic>> GetIrdSalesReturnBookAsync(string fromDateBS, string toDateBS)
    {
        using var conn = Open();
        return await conn.QueryAsync(
            "usp_ro_GetReturnedSalesBook",
            new { FromDate = fromDateBS, ToDate = toDateBS },
            commandType: CommandType.StoredProcedure, commandTimeout: 60);
    }

    /// <summary>
    /// The "materialized view" report — bill no, customer, PAN, taxable
    /// amount, discount, service charge, VAT, payment modes, print status.
    /// @Valid: -1 = both archived and active, 0 = active only, 1 = archived only.
    /// </summary>
    public async Task<IEnumerable<dynamic>> GetMaterializedSalesReportAsync(
        DateTime from, DateTime to, int valid = -1, string? paymentMode = null)
    {
        using var conn = Open();
        return await conn.QueryAsync(
            "usp_MaterializedReportView",
            new { StartDate = from.Date, EndDate = to.Date, Valid = valid, PaymentMode = paymentMode ?? "" },
            commandType: CommandType.StoredProcedure, commandTimeout: 60);
    }

    /// <summary>
    /// Item Sales Report - Menu Engineering Analysis
    /// Returns item-wise sales with category classification (Top/Least/Dead selling)
    /// Supports filtering by cost center (category) and branch
    /// </summary>
    public async Task<IEnumerable<dynamic>> GetItemSalesReportAsync(
        DateTime from, DateTime to, string? category, string? branch)
    {
        using var conn = Open();
        return await conn.QueryAsync(
            "usp_RO_ItemSalesReport",
            new
            {
                FromDate = from.Date,
                ToDate = to.Date,
                Category = category,
                Branch = branch
            },
            commandType: CommandType.StoredProcedure, commandTimeout: 60);
    }

    /// <summary>
    /// Cost Centre Purchase Report
    /// Returns purchase orders grouped by cost centre (Kitchen, Bar, Bakery, Housekeeping etc.)
    /// Supports filtering by specific cost centre and branch
    /// </summary>
    public async Task<IEnumerable<dynamic>> GetCostCentrePurchaseReportAsync(
        DateTime from, DateTime to, string? costCentre, string? branch)
    {
        using var conn = Open();
        return await conn.QueryAsync(
            "usp_RO_CostCentrePurchaseReport",
            new
            {
                FromDate = from.Date,
                ToDate = to.Date,
                CostCentre = costCentre,
                Branch = branch
            },
            commandType: CommandType.StoredProcedure, commandTimeout: 60);
    }
}
