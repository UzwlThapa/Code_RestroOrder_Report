using Microsoft.AspNetCore.Mvc;
using RestroOrder.ReportsApi.Data;
using RestroOrder.ReportsApi.Models;

namespace RestroOrder.ReportsApi.Controllers;

[ApiController]
[Route("api/reports")]
public class ReportsController : ControllerBase
{
    private readonly CostCentreRepository _costCentreRepo;
    private readonly ILogger<ReportsController> _logger;

    public ReportsController(CostCentreRepository costCentreRepo, ILogger<ReportsController> logger)
    {
        _costCentreRepo = costCentreRepo;
        _logger = logger;
    }

    // GET /api/reports/cost-centre?fromDate=2026-09-01&toDate=2026-09-10&branch=Thamel&costCentres=Kitchen,Bar
    [HttpGet("cost-centre")]
    public async Task<IActionResult> GetCostCentre(
        [FromQuery] DateTime fromDate,
        [FromQuery] DateTime toDate,
        [FromQuery] string? branch,
        [FromQuery] string? costCentres)
    {
        if (toDate < fromDate)
            return BadRequest("toDate must be >= fromDate.");

        if ((toDate - fromDate).TotalDays > 366)
            return BadRequest("Range too large - max 366 days per request. NOLOCK scans get expensive on multi-year pulls with no covering index (see README).");

        var filter = new CostCentreFilter
        {
            FromDate = fromDate,
            ToDate = toDate,
            Branch = branch,
            CostCentres = string.IsNullOrWhiteSpace(costCentres)
                ? null
                : costCentres.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).ToList()
        };

        try
        {
            var rows = await _costCentreRepo.GetAsync(filter);
            return Ok(rows);
        }
        catch (Exception ex)
        {
            // Log full detail server-side (Event Viewer via ILogger -> EventLog provider once configured),
            // return generic message to client - don't leak connection string/SQL detail to the browser.
            _logger.LogError(ex, "cost-centre report query failed for range {From}-{To}", fromDate, toDate);
            return StatusCode(500, "Report query failed. Check server Event Log / application logs.");
        }
    }
}
