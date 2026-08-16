using System.Diagnostics;
using System.Runtime.InteropServices;
using Microsoft.Data.SqlClient;
using ReportingApi.Models;
using ReportingApi.Services.Backup;

namespace ReportingApi.Services.Monitoring;

/// <summary>
/// Enterprise System Monitoring & Crash Detection Service
/// - Real-time health monitoring
/// - Automatic crash detection and recovery
/// - Resource usage tracking (CPU, Memory, Disk)
/// - Database connectivity monitoring
/// - Auto-trigger emergency backups on anomalies
/// - Comprehensive audit logging
/// - Alert notifications for critical events
/// </summary>
public class SystemMonitoringService : IHostedService, IDisposable
{
    private readonly ILogger<SystemMonitoringService> _logger;
    private readonly IConfiguration _config;
    private readonly BackupService _backupService;
    private readonly string _connectionString;
    private Timer? _healthCheckTimer;
    private readonly List<CrashIncident> _crashHistory = new();
    private readonly List<AuditLog> _auditLogs = new();
    private SystemHealthStatus _currentStatus = new();
    private bool _isHealthy = true;
    private int _consecutiveFailures = 0;
    private const int MaxConsecutiveFailures = 3;

    // Events for integration
    public event EventHandler<CrashIncident>? OnCrashDetected;
    public event EventHandler<SystemHealthStatus>? OnHealthStatusChanged;
    public event EventHandler<string>? OnCriticalAlert;

    public SystemMonitoringService(
        ILogger<SystemMonitoringService> logger, 
        IConfiguration config,
        BackupService backupService)
    {
        _logger = logger;
        _config = config;
        _backupService = backupService;
        _connectionString = config.GetConnectionString("RestroOrderReadOnly") 
            ?? throw new InvalidOperationException("Missing connection string");
    }

    public Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("System Monitoring Service starting");
        
        var checkInterval = TimeSpan.Parse(_config["MonitoringSettings:CheckIntervalSeconds"] ?? "30");
        _healthCheckTimer = new Timer(PerformHealthCheck, null, TimeSpan.FromSeconds(5), checkInterval);
        
        // Log startup audit
        LogAudit("SYSTEM", "MONITORING_START", "System", null, true, null);
        
        return Task.CompletedTask;
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("System Monitoring Service stopping");
        _healthCheckTimer?.Change(Timeout.Infinite, Timeout.Infinite);
        
        LogAudit("SYSTEM", "MONITORING_STOP", "System", null, true, null);
        
        return Task.CompletedTask;
    }

    public void Dispose()
    {
        _healthCheckTimer?.Dispose();
    }

    /// <summary>
    /// Get current system health status
    /// </summary>
    public SystemHealthStatus GetCurrentHealthStatus() => _currentStatus;

    /// <summary>
    /// Get crash history
    /// </summary>
    public IEnumerable<CrashIncident> GetCrashHistory(int? limit = null)
    {
        var incidents = _crashHistory.OrderByDescending(i => i.DetectedAt);
        return limit.HasValue ? incidents.Take(limit.Value) : incidents;
    }

    /// <summary>
    /// Get audit logs
    /// </summary>
    public IEnumerable<AuditLog> GetAuditLogs(DateTime? from = null, DateTime? to = null, int? limit = null)
    {
        var logs = _auditLogs.OrderByDescending(l => l.Timestamp).AsEnumerable();
        
        if (from.HasValue)
            logs = logs.Where(l => l.Timestamp >= from.Value);
        if (to.HasValue)
            logs = logs.Where(l => l.Timestamp <= to.Value);
        
        return limit.HasValue ? logs.Take(limit.Value) : logs;
    }

    /// <summary>
    /// Manually trigger a health check
    /// </summary>
    public async Task<SystemHealthStatus> PerformManualHealthCheck()
    {
        await Task.Run(() => PerformHealthCheck(null));
        return _currentStatus;
    }

    /// <summary>
    /// Log an audit entry
    /// </summary>
    public void LogAudit(string userId, string action, string entityType, string? entityId, bool success, string? errorMessage)
    {
        var log = new AuditLog
        {
            Timestamp = DateTime.Now,
            UserId = userId,
            Action = action,
            EntityType = entityType,
            EntityId = entityId,
            IPAddress = "127.0.0.1", // Could be enhanced with real IP
            MachineName = Environment.MachineName,
            Success = success,
            ErrorMessage = errorMessage
        };

        lock (_auditLogs)
        {
            _auditLogs.Add(log);
            if (_auditLogs.Count > 10000) // Keep last 10k entries in memory
                _auditLogs.RemoveRange(0, _auditLogs.Count - 10000);
        }
    }

    #region Private Methods

    private void PerformHealthCheck(object? state)
    {
        try
        {
            var status = new SystemHealthStatus
            {
                CheckedAt = DateTime.Now,
                IsHealthy = true,
                Warnings = new List<string>(),
                Errors = new List<string>()
            };

            // Check CPU usage
            status.CPULoadPercent = GetCPULoad();
            if (status.CPULoadPercent > 90)
            {
                status.Warnings.Add($"High CPU usage: {status.CPULoadPercent:F1}%");
                status.IsHealthy = false;
            }

            // Check Memory usage
            status.MemoryLoadPercent = GC.GetTotalMemory(false) / (double)Environment.WorkingSet * 100;
            if (status.MemoryLoadPercent > 85)
            {
                status.Warnings.Add($"High memory pressure detected");
                status.IsHealthy = false;
            }

            // Check Disk space
            var driveInfo = new DriveInfo(Path.GetPathRoot(_backupService.GetType().Assembly.Location) ?? "C:\\");
            status.AvailableDiskSpaceBytes = driveInfo.AvailableFreeSpace;
            if (driveInfo.AvailableFreeSpace < 1L * 1024 * 1024 * 1024) // Less than 1GB
            {
                status.Warnings.Add($"Low disk space: {driveInfo.AvailableFreeSpace / (1024 * 1024):F0} MB available");
                status.IsHealthy = false;
            }

            // Check Database connectivity
            try
            {
                using var conn = new SqlConnection(_connectionString);
                conn.Open();
                status.DatabaseConnected = true;
                
                // Count active connections
                var countSql = @"SELECT COUNT(*) FROM sys.dm_exec_connections WHERE session_id > 50";
                status.ActiveConnections = conn.QueryFirstOrDefault<int>(countSql);
            }
            catch (Exception ex)
            {
                status.DatabaseConnected = false;
                status.Errors.Add($"Database connection failed: {ex.Message}");
                status.IsHealthy = false;
            }

            // Check backup status
            var backupStats = _backupService.GetBackupStatistics();
            status.LastSuccessfulBackup = backupStats["LastBackupTime"] as DateTime?;
            status.PendingBackupCount = (int)(backupStats["FailedBackups"] ?? 0);
            
            if (status.LastSuccessfulBackup.HasValue && 
                DateTime.Now - status.LastSuccessfulBackup.Value > TimeSpan.FromHours(25))
            {
                status.Warnings.Add("No successful backup in the last 25 hours");
            }

            // Update consecutive failure counter
            if (!status.IsHealthy)
            {
                _consecutiveFailures++;
                if (_consecutiveFailures >= MaxConsecutiveFailures)
                {
                    HandlePotentialCrash(status);
                }
            }
            else
            {
                _consecutiveFailures = 0;
            }

            // Detect status change
            if (_isHealthy != status.IsHealthy)
            {
                _isHealthy = status.IsHealthy;
                OnHealthStatusChanged?.Invoke(this, status);
                
                if (!status.IsHealthy)
                {
                    OnCriticalAlert?.Invoke(this, 
                        $"System health degraded: {string.Join("; ", status.Errors)} {string.Join("; ", status.Warnings)}");
                }
            }

            _currentStatus = status;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during health check");
            _consecutiveFailures++;
        }
    }

    private void HandlePotentialCrash(SystemHealthStatus status)
    {
        var incident = new CrashIncident
        {
            IncidentId = Guid.NewGuid(),
            OccurredAt = DateTime.Now,
            DetectedAt = DateTime.Now,
            CrashType = "SystemDegradation",
            ErrorMessage = string.Join("; ", status.Errors),
            AffectedComponent = "SystemMonitor",
            AutoRecovered = false,
            DataIntegrityCompromised = !status.DatabaseConnected,
            Severity = "High",
            AffectedTables = new List<string> { "RO_SalesMaster", "RO_SalesDetail" }
        };

        _logger.LogCritical("POTENTIAL CRASH DETECTED: {Error}", incident.ErrorMessage);
        
        lock (_crashHistory)
        {
            _crashHistory.Add(incident);
            if (_crashHistory.Count > 100)
                _crashHistory.RemoveAt(0);
        }

        OnCrashDetected?.Invoke(this, incident);

        // Trigger emergency backup
        _ = Task.Run(async () =>
        {
            try
            {
                await _backupService.CreateEmergencyBackupAsync();
                incident.RelatedBackupId = _backupService.GetAvailableBackups(1).FirstOrDefault()?.BackupId;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Emergency backup failed during crash handling");
            }
        });

        // Send alert
        OnCriticalAlert?.Invoke(this, 
            $"CRITICAL: System crash detected. {incident.ErrorMessage}. Emergency backup initiated.");
    }

    private double GetCPULoad()
    {
        try
        {
            // Use PerformanceCounter on Windows
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                using var cpuCounter = new PerformanceCounter("Processor", "% Processor Time", "_Total");
                cpuCounter.NextValue(); // First call returns garbage
                Thread.Sleep(500);
                return cpuCounter.NextValue();
            }
            
            // Fallback for non-Windows (simplified)
            return Process.GetCurrentProcess().TotalProcessorTime.TotalMilliseconds / 
                   (Environment.ProcessorCount * Stopwatch.GetTimestamp() / (double)Stopwatch.Frequency) * 100;
        }
        catch
        {
            return -1; // Unable to measure
        }
    }

    #endregion
}
