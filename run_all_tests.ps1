# PPN GREAT API - Full Test Suite Runner (PHPUnit + Newman)

$apiFolder = Join-Path $PSScriptRoot "..\ppn-api"
$env:PATH = "C:\xampp\php;$env:PATH"

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "    PPN GREAT API - Running Full Test Suite (Skill)" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

# 1. Check if Laravel local dev server is responding on port 8000
$serverUrl = "http://127.0.0.1:8000/api/auth/me"
Write-Host ">>> Checking Laravel server status on port 8000..." -ForegroundColor Cyan
$serverResponding = $false
try {
    $response = Invoke-WebRequest -Uri $serverUrl -Method GET -TimeoutSec 3 -ErrorAction SilentlyContinue
    $serverResponding = $true
} catch {
    if ($_.Exception.Response -ne $null) {
        $serverResponding = $true
    }
}

if (!$serverResponding) {
    Write-Host ">>> [ERROR] Laravel server is not running on http://127.0.0.1:8000" -ForegroundColor Red
    Write-Host ">>> Please start it by running:" -ForegroundColor Yellow
    Write-Host "    cd $apiFolder" -ForegroundColor Yellow
    Write-Host "    php artisan serve --port=8000" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Green
    Exit 1
}
Write-Host ">>> Laravel server is running and healthy! [OK]" -ForegroundColor Green

# 2. Run PHPUnit Feature Tests
Write-Host "`n>>> [1/2] Running Laravel Feature Tests..." -ForegroundColor Cyan
Push-Location $apiFolder
php artisan test
$phpunitExitCode = $LASTEXITCODE
Pop-Location

# 3. Run Newman API Tests
Write-Host "`n>>> [2/2] Running Postman Newman API Tests..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "run_newman_tests.ps1")
$newmanExitCode = $LASTEXITCODE

# 4. Summary Report
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "                  TEST SUITE SUMMARY" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green

if ($phpunitExitCode -eq 0) {
    Write-Host "1. Laravel Feature Tests:  [PASSED] [OK]" -ForegroundColor Green
} else {
    Write-Host "1. Laravel Feature Tests:  [FAILED] [FAIL]" -ForegroundColor Red
}

if ($newmanExitCode -eq 0) {
    Write-Host "2. Postman Newman Tests:   [PASSED] [OK]" -ForegroundColor Green
} else {
    Write-Host "2. Postman Newman Tests:   [FAILED] [FAIL]" -ForegroundColor Red
}

Write-Host "==========================================================" -ForegroundColor Green

if ($phpunitExitCode -eq 0 -and $newmanExitCode -eq 0) {
    Write-Host ">>> SUCCESS: All tests passed successfully!" -ForegroundColor Green
    Exit 0
} else {
    Write-Host ">>> FAILURE: Some tests failed. Please review the logs above." -ForegroundColor Red
    Exit 1
}
