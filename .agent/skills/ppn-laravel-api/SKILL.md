# PPN GREAT — Laravel Backend API Skill

## Description
Skill สำหรับเขียน Backend API ระบบ PPN GREAT ERP ด้วย Laravel 11 + MySQL + JWT Auth
ใช้เมื่อ: สร้าง Controller, Model, Migration, Route, หรือแก้ไข Backend code ใดๆ

## Context
- **โปรเจกต์:** PPN GREAT ERP — ระบบจัดการธุรกิจนำเข้าสินค้าพรีเมียมจากจีน
- **Tech Stack:** Laravel 11, PHP 8.3, MySQL, JWT Auth (tymon/jwt-auth)
- **Hosting:** Hostatom (Plesk Panel), Shared Hosting
- **Frontend:** Flutter Web เรียก REST API ผ่าน HTTP + JSON
- **Database:** 2 ชุด — ppn_production (ตัวจริง) + ppn_staging (ทดสอบ)

## Rules — ต้องทำตามทุกข้อ!

### 1. API Response Format (ใช้เหมือนกันหมดทุก Endpoint)

สำเร็จ (Single item):
```json
{
    "success": true,
    "data": { "id": 1, "name": "..." },
    "message": "สร้างสำเร็จ"
}
```

สำเร็จ (List + Pagination):
```json
{
    "success": true,
    "data": [ {...}, {...} ],
    "meta": {
        "current_page": 1,
        "last_page": 5,
        "per_page": 20,
        "total": 100
    }
}
```

Error:
```json
{
    "success": false,
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "กรุณากรอกชื่อลูกค้า",
        "details": { "name": ["กรุณากรอกชื่อ"] }
    }
}
```

### 2. Naming Conventions

| ประเภท | รูปแบบ | ตัวอย่าง |
|--------|--------|---------|
| Table | snake_case พหูพจน์ | `customers`, `stock_items` |
| Model | PascalCase เอกพจน์ | `Customer`, `StockItem` |
| Controller | PascalCase+Controller | `CustomerController` |
| Foreign Key | {table_singular}_id | `customer_id`, `project_id` |
| Route | /api/{resource} | `/api/customers` |
| Migration | create_{table}_table | `create_customers_table` |
| Form Request | Store/Update+Model+Request | `StoreCustomerRequest` |
| Service | PascalCase+Service | `ProjectCodeService` |

### 3. Controller Template

ทุก Controller ต้องเขียนตามโครงสร้างนี้:

```php
<?php

namespace App\Http\Controllers;

use App\Models\ModelName;
use App\Http\Requests\StoreModelNameRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ModelNameController extends Controller
{
    // GET /api/resource — List + Search + Paginate
    public function index(Request $request): JsonResponse
    {
        $query = ModelName::query();

        // Search
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where('name', 'like', "%{$search}%");
        }

        // Filter
        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        // Sort
        $sortBy = $request->get('sort', 'created_at');
        $order = $request->get('order', 'desc');
        $query->orderBy($sortBy, $order);

        // Paginate
        $perPage = $request->get('per_page', 20);
        $items = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $items->items(),
            'meta' => [
                'current_page' => $items->currentPage(),
                'last_page' => $items->lastPage(),
                'per_page' => $items->perPage(),
                'total' => $items->total(),
            ]
        ]);
    }

    // GET /api/resource/{id} — Detail
    public function show($id): JsonResponse
    {
        $item = ModelName::with(['relation1', 'relation2'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $item
        ]);
    }

    // POST /api/resource — Create
    public function store(StoreModelNameRequest $request): JsonResponse
    {
        try {
            $item = DB::transaction(function () use ($request) {
                $item = ModelName::create($request->validated());

                // บันทึก Activity Log
                \App\Models\ActivityLog::create([
                    'user_id' => auth()->id(),
                    'action' => 'สร้าง ModelName',
                    'description' => "สร้าง {$item->name}",
                    'entity_type' => 'model_name',
                    'entity_id' => $item->id,
                ]);

                return $item;
            });

            return response()->json([
                'success' => true,
                'data' => $item,
                'message' => 'สร้างสำเร็จ'
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

    // PUT /api/resource/{id} — Update
    public function update(Request $request, $id): JsonResponse
    {
        $item = ModelName::findOrFail($id);
        $item->update($request->validated());

        return response()->json([
            'success' => true,
            'data' => $item->fresh(),
            'message' => 'อัปเดตสำเร็จ'
        ]);
    }
}
```

### 4. Model Template

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ModelName extends Model
{
    protected $fillable = [
        // ระบุทุก field ที่ mass-assign ได้
    ];

    protected $casts = [
        // cast type ให้ถูกต้อง
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    // ===== Relationships =====

    public function relatedModel()
    {
        return $this->belongsTo(RelatedModel::class);
    }

    public function childModels()
    {
        return $this->hasMany(ChildModel::class);
    }
}
```

### 5. Migration Template

```php
public function up(): void
{
    Schema::create('table_name', function (Blueprint $table) {
        $table->id();
        // fields...
        $table->timestamps();

        // Foreign Keys ต้องใส่เสมอ!
        $table->foreign('parent_id')->references('id')->on('parents');
    });
}
```

### 6. สถานะ ENUM ที่ใช้ในระบบ

```
User Roles:       super_admin (ตอนนี้แค่นี้ก่อน — เพิ่มทีหลังได้)
Project Status:   Inquiry → Sample → Production → Shipping → Distributing → Delivered | Cancelled
Finance Doc Type: QU (ใบเสนอราคา), PI (แจ้งหนี้), DP (มัดจำ)
                  ⚠️ CI รอลูกค้ายืนยัน → ข้ามไปก่อน
Finance Status:   Draft → Sent → Paid → Overdue | Cancelled
Quote Status:     Waiting Link → Link Sent → Price Filled → Approved
Client Sample:    Waiting from China → Received from China → Sent to Client → Delivered to Client → Approved | Rejected
Artwork Status:   Awaiting Approval → Reviewing → Need Revision → Rejected → Approved by Client → Approved by Supplier
Container Status: Factory to Port → Sailing → Port to Warehouse → Delivered
Payment Status:   Pending Verification → Confirmed
Dispatch Status:  Scheduled → In Transit → Delivered
Stock Movement:   IN, OUT, ADJUST
Currency (Supplier): USD
Currency (Client):   THB อย่างเดียว (ไม่ต้องมี currency field ในเอกสารฝั่งลูกค้า)
```

### 7. Auto-generate Number Rules

```
Project Code:   PPN-001, PPN-002      → ไม่รีเซ็ตรายปี, 3 หลัก
Finance Doc:    QU-2026-0001           → รีเซ็ตรายปี, 4 หลัก
Sample Code:    CS-001                 → ไม่รีเซ็ต, 3 หลัก
Artwork Code:   ART-001               → ไม่รีเซ็ต, 3 หลัก
Dispatch Code:  DSP-001               → ไม่รีเซ็ต, 3 หลัก
Container Code: CTN-001               → ไม่รีเซ็ต, 3 หลัก
```

### 8. จุดตายที่ต้องระวังเสมอ

1. **ตัดสต็อก (Delivery Confirm):** ต้องใช้ `DB::transaction()` + `lockForUpdate()` เสมอ — ห้ามตัดสต็อกนอก Transaction!
2. **Due Date:** คำนวณจาก `issue_date + credit_term` อัตโนมัติ
3. **Activity Log:** บันทึกทุกการสร้าง/แก้ไข/เปลี่ยนสถานะ
4. **เลขเอกสาร:** ห้ามซ้ำ! ใช้ lockForUpdate ป้องกัน Race Condition
5. **CORS:** ต้องตั้งใน config/cors.php ให้ Flutter Web เรียกได้
6. **Pagination:** ทุก List API ต้อง Paginate (default per_page=20)
7. **Search:** ทุก List API ต้องรองรับ ?search= parameter
8. **File Upload:** เก็บใน storage/app/public/{type}/{project_id}/ + Symbolic Link
9. **Role:** ตอนนี้ Super Admin only → ไม่ต้องเช็คสิทธิ์แยก Role → เพิ่มทีหลัง
10. **Currency:** Supplier = USD / ลูกค้า = THB เท่านั้น
11. **Invoice (CI):** ⚠️ ข้ามไปก่อน รอลูกค้ายืนยัน

### 9. Database Tables (26 ตาราง)

```
users, customers, contact_persons, shipping_addresses,
projects, product_items, product_variations, product_files,
additional_requests, suppliers, quote_requests, supplier_samples,
supplier_bills, client_samples, artwork_logs, finance_documents,
finance_doc_items, payments, containers, container_projects,
warehouses, stock_items, stock_movements, dispatch_rounds,
delivery_items, activity_logs
```

### 10. API Endpoints ทั้งหมด (76 อัน — ข้าม CI)

**Auth (3):** login, logout, me
**Dashboard (3):** summary, activities, revenue-chart
**Customers (9):** CRUD + contacts + addresses + stats
**Projects (9):** CRUD + status pipeline + products + additional-requests + logs
**Suppliers (4):** CRUD
**Quotes (5):** CRUD + generate-link
**Supplier Samples (4):** CRUD + status
**Supplier Bills (4):** CRUD + pay + upload
**Client Samples (5):** CRUD + status
**Artwork (6):** CRUD + status + feedback
**Finance Docs (5):** CRUD + status (⚠️ ไม่มี CI + ไม่มี PDF ก่อน)
**Payments (4):** CRUD + verify + upload-slip
**Containers (5):** CRUD + step
**Inventory (5):** warehouses + stocks + receive + movements + low-stock
**Delivery (5):** CRUD + confirm (ตัดสต็อก!) + complete
**Reports (4):** financial + operational + revenue-by-month + profit-by-project
