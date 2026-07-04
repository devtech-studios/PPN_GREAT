# PPN GREAT API - Newman Automated Test Runner Script

# 1. Setup report directory
$reportDir = Join-Path $PSScriptRoot "reports"
if (!(Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$reportFile = Join-Path $reportDir "report.html"

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "        PPN GREAT API - Automated Test Runner CLI" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ">>> Running Newman API test suite..." -ForegroundColor Cyan

# 2. Build Newman command using npx
$collectionPath = Join-Path $PSScriptRoot "PPN_GREAT_Postman_Collection.json"
$npxCommand = 'npx -p newman -p newman-reporter-htmlextra newman run "' + $collectionPath + '" -r cli,htmlextra --reporter-htmlextra-export "' + $reportFile + '" --reporter-htmlextra-title "PPN GREAT API Automated Test Report"'

Write-Host ">>> Command: $npxCommand" -ForegroundColor DarkGray

# Execute command
Invoke-Expression $npxCommand

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n>>> [SUCCESS] All tests passed successfully!" -ForegroundColor Green
} else {
    Write-Host "`n>>> [WARNING] Some tests failed or API error occurred." -ForegroundColor Yellow
}

# 3. Open HTML report in default browser
if (Test-Path $reportFile) {
    Write-Host ">>> Displaying HTML Dashboard: $reportFile" -ForegroundColor Cyan
    Start-Process $reportFile
} else {
    Write-Host ">>> [ERROR] HTML report file not found." -ForegroundColor Red
}
Write-Host "==========================================================" -ForegroundColor Green
