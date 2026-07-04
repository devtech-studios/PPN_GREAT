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

Route::middleware('auth:api')->group(function () {
    // Customers
    Route::get('customers', [\App\Http\Controllers\CustomerController::class, 'index']);
    Route::get('customers/{id}', [\App\Http\Controllers\CustomerController::class, 'show']);
    Route::post('customers', [\App\Http\Controllers\CustomerController::class, 'store']);
    Route::put('customers/{id}', [\App\Http\Controllers\CustomerController::class, 'update']);
    Route::post('customers/{id}/contacts', [\App\Http\Controllers\CustomerController::class, 'storeContact']);
    Route::put('customers/{id}/contacts/{cid}', [\App\Http\Controllers\CustomerController::class, 'updateContact']);
    Route::delete('customers/{id}/contacts/{cid}', [\App\Http\Controllers\CustomerController::class, 'destroyContact']);
    Route::post('customers/{id}/addresses', [\App\Http\Controllers\CustomerController::class, 'storeAddress']);
    Route::get('customers/{id}/stats', [\App\Http\Controllers\CustomerController::class, 'stats']);

    // Projects
    Route::get('projects', [\App\Http\Controllers\ProjectController::class, 'index']);
    Route::get('projects/{id}', [\App\Http\Controllers\ProjectController::class, 'show']);
    Route::post('projects', [\App\Http\Controllers\ProjectController::class, 'store']);
    Route::put('projects/{id}', [\App\Http\Controllers\ProjectController::class, 'update']);
    Route::patch('projects/{id}/status', [\App\Http\Controllers\ProjectController::class, 'status']);
    Route::post('projects/{id}/products', [\App\Http\Controllers\ProjectController::class, 'storeProduct']);
    Route::put('projects/{id}/products/{pid}', [\App\Http\Controllers\ProjectController::class, 'updateProduct']);
    Route::post('projects/{id}/additional-requests', [\App\Http\Controllers\ProjectController::class, 'storeAdditionalRequest']);
    Route::get('projects/{id}/logs', [\App\Http\Controllers\ProjectController::class, 'logs']);
});
