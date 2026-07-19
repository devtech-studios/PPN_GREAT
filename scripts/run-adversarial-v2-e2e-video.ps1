param(
    [string]$Database = "ppn_e2e",
    [switch]$ConfirmReset,
    [switch]$SkipBuild,
    [ValidateSet("ALL", "AUTH", "NETWORK", "LONG")]
    [string]$Pack = "ALL"
)

$ErrorActionPreference = "Stop"

if (-not $ConfirmReset) {
    throw "V2 permanently resets the dedicated local database. Re-run with -ConfirmReset."
}
if ($Database -ne "ppn_e2e") {
    throw "V2 only accepts the dedicated local database 'ppn_e2e'."
}

$env:APP_ENV = "local"
$env:DB_DATABASE = $Database
$env:E2E_RESET_DATABASE = $Database
$env:E2E_ALLOWED_RESET_DATABASES = $Database
$env:E2E_ALLOW_DATABASE_RESET = "1"
$env:E2E_API_URL = "http://127.0.0.1:8001"
$env:E2E_ADMIN_URL = "http://127.0.0.1:4174"
$env:E2E_SUPPLIER_URL = "http://localhost:3001"
$env:PPN_API_BASE_URL = "http://127.0.0.1:8001/api"

if ($Pack -eq "ALL") {
    Remove-Item Env:E2E_ADVERSARIAL_PACK -ErrorAction SilentlyContinue
} else {
    $env:E2E_ADVERSARIAL_PACK = $Pack.ToLowerInvariant()
}

Write-Host "V2 database target: $Database"
Write-Host "V2 pack: $Pack"
Write-Host "Pacing: slowMo=1000ms, normal=3s, important=4s, error=6s, final=10s"
Write-Host "Artifacts: video/trace/screenshot always on; failures do not stop later tests"
Write-Host "Result folder: test-results-adversarial-v2-$($Pack.ToLowerInvariant())"
Write-Host "HTML report: playwright-report-adversarial-v2-$($Pack.ToLowerInvariant())"

if (-not $SkipBuild) {
    npm run build:web:realistic
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

npm run e2e:adversarial:v2
exit $LASTEXITCODE
