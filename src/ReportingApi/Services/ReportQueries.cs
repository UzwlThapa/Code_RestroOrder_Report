using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;

namespace ReportingApi.Services;

/// <summary>
/// Every method here EXECs an existing, already-correct RestroOrder stored
/// procedure — usp_ro_GetSalesBook, usp_ro_GetReturnedSalesBook, and
/// usp_MaterializedReportView were already built (by the IRD-Sync/CBMS
/// pipeline) and are not reimplemented. Only
/// usp_RO_Reports_FilterableSalesReport is new (see sql/02_reporting_objects.sql).
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
    /// exactly what usp_ro_GetSalesBook expects (it does a string BETWEEN
    /// on invoice_date, not a real DATETIME comparison). Pass through
    /// whatever format the existing app already uses for this proc.
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

    /// <summary>General filterable sales report — item/unit/rate/cost-center/table/payment-mode wise.</summary>
    public async Task<IEnumerable<dynamic>> GetFilterableSalesReportAsync(
        DateTime from, DateTime to, string? item, string? costCenter, string? unit,
        decimal? rateMin, decimal? rateMax, string? table, string? paymentMode)
    {
        using var conn = Open();
        return await conn.QueryAsync(
            "usp_RO_Reports_FilterableSalesReport",
            new
            {
                From = from.Date,
                To = to.Date,
                Item = item,
                CostCenter = costCenter,
                Unit = unit,
                RateMin = rateMin,
                RateMax = rateMax,
                Table = table,
                PaymentMode = paymentMode
            },
            commandType: CommandType.StoredProcedure, commandTimeout: 60);
    }
}
