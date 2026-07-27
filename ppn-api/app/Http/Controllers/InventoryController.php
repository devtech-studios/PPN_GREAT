<?php

namespace App\Http\Controllers;

use App\Models\Warehouse;
use App\Models\StockItem;
use App\Models\StockMovement;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class InventoryController extends Controller
{
    // GET /api/inventory/warehouses — List all warehouses
    public function getWarehouses(): JsonResponse
    {
        $warehouses = Warehouse::where('is_active', true)->get();
        return response()->json([
            'success' => true,
            'data' => $warehouses
        ]);
    }

    // GET /api/inventory/warehouses/{id}/stocks — List stock items inside a warehouse
    public function getWarehouseStocks($id): JsonResponse
    {
        $warehouse = Warehouse::findOrFail($id);
        $stocks = StockItem::where('warehouse_id', $warehouse->id)
            ->with(['productItem', 'project', 'movements.creator'])
            ->orderBy('updated_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $stocks
        ]);
    }

    // POST /api/inventory/warehouses — Store a new warehouse
    public function storeWarehouse(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'location' => 'required|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $warehouse = Warehouse::create([
            'name' => $request->input('name'),
            'location' => $request->input('location'),
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'สร้างคลังสินค้าสำเร็จ',
            'data' => $warehouse
        ], 201);
    }

    // POST /api/inventory/adjust — Manual stock adjustment (IN, OUT, ADJUST)
    public function adjust(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'warehouse_id' => 'required|exists:warehouses,id',
            'product_item_id' => 'required|exists:product_items,id',
            'project_id' => 'required|exists:projects,id',
            'qty' => 'required|integer|min:1',
            'type' => 'required|in:IN,OUT,ADJUST',
            'notes' => 'nullable|string',
            'location_in_warehouse' => 'nullable|string|max:100'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        return DB::transaction(function () use ($request) {
            $warehouseId = $request->input('warehouse_id');
            $productItemId = $request->input('product_item_id');
            $projectId = $request->input('project_id');
            $qty = intval($request->input('qty'));
            $type = $request->input('type');

            // Find or create Stock Item
            $stockItem = StockItem::firstOrCreate(
                [
                    'warehouse_id' => $warehouseId,
                    'product_item_id' => $productItemId,
                    'project_id' => $projectId
                ],
                [
                    'qty_in_stock' => 0,
                    'qty_reserved' => 0
                ]
            );

            if ($type === 'IN') {
                $stockItem->qty_in_stock += $qty;
            } elseif ($type === 'OUT') {
                $stockItem->qty_reserved += $qty;
            } else { // ADJUST
                $stockItem->qty_in_stock = $qty;
            }

            if ($request->filled('location_in_warehouse')) {
                $stockItem->location_in_warehouse = $request->input('location_in_warehouse');
            }
            $stockItem->last_received_at = now();
            $stockItem->save();

            // Create stock movement log
            $movement = StockMovement::create([
                'stock_item_id' => $stockItem->id,
                'movement_type' => $type === 'OUT' ? 'OUT' : ($type === 'IN' ? 'IN' : 'ADJUST'),
                'qty' => $qty,
                'reference_type' => 'Manual',
                'reference_id' => null,
                'notes' => $request->input('notes', 'ปรับปรุงยอดสต็อกด้วยตนเอง (Manual Adjustment)'),
                'created_by' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'บันทึกการปรับปรุงสต็อกสำเร็จ',
                'data' => [
                    'stock_item' => $stockItem,
                    'movement' => $movement
                ]
            ]);
        });
    }

    // POST /api/inventory/receive — Manual stock receipt (Goods Receipt)
    public function receive(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'warehouse_id' => 'required|exists:warehouses,id',
            'product_item_id' => 'required|exists:product_items,id',
            'project_id' => 'required|exists:projects,id',
            'qty' => 'required|integer|min:1',
            'notes' => 'nullable|string',
            'location_in_warehouse' => 'nullable|string|max:100'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        return DB::transaction(function () use ($request) {
            $warehouseId = $request->input('warehouse_id');
            $productItemId = $request->input('product_item_id');
            $projectId = $request->input('project_id');
            $qty = intval($request->input('qty'));

            // Find or create Stock Item
            $stockItem = StockItem::firstOrCreate(
                [
                    'warehouse_id' => $warehouseId,
                    'product_item_id' => $productItemId,
                    'project_id' => $projectId
                ],
                [
                    'qty_in_stock' => 0,
                    'qty_reserved' => 0
                ]
            );

            $stockItem->qty_in_stock += $qty;
            if ($request->filled('location_in_warehouse')) {
                $stockItem->location_in_warehouse = $request->input('location_in_warehouse');
            }
            $stockItem->last_received_at = now();
            $stockItem->save();

            // Create stock IN movement log
            $movement = StockMovement::create([
                'stock_item_id' => $stockItem->id,
                'movement_type' => 'IN',
                'qty' => $qty,
                'reference_type' => 'Manual',
                'reference_id' => null,
                'notes' => $request->input('notes', 'บันทึกรับสินค้าเข้าสต็อกด้วยตนเอง (Manual Goods Receipt)'),
                'created_by' => auth()->id()
            ]);

            return response()->json([
                'success' => true,
                'message' => 'บันทึกรับสินค้าเข้าสต็อกคลังสำเร็จ',
                'data' => [
                    'stock_item' => $stockItem,
                    'movement' => $movement
                ]
            ], 201);
        });
    }

    // GET /api/inventory/movements — List stock movements
    public function getMovements(Request $request): JsonResponse
    {
        $query = StockMovement::query()->with(['stockItem.productItem', 'stockItem.warehouse', 'stockItem.project']);

        if ($request->filled('movement_type')) {
            $query->where('movement_type', $request->input('movement_type'));
        }

        $movements = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $movements
        ]);
    }

    // GET /api/inventory/low-stock — List stock items below warning threshold (default 100 pcs)
    public function getLowStock(Request $request): JsonResponse
    {
        $threshold = intval($request->input('threshold', 100));

        $lowStocks = StockItem::where('qty_in_stock', '<=', $threshold)
            ->with(['productItem', 'warehouse', 'project'])
            ->orderBy('qty_in_stock', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $lowStocks
        ]);
    }
}
