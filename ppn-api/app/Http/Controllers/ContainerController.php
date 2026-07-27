<?php

namespace App\Http\Controllers;

use App\Models\Container;
use App\Models\Project;
use App\Models\StockItem;
use App\Models\StockMovement;
use App\Models\DispatchRound;
use App\Models\DeliveryItem;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class ContainerController extends Controller
{
    // GET /api/containers — List all containers
    public function index(Request $request): JsonResponse
    {
        $query = Container::query()->with('projects');

        if ($request->filled('status')) {
            $query->where('status', $request->input('status'));
        }

        if ($request->filled('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('container_code', 'like', "%{$search}%")
                  ->orWhere('container_no', 'like', "%{$search}%")
                  ->orWhere('vessel_name', 'like', "%{$search}%");
            });
        }

        $containers = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'data' => $containers
        ]);
    }

    // GET /api/containers/{id} — Container detail
    public function show($id): JsonResponse
    {
        $container = Container::with(['projects.customer', 'projects.productItems'])->findOrFail($id);
        return response()->json([
            'success' => true,
            'data' => $container
        ]);
    }

    // POST /api/containers — Create a container
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'container_no' => 'nullable|string|max:255',
            'vessel_name' => 'nullable|string|max:255',
            'port_origin' => 'nullable|string|max:255',
            'port_destination' => 'nullable|string|max:255',
            'factory_departure' => 'nullable|date',
            'domestic_tracking' => 'nullable|string|max:100',
            'port_arrival_china' => 'nullable|date',
            'etd' => 'nullable|date',
            'eta' => 'nullable|date',
            'notes' => 'nullable|string',
            'project_ids' => 'nullable|array',
            'project_ids.*' => 'exists:projects,id'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        return DB::transaction(function () use ($request) {
            $container = Container::create([
                'container_code' => 'TEMP_CODE', // Will update below
                'container_no' => $request->input('container_no'),
                'vessel_name' => $request->input('vessel_name'),
                'port_origin' => $request->input('port_origin'),
                'port_destination' => $request->input('port_destination'),
                'factory_departure' => $request->input('factory_departure'),
                'domestic_tracking' => $request->input('domestic_tracking'),
                'port_arrival_china' => $request->input('port_arrival_china'),
                'etd' => $request->input('etd'),
                'eta' => $request->input('eta'),
                'status' => 'Factory to Port',
                'notes' => $request->input('notes'),
            ]);

            $container->container_code = 'CNT-' . str_pad($container->id, 3, '0', STR_PAD_LEFT);
            $container->save();

            // Link projects
            if ($request->filled('project_ids')) {
                $container->projects()->sync($request->input('project_ids'));
            }

            return response()->json([
                'success' => true,
                'data' => $container->load(['projects.customer', 'projects.productItems'])
            ], 201);
        });
    }

    // PUT /api/containers/{id} — Update container
    public function update(Request $request, $id): JsonResponse
    {
        $container = Container::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'container_no' => 'nullable|string|max:255',
            'vessel_name' => 'nullable|string|max:255',
            'port_origin' => 'nullable|string|max:255',
            'port_destination' => 'nullable|string|max:255',
            'factory_departure' => 'nullable|date',
            'domestic_tracking' => 'nullable|string|max:100',
            'port_arrival_china' => 'nullable|date',
            'etd' => 'nullable|date',
            'eta' => 'nullable|date',
            'actual_arrival' => 'nullable|date',
            'customs_cleared' => 'nullable|boolean',
            'customs_date' => 'nullable|date',
            'warehouse_arrival' => 'nullable|date',
            'notes' => 'nullable|string',
            'project_ids' => 'nullable|array',
            'project_ids.*' => 'exists:projects,id'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        return DB::transaction(function () use ($request, $container) {
            $container->update($request->all());

            if ($request->has('project_ids')) {
                $container->projects()->sync($request->input('project_ids'));
            }

            return response()->json([
                'success' => true,
                'data' => $container->load(['projects.customer', 'projects.productItems'])
            ]);
        });
    }

    // PATCH /api/containers/{id}/step — Change transit step
    public function step(Request $request, $id): JsonResponse
    {
        $container = Container::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:Factory to Port,Sailing,Port to Warehouse,Delivered',
            'warehouse_arrival' => 'nullable|date'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $container->status = $request->input('status');
        if ($request->input('status') === 'Delivered') {
            $container->warehouse_arrival = $request->input('warehouse_arrival', now()->toDateString());
        }
        $container->save();

        return response()->json([
            'success' => true,
            'data' => $container
        ]);
    }

    // POST /api/containers/{id}/route-goods — Split container quantity to direct delivery (90%) and inventory (10%)
    public function routeGoods(Request $request, $id): JsonResponse
    {
        $container = Container::findOrFail($id);

        if ($container->status !== 'Delivered') {
            return response()->json([
                'success' => false,
                'message' => 'Container goods can only be routed after the container is Delivered.',
            ], 409);
        }

        $validator = Validator::make($request->all(), [
            'project_id' => 'required|exists:projects,id',
            'product_item_id' => 'required|exists:product_items,id',
            'qty_total_received' => 'required|integer|min:1',
            'routing' => 'required|array|min:1',
            'routing.*.type' => 'required|in:direct_delivery,inventory',
            'routing.*.qty' => 'required|integer|min:1',
            'routing.*.warehouse_id' => 'required_if:routing.*.type,inventory|exists:warehouses,id',
            'routing.*.delivery_address' => 'required_if:routing.*.type,direct_delivery|string',
            'routing.*.dispatch_round_id' => 'nullable|exists:dispatch_rounds,id'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $projectId = $request->input('project_id');
        $productItemId = $request->input('product_item_id');
        $project = Project::with('customer')->find($projectId);
        $customerName = $project->customer ? $project->customer->name : null;

        if (!$container->projects()->whereKey($projectId)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'The selected project is not linked to this container.',
            ], 422);
        }

        $routedQty = collect($request->input('routing'))->sum(
            fn (array $route) => intval($route['qty'])
        );
        if ($routedQty !== intval($request->input('qty_total_received'))) {
            return response()->json([
                'success' => false,
                'message' => 'The sum of routed quantities must equal qty_total_received.',
            ], 422);
        }

        $inventoryAlreadyRouted = StockMovement::where('reference_type', 'Container')
            ->where('reference_id', $container->id)
            ->whereHas('stockItem', function ($query) use ($projectId, $productItemId) {
                $query->where('project_id', $projectId)
                    ->where('product_item_id', $productItemId);
            })
            ->exists();
        $directAlreadyRouted = DeliveryItem::where('project_id', $projectId)
            ->where('product_item_id', $productItemId)
            ->where('notes', 'like', "%Container #{$container->id}%")
            ->exists();
        if ($inventoryAlreadyRouted || $directAlreadyRouted) {
            return response()->json([
                'success' => false,
                'message' => 'Goods for this container, project, and product were already routed.',
            ], 409);
        }

        return DB::transaction(function () use ($request, $container, $projectId, $productItemId, $customerName) {
            $routingDetails = $request->input('routing');
            $createdDeliveries = [];
            $createdStockMovements = [];

            foreach ($routingDetails as $route) {
                $qty = intval($route['qty']);

                if ($route['type'] === 'inventory') {
                    $warehouseId = $route['warehouse_id'];

                    // Find or create Stock Item in warehouse
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
                    $stockItem->last_received_at = now();
                    $stockItem->save();

                    // Create stock IN movement log
                    $movement = StockMovement::create([
                        'stock_item_id' => $stockItem->id,
                        'movement_type' => 'IN',
                        'qty' => $qty,
                        'reference_type' => 'Container',
                        'reference_id' => $container->id,
                        'notes' => 'รับสินค้าเข้าสต็อกคลังหลังตู้สินค้าถึงไทย',
                        'created_by' => auth()->id()
                    ]);

                    $createdStockMovements[] = $movement;

                } elseif ($route['type'] === 'direct_delivery') {
                    $dispatchRoundId = $route['dispatch_round_id'] ?? null;

                    // Auto create a default dispatch round if not provided
                    if (!$dispatchRoundId) {
                        $dispatchRound = DispatchRound::create([
                            'dispatch_code' => 'DSP-' . str_pad(rand(1, 9999), 4, '0', STR_PAD_LEFT),
                            'dispatch_date' => now()->toDateString(),
                            'driver_name' => 'รถขนส่งตรงตู้คอนเทนเนอร์',
                            'status' => 'Scheduled',
                            'notes' => "จัดส่งด่วนตรงจากตู้คอนเทนเนอร์ รหัสตู้ {$container->container_code}",
                            'created_by' => auth()->id()
                        ]);
                        $dispatchRoundId = $dispatchRound->id;
                    }

                    $defaultShippingAddress = $project->customer?->shippingAddresses()->first();
                    $address = $route['delivery_address']
                        ?? $defaultShippingAddress?->address
                        ?? $project->customer?->billing_address
                        ?? 'จัดส่งตรงตามแผนงานลูกค้า';

                    // Create delivery item directly
                    $deliveryItem = DeliveryItem::create([
                        'dispatch_round_id' => $dispatchRoundId,
                        'project_id' => $projectId,
                        'product_item_id' => $productItemId,
                        'customer_name' => $customerName,
                        'delivery_address' => $address,
                        'qty_to_deliver' => $qty,
                        'warehouse_id' => null, // Direct shipment, bypasses warehouse!
                        'notes' => "จัดส่งส่งมอบด่วนตรงจากตู้คอนเทนเนอร์ Container #{$container->id}"
                    ]);

                    $createdDeliveries[] = $deliveryItem;
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'บันทึกการจัดสรรแบ่งกระจายสินค้าตู้คอนเทนเนอร์สำเร็จเรียบร้อย',
                'data' => [
                    'direct_deliveries' => $createdDeliveries,
                    'stock_in_movements' => $createdStockMovements
                ]
            ]);
        });
    }
}
