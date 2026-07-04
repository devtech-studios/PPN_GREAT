# 📅 PPN GREAT — แผนงาน 8 วัน (4-11 ก.ค. 2026)

> **เป้าหมาย:** Backend Laravel API ครบทุกโมดูล พร้อมให้ Frontend เชื่อมต่อ  
> **Tech:** Laravel 11 + MySQL + JWT Auth + Hostatom  
> **Scope:** 26 ตาราง, 81 Endpoints, 11 โมดูล

---

## 📊 ภาพรวมแผน 8 วัน

```
วัน 1 (4 ก.ค.)  █████░░░░░░░░░░░  Foundation  — Setup + DB + Auth
วัน 2 (5 ก.ค.)  █████████░░░░░░░  Core        — Customers + Projects
วัน 3 (6 ก.ค.)  █████████████░░░  Supplier    — Suppliers + Quotes + Samples + Bills
วัน 4 (7 ก.ค.)  ████████████████  Finance     — Docs (QU/PI/DP/CI) + Payments
วัน 5 (8 ก.ค.)  ████████████████  Operations  — Client Samples + Artwork
วัน 6 (9 ก.ค.)  ████████████████  Logistics   — Containers + Inventory + Delivery
วัน 7 (10 ก.ค.) ████████████████  Summary     — Dashboard + Reports + Activity Log
วัน 8 (11 ก.ค.) ████████████████  Deploy      — Testing + Staging + Production Deploy
```

---

## 📌 วันที่ 1 (4 ก.ค. 2026) — Foundation

### เป้าหมาย: ตั้ง Project + Database + Auth ให้เสร็จ

| เวลา | งาน | รายละเอียด |
|------|-----|-----------|
| **เช้า** | ซื้อ Domain + ตั้งค่า Hosting | ซื้อ Domain สำหรับ PPN GREAT, ชี้ DNS ไปที่ Hostatom |
| **เช้า** | สร้าง Laravel Project | `composer create-project laravel/laravel ppn-api` |
| **เช้า** | ตั้งค่า .env | DB_HOST, DB_DATABASE, DB_USERNAME, DB_PASSWORD |
| **เช้า** | สร้าง MySQL Database 2 อัน | `ppn_production` + `ppn_staging` ผ่าน Plesk |
| **บ่าย** | ติดตั้ง JWT Auth | `composer require tymon/jwt-auth` + config |
| **บ่าย** | สร้าง Migration ทั้งหมด (26 ตาราง) | เขียน Migration Files ทุกตาราง |
| **บ่าย** | Run Migration | `php artisan migrate` ทั้ง 2 Database |
| **บ่าย** | สร้าง Auth API | Login, Logout, Me (3 endpoints) |
| **ค่ำ** | ทดสอบ Auth | ทดสอบ Login ผ่าน Postman / Thunder Client |

### Deliverables วันที่ 1:
```
✅ Laravel Project พร้อมใช้งาน
✅ Database 2 อัน (Production + Staging) มีตาราง 26 ตาราง
✅ JWT Auth ทำงานได้ (Login → ได้ Token → เรียก /me ได้)
✅ CORS ตั้งค่าเรียบร้อย (Flutter เรียก API ได้)
```

### คำสั่งที่ต้องรัน:

```bash
# 1. สร้าง Project
composer create-project laravel/laravel ppn-api
cd ppn-api

# 2. ติดตั้ง JWT
composer require tymon/jwt-auth
php artisan jwt:secret

# 3. แก้ .env
# DB_CONNECTION=mysql
# DB_HOST=localhost
# DB_PORT=3306
# DB_DATABASE=ppn_staging    ← เริ่มทดสอบที่ Staging ก่อน
# DB_USERNAME=xxxxx
# DB_PASSWORD=xxxxx

# 4. สร้าง Migration
php artisan make:migration create_users_table
php artisan make:migration create_customers_table
# ... (26 ตาราง)

# 5. Run Migration
php artisan migrate

# 6. สร้าง Seeder ข้อมูลจำลอง
php artisan make:seeder DummyDataSeeder
php artisan db:seed
```

---

## 📌 วันที่ 2 (5 ก.ค. 2026) — Core: Customers + Projects

### เป้าหมาย: CRUD ลูกค้าและโปรเจกต์ (หัวใจของระบบ)

| เวลา | งาน | Endpoints |
|------|-----|-----------|
| **เช้า** | Customer Model + Controller | 6 endpoints |
| **เช้า** | ContactPerson Controller | 3 endpoints |
| **บ่าย** | Project Model + Controller | 5 endpoints |
| **บ่าย** | ProductItem Controller | 2 endpoints |
| **บ่าย** | AdditionalRequest Controller | 1 endpoint |
| **ค่ำ** | Project Status Pipeline | PATCH status (เลื่อน Step) |
| **ค่ำ** | ProjectCode Auto-generate | Service สร้างเลข PPN-001 |
| **ค่ำ** | Activity Log | Model + เริ่มบันทึก Log |

### Deliverables วันที่ 2:
```
✅ Customer CRUD (สร้าง/แก้ไข/ดู/ค้นหา + ผู้ติดต่อ + ที่อยู่)    → 9 endpoints
✅ Project CRUD (สร้าง/แก้ไข/ดู/ค้นหา/เปลี่ยนสถานะ)             → 9 endpoints
✅ Auto-generate Project Code (PPN-001, PPN-002...)
✅ Activity Log เริ่มทำงาน
```

### โค้ดสำคัญวันนี้:

```php
// Routes: routes/api.php
Route::middleware('jwt.auth')->group(function () {
    // Customers
    Route::apiResource('customers', CustomerController::class);
    Route::post('customers/{id}/contacts', [ContactPersonController::class, 'store']);
    Route::put('customers/{id}/contacts/{cid}', [ContactPersonController::class, 'update']);
    Route::delete('customers/{id}/contacts/{cid}', [ContactPersonController::class, 'destroy']);
    Route::post('customers/{id}/addresses', [ShippingAddressController::class, 'store']);
    Route::get('customers/{id}/stats', [CustomerController::class, 'stats']);

    // Projects
    Route::apiResource('projects', ProjectController::class);
    Route::patch('projects/{id}/status', [ProjectController::class, 'updateStatus']);
    Route::post('projects/{id}/products', [ProductItemController::class, 'store']);
    Route::put('projects/{id}/products/{pid}', [ProductItemController::class, 'update']);
    Route::post('projects/{id}/additional-requests', [AdditionalRequestController::class, 'store']);
    Route::get('projects/{id}/logs', [ProjectController::class, 'logs']);
});
```

---

## 📌 วันที่ 3 (6 ก.ค. 2026) — Supplier ทั้งระบบ

### เป้าหมาย: Supplier CRUD + ขอราคา + ขอตัวอย่าง + AP

| เวลา | งาน | Endpoints |
|------|-----|-----------|
| **เช้า** | Supplier Model + Controller | 4 endpoints |
| **เช้า** | QuoteRequest Controller | 5 endpoints |
| **เช้า** | Session Link Generator | สร้าง Token ลิงก์ให้ Supplier กรอกราคา |
| **บ่าย** | SupplierSample Controller | 4 endpoints |
| **บ่าย** | SupplierBill Controller (AP) | 4 endpoints |
| **ค่ำ** | File Upload สำหรับ Bill | อัปโหลด PI / Invoice ของ Supplier |
| **ค่ำ** | ทดสอบ Flow ครบ | ขอราคา → ส่งลิงก์ → กรอกราคา → Approve |

### Deliverables วันที่ 3:
```
✅ Supplier CRUD                                                   → 4 endpoints
✅ Quote Request (ขอราคา + ส่งลิงก์ + Manual Input + Approve)       → 5 endpoints
✅ Supplier Sample (ขอตัวอย่างจากโรงงาน)                            → 4 endpoints
✅ Supplier Bill / AP (บิลจ่ายเงิน + Mark as Paid + Upload Doc)    → 4 endpoints
✅ รวม: 17 endpoints
```

---

## 📌 วันที่ 4 (7 ก.ค. 2026) — Finance ทั้งระบบ

### เป้าหมาย: เอกสาร QU/PI/DP/CI + รับเงิน + Auto-numbering

| เวลา | งาน | Endpoints |
|------|-----|-----------|
| **เช้า** | FinanceDocument Model + Controller | 5 endpoints |
| **เช้า** | DocNumberService | Auto-generate QU-2026-0001 |
| **เช้า** | FinanceDocItem (รายการในเอกสาร) | CRUD ภายในเอกสาร |
| **บ่าย** | Credit Term → Due Date | คำนวณกำหนดชำระอัตโนมัติ |
| **บ่าย** | Payment Controller (AR) | 4 endpoints |
| **บ่าย** | Upload สลิป | File Upload สำหรับสลิปโอนเงิน |
| **ค่ำ** | Overdue Detection | Scheduled Task เช็คบิลเลยกำหนด |
| **ค่ำ** | ทดสอบ Flow | QU → PI → จ่ายมัดจำ → CI → จ่ายครบ |

### Deliverables วันที่ 4:
```
✅ Finance Document CRUD (QU/PI/DP/CI)                              → 6 endpoints
✅ Auto-generate เลขเอกสาร (QU-2026-0001, PI-2026-0001...)
✅ Due Date คำนวณจาก Credit Term อัตโนมัติ
✅ Payment (บันทึกรับเงิน + Upload สลิป + ยืนยัน)                    → 4 endpoints
✅ รวม: 10 endpoints
```

### โค้ดสำคัญวันนี้:

```php
// DocNumberService.php — Auto-generate เลขเอกสาร
public static function generate(string $type): string
{
    $year = date('Y');
    $lastDoc = FinanceDocument::where('doc_type', $type)
        ->whereYear('created_at', $year)
        ->orderBy('id', 'desc')
        ->first();

    $nextNumber = $lastDoc
        ? intval(substr($lastDoc->doc_no, -4)) + 1
        : 1;

    return sprintf('%s-%s-%04d', $type, $year, $nextNumber);
}
```

---

## 📌 วันที่ 5 (8 ก.ค. 2026) — Client Samples + Artwork

### เป้าหมาย: ระบบติดตามตัวอย่างสินค้า + Artwork

| เวลา | งาน | Endpoints |
|------|-----|-----------|
| **เช้า** | ClientSample Model + Controller | 5 endpoints |
| **เช้า** | Sample Tracking (2 ขา: จีน→PPN, PPN→ลูกค้า) | Update tracking fields |
| **เช้า** | Multi-attempt (ส่งใหม่ได้หลายครั้ง) | attempt field + logic |
| **บ่าย** | ArtworkLog Model + Controller | 6 endpoints |
| **บ่าย** | Artwork File Upload | Upload + store ไฟล์ Artwork |
| **บ่าย** | Version Management | V1, V2, V2.1 (Factory Proof) |
| **ค่ำ** | ทดสอบ Flow | อัปโหลด V1 → Reject → V2 → Approve |

### Deliverables วันที่ 5:
```
✅ Client Sample (ส่งตัวอย่าง + Tracking 2 ขา + Multi-attempt)     → 5 endpoints
✅ Artwork Tracking (อัปโหลด + Version + Status + Feedback)         → 6 endpoints
✅ File Upload ทำงานจริง (เก็บไฟล์บน Hosting)
✅ รวม: 11 endpoints
```

---

## 📌 วันที่ 6 (9 ก.ค. 2026) — Logistics: Container + Inventory + Delivery

### เป้าหมาย: ติดตามตู้ + คลัง + จัดส่ง + ⚠️ ตัดสต็อก

| เวลา | งาน | Endpoints |
|------|-----|-----------|
| **เช้า** | Container Model + Controller | 5 endpoints |
| **เช้า** | Container ↔ Projects (Many-to-Many) | Pivot table |
| **เช้า** | 3-Step Tracking (Factory→Port→Sail→Warehouse) | PATCH step |
| **บ่าย** | Warehouse + StockItem | 3 endpoints |
| **บ่าย** | Stock Receive (รับเข้าคลัง) | POST receive + StockMovement |
| **บ่าย** | DispatchRound + DeliveryItem | 3 endpoints |
| **ค่ำ** | ⚠️ ตัดสต็อก (Atomic Transaction) | Confirm Dispatch → ตัด Stock |
| **ค่ำ** | StockMovement Log | บันทึกทุกครั้งที่สต็อกเปลี่ยน |

### Deliverables วันที่ 6:
```
✅ Container Tracking (3 ขั้นตอน + เชื่อม Projects)                 → 5 endpoints
✅ Inventory (คลัง + สต็อก + รับเข้า + ประวัติ + Low Stock)          → 5 endpoints
✅ Delivery (รอบส่ง + ยืนยัน → ตัดสต็อก Transaction)                 → 5 endpoints
✅ ⚠️ Atomic Transaction ทำงานถูกต้อง (ตัดสต็อก + บันทึก Movement)
✅ รวม: 15 endpoints
```

### ⚠️ โค้ดสำคัญที่สุดของวัน (ตัดสต็อก):

```php
// DeliveryController.php → confirm()
public function confirm($id)
{
    $dispatch = DispatchRound::with('items')->findOrFail($id);

    DB::transaction(function () use ($dispatch) {
        foreach ($dispatch->items as $item) {
            $stock = StockItem::where([
                'product_item_id' => $item->product_item_id,
                'warehouse_id' => $item->warehouse_id,
            ])->lockForUpdate()->first();

            if (!$stock || $stock->qty_in_stock < $item->qty_to_deliver) {
                throw new \Exception("สต็อกไม่เพียงพอ: {$item->product_item_id}");
            }

            $stock->decrement('qty_in_stock', $item->qty_to_deliver);

            StockMovement::create([
                'stock_item_id' => $stock->id,
                'movement_type' => 'OUT',
                'qty' => $item->qty_to_deliver,
                'reference_type' => 'dispatch_round',
                'reference_id' => $dispatch->id,
            ]);
        }

        $dispatch->update(['status' => 'In Transit']);
    });

    return response()->json(['success' => true, 'message' => 'ยืนยันรอบส่งและตัดสต็อกเรียบร้อย']);
}
```

---

## 📌 วันที่ 7 (10 ก.ค. 2026) — Dashboard + Reports + Polish

### เป้าหมาย: รวมข้อมูลจากทุกส่วน + สรุปรายงาน

| เวลา | งาน | Endpoints |
|------|-----|-----------|
| **เช้า** | Dashboard Summary API | 1 endpoint (รวม KPI จากหลายตาราง) |
| **เช้า** | Recent Activities API | 1 endpoint (ดึง Activity Log) |
| **เช้า** | Revenue Chart API | 1 endpoint (รายได้รายเดือน) |
| **บ่าย** | Reports: Financial Summary | 1 endpoint |
| **บ่าย** | Reports: Operational Summary | 1 endpoint |
| **บ่าย** | Reports: Revenue by Month | 1 endpoint |
| **บ่าย** | Reports: Profit by Project | 1 endpoint |
| **ค่ำ** | Customer Stats API | สถิติลูกค้า (Revenue, Payment %) |
| **ค่ำ** | Polish: Error Handling | จัดการ Error Response ให้เป็นระบบ |
| **ค่ำ** | Polish: Validation | ใส่ Validation Rules ทุก Request |

### Deliverables วันที่ 7:
```
✅ Dashboard API (Summary + Activity + Chart)                       → 3 endpoints
✅ Reports API (Financial + Operational + Revenue + Profit)          → 4 endpoints
✅ Error Handling เป็นระบบ
✅ Request Validation ครบทุก endpoint
```

### โค้ดสำคัญวันนี้:

```php
// DashboardController.php
public function summary()
{
    return response()->json([
        'success' => true,
        'data' => [
            'active_projects' => Project::whereNotIn('status', ['Delivered', 'Cancelled'])->count(),
            'pending_orders' => Project::where('status', 'Inquiry')->count(),
            'revenue_mtd' => Payment::where('status', 'Confirmed')
                ->whereMonth('payment_date', now()->month)
                ->whereYear('payment_date', now()->year)
                ->sum('amount'),
            'pending_payments' => FinanceDocument::where('status', 'Sent')
                ->sum('total_amount') - Payment::where('status', 'Confirmed')->sum('amount'),
        ]
    ]);
}
```

---

## 📌 วันที่ 8 (11 ก.ค. 2026) — Testing + Deploy 🚀

### เป้าหมาย: ทดสอบทุก API + Deploy ขึ้น Production

| เวลา | งาน | รายละเอียด |
|------|-----|-----------|
| **เช้า** | ทดสอบ API ทุก Endpoint | ใช้ Postman / Thunder Client ทดสอบทุก API |
| **เช้า** | แก้ Bug ที่เจอ | Fix ปัญหาที่พบจากการทดสอบ |
| **บ่าย** | Seed Data สำหรับ Staging | ใส่ข้อมูลจำลองให้สมจริง |
| **บ่าย** | Deploy ขึ้น Staging | Upload ไปที่ Hostatom → ทดสอบผ่าน URL จริง |
| **บ่าย** | ทดสอบ Staging | ทดสอบ API ผ่าน HTTPS ว่าทำงานได้ |
| **ค่ำ** | Deploy ขึ้น Production | เปลี่ยน .env ใช้ Production DB → Deploy |
| **ค่ำ** | ทดสอบ Production | ทดสอบ Login + ดึงข้อมูล |
| **ค่ำ** | เขียนเอกสาร API | สรุป API Doc สำหรับ Frontend เชื่อมต่อ |

### Deliverables วันที่ 8:
```
✅ ทุก API ทดสอบผ่าน (81 endpoints)
✅ Staging Deploy สำเร็จ (ข้อมูลจำลอง)
✅ Production Deploy สำเร็จ (ข้อมูลว่าง พร้อมใช้งาน)
✅ API Documentation
✅ 🎉 DONE! 🎉
```

### วิธี Deploy ขึ้น Hostatom (ผ่าน Plesk):

```bash
# วิธีที่ 1: อัปโหลดผ่าน FTP
# 1. ใช้ FileZilla เชื่อมต่อ Hostatom
# 2. Upload โฟลเดอร์ ppn-api ไปที่ httpdocs/
# 3. ตั้งค่า Document Root ใน Plesk ชี้ไปที่ httpdocs/ppn-api/public/

# วิธีที่ 2: ใช้ Git (แนะนำ)
# 1. Push โค้ดขึ้น GitHub/GitLab
# 2. SSH เข้า Server
ssh username@thsv37.hostatom.com
cd httpdocs/ppn-api
git pull origin main
composer install --no-dev
php artisan migrate
php artisan config:cache
php artisan route:cache
```

---

## 📊 สรุปภาพรวม 8 วัน

| วัน | วันที่ | หัวข้อ | Endpoints | สถานะ |
|-----|--------|--------|-----------|-------|
| 1 | 4 ก.ค. | Foundation (Setup + DB + Auth) | 3 | ⬜ |
| 2 | 5 ก.ค. | Core (Customers + Projects) | 18 | ⬜ |
| 3 | 6 ก.ค. | Suppliers (Quotes + Samples + Bills) | 17 | ⬜ |
| 4 | 7 ก.ค. | Finance (Docs + Payments) | 10 | ⬜ |
| 5 | 8 ก.ค. | Operations (Client Samples + Artwork) | 11 | ⬜ |
| 6 | 9 ก.ค. | Logistics (Container + Inventory + Delivery) | 15 | ⬜ |
| 7 | 10 ก.ค. | Summary (Dashboard + Reports + Polish) | 7 | ⬜ |
| 8 | 11 ก.ค. | Deploy (Testing + Staging + Production) | 0 | ⬜ |
| | | **รวม** | **81** | |

---

## ⚠️ ความเสี่ยงและแผนสำรอง

| ความเสี่ยง | ผลกระทบ | แผนสำรอง |
|-----------|---------|---------|
| วัน 1 ติดตั้ง Hosting นาน | ทำ DB + Migration ช้า | เริ่ม Migration บนเครื่อง Dev ก่อน |
| วัน 6 ตัดสต็อกมี Bug | ข้อมูลสต็อกผิดพลาด | ทดสอบบน Staging ซ้ำหลายรอบ |
| Deploy ไม่สำเร็จ | เปิดใช้งานไม่ได้ | เตรียม FTP Upload เป็น Backup |
| ทำไม่ทัน 8 วัน | ขาด Reports / Dashboard | ตัด Reports ออก ทำทีหลัง (Priority ต่ำสุด) |

---

## 🏷️ Checklist รายวัน (Print ติดโต๊ะ!)

```
=== วันที่ 1 (4 ก.ค.) ===
□ ซื้อ Domain
□ ตั้งค่า Hosting + DNS
□ สร้าง Laravel Project
□ สร้าง MySQL DB 2 อัน
□ ติดตั้ง JWT Auth
□ เขียน + Run Migration 26 ตาราง
□ สร้าง Auth API (Login/Logout/Me)
□ ทดสอบ Auth ผ่าน

=== วันที่ 2 (5 ก.ค.) ===
□ Customer CRUD (9 endpoints)
□ Project CRUD (9 endpoints)
□ Auto-generate Project Code
□ Activity Log

=== วันที่ 3 (6 ก.ค.) ===
□ Supplier CRUD (4 endpoints)
□ Quote Request (5 endpoints)
□ Session Link Generator
□ Supplier Sample (4 endpoints)
□ Supplier Bill / AP (4 endpoints)

=== วันที่ 4 (7 ก.ค.) ===
□ Finance Document CRUD (6 endpoints)
□ DocNumberService (Auto-generate)
□ Credit Term → Due Date
□ Payment / AR (4 endpoints)
□ Upload Slip

=== วันที่ 5 (8 ก.ค.) ===
□ Client Sample (5 endpoints)
□ Multi-attempt + Tracking 2 ขา
□ Artwork Log (6 endpoints)
□ Artwork File Upload

=== วันที่ 6 (9 ก.ค.) ===
□ Container (5 endpoints)
□ Container ↔ Projects Pivot
□ Inventory (5 endpoints)
□ Delivery (5 endpoints)
□ ⚠️ Atomic Transaction ตัดสต็อก

=== วันที่ 7 (10 ก.ค.) ===
□ Dashboard API (3 endpoints)
□ Reports API (4 endpoints)
□ Error Handling
□ Validation Rules

=== วันที่ 8 (11 ก.ค.) ===
□ ทดสอบทุก API
□ แก้ Bug
□ Deploy Staging
□ Deploy Production
□ เขียน API Doc
□ 🎉 DONE!
```

---

> 📝 **สร้างโดย:** Antigravity AI Assistant  
> **วันที่:** 3 กรกฎาคม 2026
