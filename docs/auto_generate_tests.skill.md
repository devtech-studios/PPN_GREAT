# Skill: Auto-Generate & Run Tests for New API Endpoints

This skill guide is for AI Agents to automatically detect new API endpoints in the PPN GREAT codebase, generate Laravel PHPUnit feature tests, add them to the Postman Newman collection, and run validation.

## Execution Workflow

### Step 1: Detect Untested API Endpoints
Run the route list command to list all current API endpoints in JSON format:
```powershell
$env:PATH = "C:\xampp\php;$env:PATH"
php artisan route:list --path=api --json
```
Compare these routes with:
- The tests inside `tests/Feature/` in the `ppn-api` repository.
- The items inside `PPN_GREAT_Postman_Collection.json` in the `ppn_great` repository.

Identify which API endpoints are new and have no tests yet.

### Step 2: Analyze Endpoint Requirements
For each untested API endpoint, analyze:
1. The **Route definition** (HTTP method, URI parameters, Middleware).
2. The **Controller class and method** (e.g., `SupplierController@store`).
3. The **Request Validator** inside the controller method to understand required fields, data types, and enum restrictions (e.g., `'lead_source' => 'required|in:Referral,Google Search'`).
4. The **Database Migrations** to understand the table schema and database constraints (foreign keys, non-null fields).

### Step 3: Write Laravel Feature Tests
1. Locate or create the corresponding feature test file in `tests/Feature/` (e.g., `SupplierApiTest.php` for suppliers).
2. Follow the standard testing structure:
   - Use `RefreshDatabase` trait.
   - Set up standard JWT authentication headers in `setUp()` (use the seeded `admin@ppngreat.com` user).
   - Write positive test cases (e.g., successful creation, retrieval, updates).
   - Write negative test cases (e.g., validation failure with incorrect payload).
   - For database assertions, check `assertDatabaseHas()` or `assertDatabaseMissing()` using correct table names.

### Step 4: Update Postman Collection
1. Open and parse [PPN_GREAT_Postman_Collection.json](file:///d:/07_Projects/Work/PNN/ppn_great/PPN_GREAT_Postman_Collection.json).
2. Add a new request node inside the corresponding folder item (`item` array) using the correct JSON structure:
   - **Request method and URL** (e.g., `{{base_url}}/api/suppliers`).
   - **Headers** (Accept: application/json, Content-Type: application/json).
   - **Body** (Raw JSON containing a valid payload based on the validator).
   - **Test scripts** asserting status code and JSON properties (e.g., `pm.response.to.have.status(201)`).
3. If the request creates a resource, capture the created resource ID in the collection variable (e.g., `pm.collectionVariables.set('supplier_id', response.data.id)`).

*Note: Always ensure the `logout` request remains the very last item in the main collection list.*

### Step 5: Execute & Verify
Run the unified test runner:
```powershell
Powershell -ExecutionPolicy Bypass -File .\run_all_tests.ps1
```
Verify that:
- All PHPUnit feature tests pass.
- All Newman CLI assertions pass.
- The HTML report in `reports/report.html` is generated with 0 failures.
