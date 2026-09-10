namespace RestroOrder.ReportsApi.Models;

// Property names are camelCase-serialized to match reportData.ts's
// COST_CENTRE_DATA column keys exactly: date, invoiceNo, supplier,
// description, costCentre, branch, qty, unitRate, totalAmount, status.
// Do not rename these without updating REPORT_CONFIGS['cost-centre'].columns
// in the Next.js project - the ReportTable renders by key, not by index.
public class CostCentreRow
{
    public string Date { get; set; } = string.Empty;          // formatted dd/MM/yyyy, formatted server-side to keep UI dumb
    public string InvoiceNo { get; set; } = string.Empty;
    public string Supplier { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string CostCentre { get; set; } = string.Empty;
    public string Branch { get; set; } = string.Empty;
    public decimal Qty { get; set; }
    public decimal UnitRate { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class CostCentreFilter
{
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public string? Branch { get; set; }          // null/"all" = no filter
    public List<string>? CostCentres { get; set; } // empty/null = "All" per FilterState.costCentres
}
