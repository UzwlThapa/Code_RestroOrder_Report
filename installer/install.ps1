<#
============================================================
 RestroOrder Reports — one-shot installer
 Run this ON THE SAME SERVER as RestroOrder (elevated PowerShell).

 What it does, in order:
   1. Auto-detects RestroOrder's own SQL connection string by
      reading SageFrame\connectionstring.config (or web.config)
      from the RestroOrder install folder — same server, same DB,
      zero typing needed in the common case.
   2. Falls back to prompting for Server/Database/User/Password
      if it can't find or parse that file, defaulting the
      username/password to sa / saa (RestroOrder's own standing
      default, confirmed from your real client configs).
   3. Creates the read-only ro_reports_reader login + the new
      reporting proc (sql/01, sql/02, sql/03) using the ADMIN
      credentials just discovered/entered — the app itself will
      run as the low-privilege reader afterwards, never as sa.
   4. Publishes the .NET 8 API as a self-contained exe.
   5. Writes appsettings.json with the reporting connection string.
   6. Installs + starts it as a Windows Service via NSSM (same
      pattern as your existing IRD-Sync service).
   7. Opens the report UI in the default browser.

 Usage:
   .\install.ps1
   .\install.ps1 -RestroOrderPath "D:\inetpub\wwwroot\RestroOrder"
   .\install.ps1 -SqlServer "DESKTOP-9VVHFMK" -SqlDatabase "ProdCityescapeRO_IRD" -SqlUser "sa" -SqlPassword "saa"
============================================================
#>

param(
    [string]$RestroOrderPath,
    [string]$SqlServer,
    [string]$SqlDatabase,
    [string]$SqlUser,
    [string]$SqlPassword,
    [string]$InstallDir = "C:\Apps\RestroReports",
    [int]$Port = 5080
)

$ErrorActionPreference = "Stop"
function Say($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Warn($msg) { Write-Host "!!  $msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------
# 1) AUTO-DETECT RestroOrder's connection string
# ---------------------------------------------------------------
function Find-RestroOrderConfig {
    param([string]$hintPath)

    $candidates = @()
    if ($hintPath) { $candidates += $hintPath }

    # Common IIS install roots — searched if no hint given
    $candidates += @(
        "C:\inetpub\wwwroot\RestroOrder",
        "D:\inetpub\wwwroot\RestroOrder",
        "C:\inetpub\wwwroot"
    )

    foreach ($base in $candidates) {
        if (-not (Test-Path $base)) { continue }
        $found = Get-ChildItem -Path $base -Recurse -Filter "connectionstring.config" -ErrorAction SilentlyContinue |
                 Select-Object -First 1
        if ($found) { return $found.FullName }

        $webConfig = Get-ChildItem -Path $base -Recurse -Filter "web.config" -ErrorAction SilentlyContinue |
                     Where-Object { (Get-Content $_.FullName -Raw) -match "SageFrameConnectionString" } |
                     Select-Object -First 1
        if ($webConfig) { return $webConfig.FullName }
    }
    return $null
}

function Parse-ConnectionString {
    param([string]$configPath)
    $xml = [xml](Get-Content $configPath -Raw)
    $connStr = $xml.SelectSingleNode("//connectionStrings/add[@name='SageFrameConnectionString']") |
               ForEach-Object { $_.connectionString }
    # Some configs comment out the real entry and leave a placeholder — grab the last <add> if XML parse misses it
    if (-not $connStr) {
        $raw = Get-Content $configPath -Raw
        if ($raw -match 'connectionString="([^"]+)"\s+name="SageFrameConnectionString"') {
            $connStr = $matches[1]
        }
    }
    if (-not $connStr) { return $null }

    $parts = @{}
    foreach ($pair in $connStr -split ';') {
        if ($pair -match '^\s*([^=]+)=(.*)$') {
            $parts[$matches[1].Trim().ToLower()] = $matches[2].Trim()
        }
    }
    return @{
        Server   = $(if ($parts.ContainsKey('server')) { $parts['server'] } else { $parts['data source'] })
        Database = $(if ($parts.ContainsKey('initial catalog')) { $parts['initial catalog'] } else { $parts['database'] })
        User     = $(if ($parts.ContainsKey('user id')) { $parts['user id'] } else { $parts['uid'] })
        Password = $(if ($parts.ContainsKey('password')) { $parts['password'] } else { $parts['pwd'] })
    }
}

if (-not ($SqlServer -and $SqlDatabase -and $SqlUser -and $SqlPassword)) {
    Say "Looking for RestroOrder's own connection string..."
    $configPath = Find-RestroOrderConfig -hintPath $RestroOrderPath

    if ($configPath) {
        Say "Found config: $configPath"
        $detected = Parse-ConnectionString -configPath $configPath
        if ($detected -and $detected.Server -and $detected.Database) {
            Say "Auto-detected: Server=$($detected.Server)  Database=$($detected.Database)  User=$($detected.User)"
            if (-not $SqlServer)   { $SqlServer   = $detected.Server }
            if (-not $SqlDatabase) { $SqlDatabase = $detected.Database }
            if (-not $SqlUser)     { $SqlUser     = $detected.User }
            if (-not $SqlPassword) { $SqlPassword = $detected.Password }
        }
    } else {
        Warn "Could not auto-locate RestroOrder's config file."
    }
}

# Prompt for anything still missing, defaulting user/password to RestroOrder's own standing default
if (-not $SqlServer)   { $SqlServer   = Read-Host "SQL Server name (e.g. localhost, DESKTOP-XXXX)" }
if (-not $SqlDatabase) { $SqlDatabase = Read-Host "RestroOrder database name (e.g. ProdCityescapeRO_IRD)" }
if (-not $SqlUser)     { $u = Read-Host "SQL username [sa]"; $SqlUser = $(if ($u) { $u } else { "sa" }) }
if (-not $SqlPassword) { $p = Read-Host "SQL password [saa]" -AsSecureString
                          $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($p))
                          $SqlPassword = $(if ($plain) { $plain } else { "saa" }) }

Say "Using: Server=$SqlServer  Database=$SqlDatabase  User=$SqlUser"

$adminConnStr = "Server=$SqlServer;Database=$SqlDatabase;User Id=$SqlUser;Password=$SqlPassword;TrustServerCertificate=True;"

# ---------------------------------------------------------------
# 2) Run SQL setup (creates ro_reports_reader + reporting proc)
# ---------------------------------------------------------------
Say "Running SQL setup scripts against $SqlDatabase..."
$sqlDir = Join-Path $PSScriptRoot "..\sql"
foreach ($script in @("01_setup_readonly_login.sql", "02_reporting_objects.sql", "03_supporting_indexes.sql")) {
    $path = Join-Path $sqlDir $script
    Say "  -> $script"
    sqlcmd -S $SqlServer -d $SqlDatabase -U $SqlUser -P $SqlPassword -i $path -b
    if ($LASTEXITCODE -ne 0) { throw "$script failed — see sqlcmd output above." }
}

# Reporting login password — generate one instead of using a fixed default
Add-Type -AssemblyName System.Web
$readerPassword = [System.Web.Security.Membership]::GeneratePassword(20, 4)
sqlcmd -S $SqlServer -d $SqlDatabase -U $SqlUser -P $SqlPassword -b -Q `
    "ALTER LOGIN ro_reports_reader WITH PASSWORD = '$readerPassword';"
if ($LASTEXITCODE -ne 0) { throw "Failed to set ro_reports_reader password." }

# ---------------------------------------------------------------
# 3) Publish the API
# ---------------------------------------------------------------
Say "Publishing the reporting API to $InstallDir ..."
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$srcDir = Join-Path $PSScriptRoot "..\src\ReportingApi"
dotnet publish $srcDir -c Release -r win-x64 --self-contained -o $InstallDir
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed — is the .NET 8 SDK installed?" }

# ---------------------------------------------------------------
# 4) Write appsettings.json with the low-privilege reader connection
# ---------------------------------------------------------------
Say "Writing appsettings.json..."
$appSettingsPath = Join-Path $InstallDir "appsettings.json"
$appSettings = Get-Content $appSettingsPath -Raw | ConvertFrom-Json
$appSettings.ConnectionStrings.RestroOrderReadOnly =
    "Server=$SqlServer;Database=$SqlDatabase;User Id=ro_reports_reader;Password=$readerPassword;TrustServerCertificate=True;"
$appSettings.Kestrel.Endpoints.Http.Url = "http://0.0.0.0:$Port"
$appSettings | ConvertTo-Json -Depth 10 | Set-Content $appSettingsPath

# ---------------------------------------------------------------
# 5) Install as a Windows Service via NSSM (same as IRD-Sync)
# ---------------------------------------------------------------
$nssm = Get-Command nssm.exe -ErrorAction SilentlyContinue
if (-not $nssm) {
    Warn "nssm.exe not found on PATH. Install it (same tool used for IRD-Sync) and re-run just this section:"
    Warn "  nssm install RestroReports `"$InstallDir\ReportingApi.exe`""
    Warn "  nssm start RestroReports"
} else {
    Say "Installing Windows Service 'RestroReports'..."
    & nssm install RestroReports "$InstallDir\ReportingApi.exe"
    & nssm start RestroReports
}

Start-Sleep -Seconds 2
Say "Done. Opening the report UI..."
Start-Process "http://localhost:$Port"
Say "Reporting login password (save this somewhere safe): $readerPassword"
