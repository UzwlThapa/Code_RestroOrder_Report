using RestroOrder.ReportsApi.Data;

var builder = WebApplication.CreateBuilder(args);

// Windows Event Log logging - so failures show up in Event Viewer > Application,
// same place you already check for SageFrame issues. Only meaningful when
// running as an actual Windows Service / under IIS on a real server - EventLog
// provider is a no-op stub-equivalent on non-Windows (fine for local dev on WSL/mac).
if (OperatingSystem.IsWindows())
{
    builder.Logging.AddEventLog(settings =>
    {
        settings.SourceName = "RestroOrder.ReportsApi";
        // NOTE: the EventLog *source* must exist before first write, or logging
        // throws. Create it once via elevated PowerShell on the target server:
        //   New-EventLog -LogName Application -Source "RestroOrder.ReportsApi"
    });
}

// Next.js dev server / prod build calls this API cross-origin (different port,
// or different host entirely if Next runs on its own IIS site/reverse proxy).
// Tighten AllowedOrigins in appsettings per environment - do NOT ship AllowAnyOrigin.
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>()
    ?? new[] { "http://localhost:3000" };

builder.Services.AddCors(options =>
{
    options.AddPolicy("ReportsUiPolicy", policy =>
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod());
});

builder.Services.AddControllers();
builder.Services.AddScoped<CostCentreRepository>();
builder.Services.AddEndpointsApiExplorer();

var app = builder.Build();

app.UseCors("ReportsUiPolicy");
app.UseAuthorization();
app.MapControllers();

// Cheap health check for the zero-downtime deploy script (see README) to poll
// against localhost before swapping the app pool / cutting traffic over.
app.MapGet("/health", () => Results.Ok(new { status = "ok", time = DateTime.UtcNow }));

app.Run();
