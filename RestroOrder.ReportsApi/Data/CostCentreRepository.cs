using Dapper;
using Microsoft.Data.SqlClient;
using RestroOrder.ReportsApi.Models;

namespace RestroOrder.ReportsApi.Data;

public class CostCentreRepository
{
    private readonly string _connString;

    public CostCentreRepository(IConfiguration config)
    {
        _connString = config.GetConnectionString("RestroOrderDb")
            ?? throw new InvalidOperationException("ConnectionStrings:RestroOrderDb missing in appsettings.json");
    }

    public async Task<IEnumerable<CostCentreRow>> GetAsync(CostCentreFilter filter)
    {
        // WITH (NOLOCK): dirty-read risk accepted here deliberately - this is a
        // read-only reporting endpoint against a live POS/purchase DB. A row
        // mid-transaction (e.g. GoodsReceived being posted) may show up half-committed
        // or a row may be skipped/duplicated during a page split. Acceptable for
        // a purchase report refreshed on demand; NOT acceptable if this report
        // ever feeds financial reconciliation without a re-run against committed data.
        //
        // NOTE: RO_GoodsReceivedMain's branch column is UNCONFIRMED - it did not
        // appear in the schema dump you shared. Placeholder below assumes
        // gm.BranchName exists (nvarchar). If it doesn't, branch likely lives on
        // a separate Branch/Outlet master table joined via gm.BranchId - swap the
        // WHERE/SELECT accordingly once you confirm. Run:
        //   SELECT name FROM sys.columns WHERE object_id = OBJECT_ID('RO_GoodsReceivedMain');
        const string sql = @"
SELECT
    CONVERT(varchar(10), gm.PostedOn, 103)        AS [Date],
    gm.InvoiceNo                                   AS InvoiceNo,
    gm.VendorName                                  AS Supplier,
    id.ITName                                      AS [Description],
    ccg.GroupName                                  AS CostCentre,
    gm.BranchName                                  AS Branch,        -- UNCONFIRMED COLUMN, see note above
    pd.Qty                                         AS Qty,
    gd.Rate                                        AS UnitRate,
    gd.Total                                       AS TotalAmount,
    gm.Status                                      AS Status         -- UNCONFIRMED COLUMN name/values, map to 'Approved'/'Pending'/'Rejected' as needed
FROM RO_GoodsReceivedDetls gd WITH (NOLOCK)
JOIN RO_GoodsReceivedMain gm  WITH (NOLOCK) ON gd.GMId = gm.GMId
JOIN ROI_PurchaseDetails pd   WITH (NOLOCK) ON gd.PDId = pd.PurchaseDetailsID
JOIN ROI_ItemDetails id       WITH (NOLOCK) ON pd.ItemID = id.ITId
JOIN CostCenterInfo cci       WITH (NOLOCK) ON id.ItemCostCentreID = cci.CostCenterId
JOIN RO_CostCenterGroup ccg   WITH (NOLOCK) ON cci.GroupId = ccg.GroupId
WHERE gm.PostedOn >= @FromDate
  AND gm.PostedOn <  DATEADD(DAY, 1, @ToDate)   -- half-open range: avoids missing same-day rows with a time component
  AND ccg.IsActive = 1
  AND (@Branch IS NULL OR gm.BranchName = @Branch)
  AND (@HasCostCentreFilter = 0 OR ccg.GroupName IN @CostCentres)
ORDER BY gm.PostedOn DESC, gm.InvoiceNo;";

        var hasCcFilter = filter.CostCentres is { Count: > 0 };

        using var conn = new SqlConnection(_connString);
        return await conn.QueryAsync<CostCentreRow>(sql, new
        {
            filter.FromDate,
            filter.ToDate,
            Branch = string.IsNullOrWhiteSpace(filter.Branch) || filter.Branch == "all" ? null : filter.Branch,
            HasCostCentreFilter = hasCcFilter ? 1 : 0,
            // Dapper expands IN @list safely (parameterized, not string concat) -
            // but errors on an empty list, hence the HasCostCentreFilter guard above.
            CostCentres = hasCcFilter ? filter.CostCentres : new List<string> { string.Empty }
        });
    }
}
