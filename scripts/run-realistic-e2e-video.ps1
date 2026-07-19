param(
    [string]$Database = "ppn_e2e",
    [switch]$ConfirmReset,
    [switch]$SkipBuild,
    [switch]$Resume
)

$ErrorActionPreference = "Stop"

if (-not $Resume -and -not $ConfirmReset) {
    throw "This run permanently resets the selected local database. Re-run with -ConfirmReset."
}

if ($Database -ne "ppn_e2e") {
    throw "For safety this runner only accepts the dedicated local database 'ppn_e2e'."
}

$env:APP_ENV = "local"
$env:DB_DATABASE = $Database
$env:E2E_REALISTIC_MODE = if ($Resume) { "resume" } else { "full" }
if ($Resume) {
    Remove-Item Env:E2E_RESET_DATABASE -ErrorAction SilentlyContinue
    Remove-Item Env:E2E_ALLOW_DATABASE_RESET -ErrorAction SilentlyContinue
} else {
    $env:E2E_RESET_DATABASE = $Database
    $env:E2E_ALLOWED_RESET_DATABASES = $Database
    $env:E2E_ALLOW_DATABASE_RESET = "1"
}
$env:E2E_API_URL = "http://127.0.0.1:8001"
$env:E2E_ADMIN_URL = "http://127.0.0.1:4174"
$env:E2E_SUPPLIER_URL = "http://localhost:3001"
$env:PPN_API_BASE_URL = "http://127.0.0.1:8001/api"

Write-Host "Database target: $Database"
Write-Host "Mode: $(if ($Resume) { 'resume from existing checkpoint' } else { 'full reset and realistic UI flow' })"
Write-Host "Artifacts: video/trace/screenshot always on"

if (-not $SkipBuild) {
    npm run build:web:realistic
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

npm run e2e:realistic:video
exit $LASTEXITCODE
