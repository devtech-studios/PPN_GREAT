<?php

namespace App\Http\Controllers;

use App\Models\DispatchRound;
use App\Models\DeliveryItem;
use App\Models\StockItem;
use App\Models\StockMovement;
use App\Models\Project;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class DeliveryController extends Controller
{
    // GET /api/delivery/rounds — List all delivery dispatch rounds
    public function index(Request $request): JsonResponse
    {
        $query = DispatchRound::query();

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        $rounds = $query->with(['items.project.customer', 'items.productItem', 'items.warehouse'])
                        ->orderBy('dispatch_date', 'desc')
                        ->get();

        return response()->json([
            'success' => true,
            'data' => $rounds
        ]);
    }

    // GET /api/delivery/rounds/{id} — Round detail with items
    public function show($id): JsonResponse
    {
        $round = DispatchRound::with(['items.project.customer', 'items.productItem', 'items.warehouse'])->findOrFail($id);
        return response()->json([
            'success' => true,
            'data' => $round
        ]);
    }

    // POST /api/delivery/rounds — Create dispatch round and schedule delivery items (with stock reservation)
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'dispatch_date' => 'required|date',
            'driver_name' => 'nullable|string|max:255',
            'vehicle_plate' => 'nullable|string|max:50',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.project_id' => 'required|exists:projects,id',
            'items.*.product_item_id' => 'required|exists:product_items,id',
            'items.*.qty_to_deliver' => 'required|integer|min:1',
            'items.*.delivery_address' => 'required|string',
            'items.*.warehouse_id' => 'nullable|exists:warehouses,id'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        return DB::transaction(function () use ($request) {
            // 1. Create dispatch round
            $round = DispatchRound::create([
                'dispatch_code' => 'TEMP_DSP_CODE', // Will update below
                'dispatch_date' => $request->input('dispatch_date'),
                'driver_name' => $request->input('driver_name'),
                'vehicle_plate' => $request->input('vehicle_plate'),
                'status' => 'Scheduled',
                'notes' => $request->input('notes'),
                'created_by' => auth()->id()
            ]);

            $round->dispatch_code = 'DSP-' . str_pad($round->id, 3, '0', STR_PAD_LEFT);
            $round->save();

            // 2. Loop and reserve stock for items shipped from warehouse
            foreach ($request->input('items') as $itemData) {
                $projectId = $itemData['project_id'];
                $productItemId = $itemData['product_item_id'];
                $qty = intval($itemData['qty_to_deliver']);
                $warehouseId = $itemData['warehouse_id'] ?? null;

                $project = Project::with('customer')->find($projectId);
                $customerName = $project->customer ? $project->customer->name : null;

                if ($warehouseId) {
                    // Check stock in warehouse
                    $stockItem = StockItem::where([
                        'warehouse_id' => $warehouseId,
                        'product_item_id' => $productItemId,
                        'project_id' => $projectId
                    ])->first();

                    if (!$stockItem) {
                        return response()->json([
                            'success' => false,
                            'message' => "ไม่พบสินค้าในสต็อกคลังสินค้า ID {$warehouseId} สำหรับจัดส่ง"
                        ], 422);
                    }

                    $availableStock = $stockItem->qty_in_stock - $stockItem->qty_reserved;
                    if ($availableStock < $qty) {
                        return response()->json([
                            'success' => false,
                            'message' => "สินค้าในคลังไม่พอจัดส่ง (ต้องการ {$qty}, ยอดว่างใช้งานได้ {$availableStock})"
                        ], 422);
                    }

                    // Reserve stock
                    $stockItem->qty_reserved += $qty;
                    $stockItem->save();
                }

                // Create Delivery Item
                DeliveryItem::create([
                    'dispatch_round_id' => $round->id,
                    'project_id' => $projectId,
                    'product_item_id' => $productItemId,
                    'customer_name' => $customerName,
                    'delivery_address' => $itemData['delivery_address'],
                    'qty_to_deliver' => $qty,
                    'warehouse_id' => $warehouseId,
                    'notes' => $itemData['notes'] ?? null
                ]);
            }

            return response()->json([
                'success' => true,
                'data' => $round->load('items')
            ], 201);
        });
    }

    // PATCH /api/delivery/rounds/{id}/confirm — Depart round (Scheduled -> In Transit: deduct stock)
    public function confirm($id): JsonResponse
    {
        $round = DispatchRound::with('items')->findOrFail($id);

        if ($round->status !== 'Scheduled') {
            return response()->json([
                'success' => false,
                'message' => 'รอบจัดส่งนี้ไม่ได้อยู่ในสถานะ Scheduled จึงยืนยันปล่อยรถไม่ได้'
            ], 400);
        }

        return DB::transaction(function () use ($round) {
            $round->status = 'In Transit';
            $round->save();

            // Loop items to deduct reserved and stock quantities
            foreach ($round->items as $item) {
                if ($item->warehouse_id) {
                    $stockItem = StockItem::where([
                        'warehouse_id' => $item->warehouse_id,
                        'product_item_id' => $item->product_item_id,
                        'project_id' => $item->project_id
                    ])->first();

                    if ($stockItem) {
                        // Deduct stock and reservation
                        $stockItem->qty_reserved = max(0, $stockItem->qty_reserved - $item->qty_to_deliver);
                        $stockItem->qty_in_stock = max(0, $stockItem->qty_in_stock - $item->qty_to_deliver);
                        $stockItem->save();

                        // Log OUT movement history
                        StockMovement::create([
                            'stock_item_id' => $stockItem->id,
                            'movement_type' => 'OUT',
                            'qty' => $item->qty_to_deliver,
                            'reference_type' => 'Delivery',
                            'reference_id' => $round->id,
                            'notes' => 'ตัดยอดสินค้าออกจากคลังเมื่อปล่อยรถส่งมอบจริง (In Transit)',
                            'created_by' => auth()->id()
                        ]);
                    }
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'ยืนยันปล่อยรอบจัดส่ง (In Transit) และหักสต็อกสินค้าเรียบร้อย',
                'data' => $round->load('items')
            ]);
        });
    }

    // PATCH /api/delivery/rounds/{id}/complete — Complete delivery (In Transit -> Delivered)
    public function complete($id): JsonResponse
    {
        $round = DispatchRound::findOrFail($id);

        if ($round->status !== 'In Transit') {
            return response()->json([
                'success' => false,
                'message' => 'รอบจัดส่งนี้ไม่ได้อยู่ในสถานะ In Transit จึงยืนยันส่งเสร็จไม่ได้'
            ], 400);
        }

        $round->status = 'Delivered';
        $round->save();

        return response()->json([
            'success' => true,
            'message' => 'บันทึกการส่งมอบสินค้าเสร็จสมบูรณ์เรียบร้อย',
            'data' => $round
        ]);
    }
}
