<?php

namespace App\Http\Controllers;

use App\Models\Project;
use App\Models\ProductItem;
use App\Models\AdditionalRequest;
use App\Models\ActivityLog;
use App\Services\ProjectCodeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class ProjectController extends Controller
{
    // GET /api/projects — List + Filter + Search + Paginate
    public function index(Request $request): JsonResponse
    {
        $query = Project::with(['customer', 'contactPerson', 'productItems']);

        // Search (project_code, customer name, or product name inside project)
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('project_code', 'like', "%{$search}%")
                  ->orWhereHas('customer', function ($cq) use ($search) {
                      $cq->where('name', 'like', "%{$search}%");
                  })
                  ->orWhereHas('productItems', function ($pq) use ($search) {
                      $pq->where('name', 'like', "%{$search}%");
                  });
            });
        }

        // Filters
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('customer_id')) {
            $query->where('customer_id', $request->customer_id);
        }

        // Sorting
        $sortBy = $request->get('sort', 'created_at');
        $order = $request->get('order', 'desc');
        $query->orderBy($sortBy, $order);

        // Paginate
        $perPage = $request->get('per_page', 20);
        $items = $query->paginate($perPage);

        // Map data to calculate days_left and custom attributes for Flutter
        $mappedItems = collect($items->items())->map(function ($project) {
            $daysLeft = null;
            if ($project->target_date) {
                $daysLeft = now()->diffInDays($project->target_date, false);
            }

            return array_merge($project->toArray(), [
                'days_left' => $daysLeft
            ]);
        });

        return response()->json([
            'success' => true,
            'data' => $mappedItems,
            'meta' => [
                'current_page' => $items->currentPage(),
                'last_page' => $items->lastPage(),
                'per_page' => $items->perPage(),
                'total' => $items->total(),
            ]
        ]);
    }

    // GET /api/projects/{id} — Detail
    public function show($id): JsonResponse
    {
        $project = Project::with([
            'customer', 
            'contactPerson', 
            'productItems.variations', 
            'productItems.files', 
            'additionalRequests',
            'activityLogs.user'
        ])->findOrFail($id);

        $daysLeft = null;
        if ($project->target_date) {
            $daysLeft = now()->diffInDays($project->target_date, false);
        }

        $data = array_merge($project->toArray(), [
            'days_left' => $daysLeft
        ]);

        return response()->json([
            'success' => true,
            'data' => $data
        ]);
    }

    // POST /api/projects — Create
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'customer_id' => 'required|exists:customers,id',
            'contact_person_id' => 'nullable|exists:contact_persons,id',
            'priority' => 'nullable|integer',
            'is_repeat_order' => 'nullable|boolean',
            'target_date' => 'nullable|date',
            'order_value' => 'nullable|numeric',
            'usage_location' => 'nullable|string',
            'credit_term' => 'nullable|in:Advance,15 Days,30 Days,45 Days,60 Days',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'ข้อมูลนำเข้าไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        try {
            $project = DB::transaction(function () use ($request) {
                // Generate next code safely using lock
                $projectCode = ProjectCodeService::generateNextCode();

                $data = $request->all();
                $data['project_code'] = $projectCode;
                $data['status'] = 'Inquiry';
                $data['step'] = 0;
                $data['created_by'] = auth()->id();

                $project = Project::create($data);

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'project_id' => $project->id,
                    'action' => 'สร้าง Project',
                    'description' => "สร้างโปรเจกต์ใหม่ รหัส {$project->project_code}",
                    'entity_type' => 'projects',
                    'entity_id' => $project->id,
                ]);

                return $project;
            });

            return response()->json([
                'success' => true,
                'data' => $project,
                'message' => 'สร้างโปรเจกต์สำเร็จ'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'CREATE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // PUT /api/projects/{id} — Update
    public function update(Request $request, $id): JsonResponse
    {
        $project = Project::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'contact_person_id' => 'nullable|exists:contact_persons,id',
            'priority' => 'nullable|integer',
            'is_repeat_order' => 'nullable|boolean',
            'target_date' => 'nullable|date',
            'order_value' => 'nullable|numeric',
            'usage_location' => 'nullable|string',
            'credit_term' => 'nullable|in:Advance,15 Days,30 Days,45 Days,60 Days',
            'ocpb_passed' => 'nullable|boolean',
            'shipping_mark_ready' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'ข้อมูลนำเข้าไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        try {
            DB::transaction(function () use ($request, $project) {
                $project->update($request->all());

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'project_id' => $project->id,
                    'action' => 'อัปเดต Project',
                    'description' => "อัปเดตข้อมูลโปรเจกต์ {$project->project_code}",
                    'entity_type' => 'projects',
                    'entity_id' => $project->id,
                ]);
            });

            return response()->json([
                'success' => true,
                'data' => $project->fresh(),
                'message' => 'อัปเดตโปรเจกต์สำเร็จ'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'UPDATE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // PATCH /api/projects/{id}/status — Update status pipeline
    public function status(Request $request, $id): JsonResponse
    {
        $project = Project::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'status' => 'required|in:Inquiry,Sample,Production,Shipping,Distributing,Delivered,Cancelled',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'สถานะไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        $oldStatus = $project->status;
        $newStatus = $request->status;

        // Map status to steps
        $steps = [
            'Inquiry' => 0,
            'Sample' => 1,
            'Production' => 2,
            'Shipping' => 3,
            'Distributing' => 4,
            'Delivered' => 5,
            'Cancelled' => 6,
        ];

        try {
            DB::transaction(function () use ($project, $newStatus, $steps, $oldStatus) {
                $project->update([
                    'status' => $newStatus,
                    'step' => $steps[$newStatus]
                ]);

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'project_id' => $project->id,
                    'action' => 'เปลี่ยนสถานะ',
                    'description' => "เปลี่ยนสถานะจาก {$oldStatus} เป็น {$newStatus}",
                    'entity_type' => 'projects',
                    'entity_id' => $project->id,
                ]);
            });

            return response()->json([
                'success' => true,
                'data' => $project->fresh(),
                'message' => "เปลี่ยนสถานะเป็น {$newStatus} สำเร็จ"
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'STATUS_UPDATE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // POST /api/projects/{id}/products — Add product
    public function storeProduct(Request $request, $id): JsonResponse
    {
        $project = Project::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'qty' => 'required|integer|min:1',
            'specs' => 'nullable|string',
            'target_date' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'ข้อมูลสินค้าไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        try {
            $product = DB::transaction(function () use ($request, $project) {
                $product = ProductItem::create([
                    'project_id' => $project->id,
                    'name' => $request->name,
                    'qty' => $request->qty,
                    'specs' => $request->specs,
                    'target_date' => $request->target_date,
                ]);

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'project_id' => $project->id,
                    'action' => 'เพิ่มสินค้า',
                    'description' => "เพิ่มสินค้า {$product->name} จำนวน {$product->qty} ชิ้น",
                    'entity_type' => 'product_items',
                    'entity_id' => $product->id,
                ]);

                return $product;
            });

            return response()->json([
                'success' => true,
                'data' => $product,
                'message' => 'เพิ่มสินค้าสำเร็จ'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'CREATE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // PUT /api/projects/{id}/products/{pid} — Update product
    public function updateProduct(Request $request, $id, $pid): JsonResponse
    {
        $project = Project::findOrFail($id);
        $product = ProductItem::where('project_id', $project->id)->findOrFail($pid);

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'qty' => 'sometimes|required|integer|min:1',
            'specs' => 'nullable|string',
            'target_date' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'ข้อมูลสินค้าไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        try {
            DB::transaction(function () use ($request, $project, $product) {
                $product->update($request->all());

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'project_id' => $project->id,
                    'action' => 'อัปเดตสินค้า',
                    'description' => "อัปเดตสินค้า {$product->name}",
                    'entity_type' => 'product_items',
                    'entity_id' => $product->id,
                ]);
            });

            return response()->json([
                'success' => true,
                'data' => $product->fresh(),
                'message' => 'อัปเดตสินค้าสำเร็จ'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'UPDATE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // POST /api/projects/{id}/additional-requests — Add Additional Request
    public function storeAdditionalRequest(Request $request, $id): JsonResponse
    {
        $project = Project::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'description' => 'required|string',
            'cost' => 'required|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'ข้อมูลไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        try {
            $req = DB::transaction(function () use ($request, $project) {
                $req = AdditionalRequest::create([
                    'project_id' => $project->id,
                    'description' => $request->description,
                    'cost' => $request->cost,
                ]);

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'project_id' => $project->id,
                    'action' => 'เพิ่มคำขอพิเศษ',
                    'description' => "เพิ่มคำขอพิเศษ: {$req->description} (ค่าใช้จ่าย: {$req->cost} บาท)",
                    'entity_type' => 'additional_requests',
                    'entity_id' => $req->id,
                ]);

                return $req;
            });

            return response()->json([
                'success' => true,
                'data' => $req,
                'message' => 'เพิ่มคำขอพิเศษสำเร็จ'
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'CREATE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // DELETE /api/projects/{id}/products/{pid} — Delete product
    public function destroyProduct($id, $pid): JsonResponse
    {
        $project = Project::findOrFail($id);
        $product = ProductItem::where('project_id', $project->id)->findOrFail($pid);

        try {
            DB::transaction(function () use ($project, $product) {
                $product->delete();

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'project_id' => $project->id,
                    'action' => 'ลบสินค้า',
                    'description' => "ลบสินค้า {$product->name} ออกจากโปรเจกต์",
                    'entity_type' => 'product_items',
                    'entity_id' => $product->id,
                ]);
            });

            return response()->json([
                'success' => true,
                'message' => 'ลบสินค้าสำเร็จ'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'DELETE_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }

    // GET /api/projects/{id}/logs — Get logs
    public function logs($id): JsonResponse
    {
        $project = Project::findOrFail($id);
        $logs = ActivityLog::with('user')
            ->where('project_id', $project->id)
            ->orderBy('created_at', 'desc')
            ->orderBy('id', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $logs
        ]);
    }

    // POST /api/projects/{id}/upload-po — Upload Client PO
    public function uploadPO(Request $request, $id): JsonResponse
    {
        $project = Project::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'file' => 'required|file|max:20480' // max 20MB
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'VALIDATION_ERROR',
                    'message' => 'ไฟล์ที่อัปโหลดไม่ถูกต้อง',
                    'details' => $validator->errors()
                ]
            ], 422);
        }

        try {
            $file = $request->file('file');
            $path = $file->store('po_files', 'public');
            $publicPath = Storage::url($path);

            DB::transaction(function () use ($project, $file, $publicPath) {
                $project->update([
                    'po_file_path' => $publicPath,
                    'po_file_name' => $file->getClientOriginalName()
                ]);

                // Activity Log
                ActivityLog::create([
                    'user_id' => auth()->id(),
                    'project_id' => $project->id,
                    'action' => 'อัปโหลด PO',
                    'description' => "อัปโหลดใบสั่งซื้อจากลูกค้า (Client PO) ไฟล์ {$file->getClientOriginalName()}",
                    'entity_type' => 'projects',
                    'entity_id' => $project->id,
                ]);
            });

            return response()->json([
                'success' => true,
                'po_file_name' => $file->getClientOriginalName(),
                'po_file_path' => $publicPath,
                'message' => 'อัปโหลดใบสั่งซื้อสำเร็จ'
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'UPLOAD_FAILED',
                    'message' => $e->getMessage()
                ]
            ], 500);
        }
    }
}
