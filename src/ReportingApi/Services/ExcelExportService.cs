using ClosedXML.Excel;

namespace ReportingApi.Services;

public class ExcelExportService
{
    /// <summary>
    /// Turns any IEnumerable of dynamic rows (from Dapper) into an .xlsx stream.
    /// Column order/names come straight from the SQL view, so the Tally Export
    /// sheet always matches Final_Tally_Export_Format_All_Statuses.xlsx exactly
    /// as long as the view's column aliases match that file.
    /// </summary>
    public byte[] Export(IEnumerable<dynamic> rows, string sheetName)
    {
        using var wb = new XLWorkbook();
        var ws = wb.Worksheets.Add(sheetName);

        var rowList = rows.Select(r => (IDictionary<string, object>)r).ToList();
        if (rowList.Count == 0)
        {
            ws.Cell(1, 1).Value = "No rows for the selected filters.";
            using var emptyStream = new MemoryStream();
            wb.SaveAs(emptyStream);
            return emptyStream.ToArray();
        }

        var columns = rowList[0].Keys.ToList();
        for (int c = 0; c < columns.Count; c++)
        {
            ws.Cell(1, c + 1).Value = columns[c];
            ws.Cell(1, c + 1).Style.Font.Bold = true;
        }

        for (int r = 0; r < rowList.Count; r++)
        {
            for (int c = 0; c < columns.Count; c++)
            {
                var val = rowList[r][columns[c]];
                ws.Cell(r + 2, c + 1).Value = val switch
                {
                    null => XLCellValue.FromObject(string.Empty),
                    DateTime dt => XLCellValue.FromObject(dt),
                    decimal or double or int or long => XLCellValue.FromObject(val),
                    _ => XLCellValue.FromObject(val.ToString())
                };
            }
        }

        ws.Columns().AdjustToContents();

        using var stream = new MemoryStream();
        wb.SaveAs(stream);
        return stream.ToArray();
    }
}
