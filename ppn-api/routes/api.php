<?php

use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::prefix('auth')->group(function () {
    Route::post('login', [AuthController::class, 'login']);
    Route::post('logout', [AuthController::class, 'logout'])->middleware('auth:api');
    Route::get('me', [AuthController::class, 'me'])->middleware('auth:api');
});

Route::middleware(['auth:api', \App\Http\Middleware\TenantContextMiddleware::class])->group(function () {
    // Customers
    Route::get('customers', [\App\Http\Controllers\CustomerController::class, 'index']);
    Route::get('customers/{id}', [\App\Http\Controllers\CustomerController::class, 'show']);
    Route::post('customers', [\App\Http\Controllers\CustomerController::class, 'store']);
    Route::put('customers/{id}', [\App\Http\Controllers\CustomerController::class, 'update']);
    Route::post('customers/{id}/contacts', [\App\Http\Controllers\CustomerController::class, 'storeContact']);
    Route::put('customers/{id}/contacts/{cid}', [\App\Http\Controllers\CustomerController::class, 'updateContact']);
    Route::delete('customers/{id}/contacts/{cid}', [\App\Http\Controllers\CustomerController::class, 'destroyContact']);
    Route::post('customers/{id}/addresses', [\App\Http\Controllers\CustomerController::class, 'storeAddress']);
    Route::put('customers/{id}/addresses/{aid}', [\App\Http\Controllers\CustomerController::class, 'updateAddress']);
    Route::delete('customers/{id}/addresses/{aid}', [\App\Http\Controllers\CustomerController::class, 'destroyAddress']);
    Route::get('customers/{id}/stats', [\App\Http\Controllers\CustomerController::class, 'stats']);

    // Projects
    Route::get('projects', [\App\Http\Controllers\ProjectController::class, 'index']);
    Route::get('projects/{id}', [\App\Http\Controllers\ProjectController::class, 'show']);
    Route::post('projects', [\App\Http\Controllers\ProjectController::class, 'store']);
    Route::put('projects/{id}', [\App\Http\Controllers\ProjectController::class, 'update']);
    Route::patch('projects/{id}/status', [\App\Http\Controllers\ProjectController::class, 'status']);
    Route::post('projects/{id}/products', [\App\Http\Controllers\ProjectController::class, 'storeProduct']);
    Route::put('projects/{id}/products/{pid}', [\App\Http\Controllers\ProjectController::class, 'updateProduct']);
    Route::delete('projects/{id}/products/{pid}', [\App\Http\Controllers\ProjectController::class, 'destroyProduct']);
    Route::post('projects/{id}/additional-requests', [\App\Http\Controllers\ProjectController::class, 'storeAdditionalRequest']);
    Route::post('projects/{id}/upload-po', [\App\Http\Controllers\ProjectController::class, 'uploadPO']);
    Route::get('projects/{id}/logs', [\App\Http\Controllers\ProjectController::class, 'logs']);

    // Suppliers
    Route::get('suppliers', [\App\Http\Controllers\SupplierController::class, 'index']);
    Route::get('suppliers/{id}', [\App\Http\Controllers\SupplierController::class, 'show']);
    Route::post('suppliers', [\App\Http\Controllers\SupplierController::class, 'store']);
    Route::put('suppliers/{id}', [\App\Http\Controllers\SupplierController::class, 'update']);
    
    // Quotes (Supplier)
    Route::get('suppliers/{id}/quotes', [\App\Http\Controllers\QuoteRequestController::class, 'index']);
    Route::post('suppliers/{id}/quotes', [\App\Http\Controllers\QuoteRequestController::class, 'store']);
    Route::put('suppliers/{id}/quotes/{qid}', [\App\Http\Controllers\QuoteRequestController::class, 'update']);
    Route::patch('suppliers/{id}/quotes/{qid}/status', [\App\Http\Controllers\QuoteRequestController::class, 'status']);
    Route::post('suppliers/{id}/quotes/{qid}/generate-link', [\App\Http\Controllers\QuoteRequestController::class, 'generateLink']);

    // Samples (Supplier)
    Route::get('suppliers/{id}/samples', [\App\Http\Controllers\SupplierSampleController::class, 'index']);
    Route::post('suppliers/{id}/samples', [\App\Http\Controllers\SupplierSampleController::class, 'store']);
    Route::put('suppliers/{id}/samples/{sid}', [\App\Http\Controllers\SupplierSampleController::class, 'update']);
    Route::patch('suppliers/{id}/samples/{sid}/status', [\App\Http\Controllers\SupplierSampleController::class, 'status']);

    // Bills (Supplier)
    Route::get('suppliers/{id}/bills', [\App\Http\Controllers\SupplierBillController::class, 'index']);
    Route::post('suppliers/{id}/bills', [\App\Http\Controllers\SupplierBillController::class, 'store']);
    Route::patch('suppliers/{id}/bills/{bid}/pay', [\App\Http\Controllers\SupplierBillController::class, 'pay']);
    Route::post('suppliers/{id}/bills/{bid}/upload', [\App\Http\Controllers\SupplierBillController::class, 'upload']);

    // Finance Documents
    Route::get('finance/supplier-bills', [\App\Http\Controllers\FinanceDocController::class, 'supplierBills']);
    Route::get('finance/documents', [\App\Http\Controllers\FinanceDocController::class, 'index']);
    Route::get('finance/documents/{id}', [\App\Http\Controllers\FinanceDocController::class, 'show']);
    Route::post('finance/documents', [\App\Http\Controllers\FinanceDocController::class, 'store']);
    Route::put('finance/documents/{id}', [\App\Http\Controllers\FinanceDocController::class, 'update']);
    Route::patch('finance/documents/{id}/status', [\App\Http\Controllers\FinanceDocController::class, 'status']);

    // Payments
    Route::get('finance/payments', [\App\Http\Controllers\PaymentController::class, 'index']);
    Route::post('finance/payments', [\App\Http\Controllers\PaymentController::class, 'store']);
    Route::patch('finance/payments/{id}/verify', [\App\Http\Controllers\PaymentController::class, 'verify']);
    Route::post('finance/payments/{id}/upload-slip', [\App\Http\Controllers\PaymentController::class, 'uploadSlip']);

    // Client Samples (Phase 3)
    Route::get('samples', [\App\Http\Controllers\ClientSampleController::class, 'index']);
    Route::get('samples/project/{pid}', [\App\Http\Controllers\ClientSampleController::class, 'getByProject']);
    Route::post('samples', [\App\Http\Controllers\ClientSampleController::class, 'store']);
    Route::put('samples/{id}', [\App\Http\Controllers\ClientSampleController::class, 'update']);
    Route::patch('samples/{id}/status', [\App\Http\Controllers\ClientSampleController::class, 'status']);

    // Artworks (Phase 3)
    Route::get('artworks', [\App\Http\Controllers\ArtworkController::class, 'index']);
    Route::get('artworks/project/{pid}', [\App\Http\Controllers\ArtworkController::class, 'getByProject']);
    Route::post('artworks', [\App\Http\Controllers\ArtworkController::class, 'store']);
    Route::post('artworks/upload', [\App\Http\Controllers\ArtworkController::class, 'upload']);
    Route::put('artworks/{id}', [\App\Http\Controllers\ArtworkController::class, 'update']);
    Route::patch('artworks/{id}/status', [\App\Http\Controllers\ArtworkController::class, 'status']);
    Route::patch('artworks/{id}/feedback', [\App\Http\Controllers\ArtworkController::class, 'feedback']);

    // Logistics Containers (Phase 3)
    Route::get('containers', [\App\Http\Controllers\ContainerController::class, 'index']);
    Route::get('containers/{id}', [\App\Http\Controllers\ContainerController::class, 'show']);
    Route::post('containers', [\App\Http\Controllers\ContainerController::class, 'store']);
    Route::put('containers/{id}', [\App\Http\Controllers\ContainerController::class, 'update']);
    Route::patch('containers/{id}/step', [\App\Http\Controllers\ContainerController::class, 'step']);
    Route::post('containers/{id}/route-goods', [\App\Http\Controllers\ContainerController::class, 'routeGoods']);

    // Inventory & Warehouses (Phase 3)
    Route::get('inventory/warehouses', [\App\Http\Controllers\InventoryController::class, 'getWarehouses']);
    Route::post('inventory/warehouses', [\App\Http\Controllers\InventoryController::class, 'storeWarehouse']);
    Route::get('inventory/warehouses/{id}/stocks', [\App\Http\Controllers\InventoryController::class, 'getWarehouseStocks']);
    Route::post('inventory/receive', [\App\Http\Controllers\InventoryController::class, 'receive']);
    Route::post('inventory/adjust', [\App\Http\Controllers\InventoryController::class, 'adjust']);
    Route::get('inventory/movements', [\App\Http\Controllers\InventoryController::class, 'getMovements']);
    Route::get('inventory/low-stock', [\App\Http\Controllers\InventoryController::class, 'getLowStock']);

    // Deliveries (Phase 3)
    Route::get('delivery/rounds', [\App\Http\Controllers\DeliveryController::class, 'index']);
    Route::get('delivery/rounds/{id}', [\App\Http\Controllers\DeliveryController::class, 'show']);
    Route::post('delivery/rounds', [\App\Http\Controllers\DeliveryController::class, 'store']);
    Route::patch('delivery/rounds/{id}/confirm', [\App\Http\Controllers\DeliveryController::class, 'confirm']);
    Route::patch('delivery/rounds/{id}/complete', [\App\Http\Controllers\DeliveryController::class, 'complete']);

    // Dashboard (Phase 4)
    Route::get('dashboard/summary', [\App\Http\Controllers\DashboardController::class, 'summary']);
    Route::get('dashboard/activities', [\App\Http\Controllers\DashboardController::class, 'activities']);
    Route::get('dashboard/revenue-chart', [\App\Http\Controllers\DashboardController::class, 'revenueChart']);

    // Reports (Phase 4)
    Route::get('reports/financial-summary', [\App\Http\Controllers\ReportController::class, 'financialSummary']);
    Route::get('reports/operational-summary', [\App\Http\Controllers\ReportController::class, 'operationalSummary']);
    Route::get('reports/revenue-by-month', [\App\Http\Controllers\ReportController::class, 'revenueByMonth']);
    Route::get('reports/profit-by-project', [\App\Http\Controllers\ReportController::class, 'profitByProject']);
});

// Public Quotes self-service routes
Route::get('quotes/public/{token}', [\App\Http\Controllers\QuoteRequestController::class, 'showPublicForm']);
Route::put('quotes/public/{token}', [\App\Http\Controllers\QuoteRequestController::class, 'fillPricePublic']);

// Public Artwork File serve route with CORS
Route::get('artworks/file/{filename}', [\App\Http\Controllers\ArtworkController::class, 'serveFile']);

// Public Payment Slip serve route with CORS
Route::get('finance/payments/file/{filename}', [\App\Http\Controllers\PaymentController::class, 'serveFile']);

// Supplier Portal routes (Mode 2)
Route::post('supplier/portal/login', [\App\Http\Controllers\QuoteRequestController::class, 'portalLogin']);
Route::post('supplier/portal/quotes/{qid}/submit', [\App\Http\Controllers\QuoteRequestController::class, 'portalSubmitQuote']);

// Public Pusher test route
Route::get('test-pusher', function () {
    event(new \App\Events\MyEvent('Hello from PPN GREAT API!'));
    return response()->json([
        'success' => true,
        'message' => 'Pusher event broadcasted successfully!'
    ]);
});

// Tenant Isolated AI Analyze Route
Route::post('ai/analyze', function (\Illuminate\Http\Request $request) {
    $shopId = session('authorized_shop_id', 1);
    $branchId = session('active_branch_id', 1);
    $service = new \App\Services\AIContextBuilderService();
    $context = $service->buildCleanContext($shopId, $branchId, $request->input('message', 'วิเคราะห์ยอดขาย'));
    return response()->json([
        'success' => true,
        'ai_context' => $context
    ]);
});



