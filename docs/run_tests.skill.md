# Skill: Run PPN GREAT API Tests

This skill describes how to execute the full test suite (both Laravel backend unit/feature tests and Postman Newman integration tests) for PPN GREAT API, verify their correctness, and review the generated reports.

## Prerequisites

1. **PHP Path (Windows)**:
   Ensure that PHP is registered in the system environment path. If not, prepend `C:\xampp\php` to `$env:PATH`.
2. **Laravel Dev Server**:
   The API server must be running on `http://127.0.0.1:8000`. If it is not running, start it using:
   ```powershell
   $env:PATH = "C:\xampp\php;$env:PATH"
   php artisan serve --port=8000
   ```
   Run this as a background task.

## Action Steps

### Step 1: Run Full Test Runner Script
In the terminal, navigate to the `d:\07_Projects\Work\PNN\ppn_great\` directory and run the unified test runner script:
```powershell
Powershell -ExecutionPolicy Bypass -File .\run_all_tests.ps1
```

### Step 2: Validate Backend Tests
Verify that the output of `php artisan test` shows all 18 feature test cases passing:
```text
Tests: 18 passed (70 assertions)
```

### Step 3: Validate Newman Integration Tests
Verify that the Newman output shows no failures:
```text
assertions | 43 | 0 failed
```

### Step 4: Open and Check HTML Dashboard
Confirm that `reports/report.html` is generated. It can be opened using:
```powershell
Start-Process reports\report.html
```

## Expected Results
- Both PHPUnit and Newman CLI test runs report 100% success.
- The dashboard shows 0 failed tests and 43 passed assertions.
