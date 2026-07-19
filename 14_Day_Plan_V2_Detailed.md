# 📅 PPN GREAT — แผนงาน 14 วัน ฉบับละเอียด

> **เอกสารนี้เขียนให้ทำตามได้เลย** ทุก Checkbox คือ 1 งานที่ต้องทำ
> ทำเสร็จแล้วติ๊ก ✅ ไป จะได้ไม่ตกหล่น
> **ขอบเขตงาน:** Backend API (Laravel) + เชื่อมต่อ Frontend + Deploy Production + Security Testing
> **ระยะเวลา:** 14 วัน (1 – 14 กรกฎาคม 2026)

---

# 🗓️ วันที่ 1 (1 ก.ค. 2026) — Foundation

> **เป้าหมาย:** จบวันนี้ ต้อง Login ผ่าน API ได้ + Database 26 ตารางพร้อม

---

## ช่วงเช้า (08:00 - 12:00) — Setup โปรเจกต์

### 1.1 ซื้อ Domain + ตั้งค่า Hosting

```
□ ซื้อ Domain สำหรับ PPN GREAT (เช่น ppngreat.com หรือชื่อที่ต้องการ)
□ เข้า Plesk (thsv37.hostatom.com:8443)
□ กด "Add Domain" → ใส่ Domain ที่ซื้อ
□ กด "Add Subdomain" → สร้าง api.xxxxx.com (สำหรับ Laravel API)
□ กด "Add Subdomain" → สร้าง staging-api.xxxxx.com (สำหรับ Staging)
□ ตั้งค่า SSL Certificate (HTTPS) ให้ทั้ง 2 subdomain
□ จดบันทึก:
   - Production API URL: https://api.xxxxx.com
   - Staging API URL: https://staging-api.xxxxx.com
```

### 1.2 สร้าง MySQL Database 2 อัน

```
□ เข้า Plesk → Databases → Add Database
□ สร้าง Database #1: ppn_production / ppn_prod_user / (รหัสแข็งๆ)
□ สร้าง Database #2: ppn_staging / ppn_stag_user / (รหัสอื่น)
□ ทดสอบเข้า phpMyAdmin ได้ทั้ง 2 อัน
```

### 1.3 สร้าง Laravel Project + ตั้งค่า CORS

```
□ composer create-project laravel/laravel ppn-api && cd ppn-api
□ ทดสอบ: php artisan serve → เห็นหน้า Welcome
□ แก้ .env ชี้ไปที่ ppn_staging DB
□ ตั้งค่า config/cors.php สำหรับ Flutter Web
□ ทดสอบ: php artisan migrate → ผ่าน
```

---

## ช่วงบ่าย (13:00 - 17:00) — JWT Auth + Migrations

### 1.4 ติดตั้ง JWT Authentication

```
□ composer require tymon/jwt-auth
□ php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider"
□ php artisan jwt:secret
□ แก้ config/auth.php → default guard = api (driver: jwt)
□ แก้ Model User.php → implements JWTSubject
```

### 1.5 เขียน Migration ทั้ง 26 ตาราง

```
□ users, customers, contact_persons, shipping_addresses
□ projects, product_items, product_variations, product_files, additional_requests
□ suppliers, quote_requests, supplier_samples, supplier_bills
□ client_samples, artwork_logs
□ finance_documents, finance_doc_items, payments
□ containers, container_projects
□ warehouses, stock_items, stock_movements
□ dispatch_rounds, delivery_items
□ activity_logs
□ Run Migration: php artisan migrate → ต้องผ่านไม่มี Error!
```

---

## ช่วงค่ำ (18:00 - 21:00) — Auth API + ทดสอบ

### 1.6 สร้าง Auth API (3 Endpoints) + ทดสอบ

```
□ POST /api/auth/login → รับ email+password → ส่ง JWT Token
□ POST /api/auth/logout → Invalidate Token
□ GET  /api/auth/me → ข้อมูล User ปัจจุบัน
□ สร้าง UserSeeder (admin@ppn.com / password123)
□ ทดสอบ Login/Me/Logout ผ่าน Postman ✅
```

### ✅ สรุปวันที่ 1:
```
✅ Domain + Hosting + SSL พร้อม
✅ MySQL 2 Database (production + staging)
✅ Laravel + JWT Auth + CORS
✅ Migration 26 ตาราง
✅ Auth API 3 endpoints ทำงานได้
```

---
---

# 🗓️ วันที่ 2 (2 ก.ค. 2026) — Core: Customers

> **เป้าหมาย:** สร้าง/แก้ไข/ค้นหา ลูกค้าได้ครบ

---

## ช่วงเช้า-บ่าย (08:00 - 17:00) — Customer CRUD (9 Endpoints)

```
□ GET    /api/customers                       → List + Search + Paginate
□ GET    /api/customers/{id}                  → รายละเอียด (include: contacts, addresses, projects)
□ POST   /api/customers                       → สร้างลูกค้า + contacts + addresses (DB::transaction)
□ PUT    /api/customers/{id}                  → แก้ไข
□ POST   /api/customers/{id}/contacts         → เพิ่มผู้ติดต่อ
□ PUT    /api/customers/{id}/contacts/{cid}   → แก้ไขผู้ติดต่อ
□ DELETE /api/customers/{id}/contacts/{cid}   → ลบผู้ติดต่อ
□ POST   /api/customers/{id}/addresses        → เพิ่มที่อยู่จัดส่ง
□ GET    /api/customers/{id}/stats            → สถิติลูกค้า (Calculated fields)
```

## ช่วงค่ำ (18:00 - 21:00) — ทดสอบ

```
□ ทดสอบ สร้างลูกค้า + contacts + addresses ✅
□ ทดสอบ ค้นหาลูกค้า ✅
□ ทดสอบ ดูรายละเอียด + Stats ✅
```

### ✅ สรุปวันที่ 2:
```
✅ Customer CRUD ครบ 9 endpoints
✅ ทดสอบผ่าน Postman
✅ รวมสะสม: 12 endpoints
```

---
---

# 🗓️ วันที่ 3 (3 ก.ค. 2026) — Core: Projects + Activity Log

> **เป้าหมาย:** สร้าง/แก้ไข/ค้นหา โปรเจกต์ได้ครบ + Activity Log ทำงาน

---

## ช่วงเช้า-บ่าย (08:00 - 17:00) — Project CRUD (9 Endpoints)

```
□ GET    /api/projects                        → List + Filter by status + Search + Paginate
□ GET    /api/projects/{id}                   → รายละเอียดเต็ม (include: products, finance, logs)
□ POST   /api/projects                        → สร้าง Project + Products (auto project_code, DB::transaction)
□ PUT    /api/projects/{id}                   → แก้ไข
□ PATCH  /api/projects/{id}/status            → เปลี่ยนสถานะ (Pipeline Step)
□ POST   /api/projects/{id}/products          → เพิ่มสินค้า
□ PUT    /api/projects/{id}/products/{pid}    → แก้ไขสินค้า
□ POST   /api/projects/{id}/additional-requests → เพิ่มคำขอพิเศษ
□ GET    /api/projects/{id}/logs              → Activity Log ของ Project
```

## ช่วงค่ำ (18:00 - 21:00) — Activity Log + ทดสอบ

```
□ สร้าง ActivityLog Model + Helper
□ เพิ่ม Activity Log ใน: สร้าง Project, เปลี่ยนสถานะ
□ ทดสอบ สร้าง Project → project_code PPN-001 ✅
□ ทดสอบ เปลี่ยนสถานะ → Activity Log บันทึก ✅
```

### ✅ สรุปวันที่ 3:
```
✅ Project CRUD ครบ 9 endpoints
✅ Auto-generate Project Code (PPN-001, PPN-002)
✅ Activity Log ทำงาน
✅ รวมสะสม: 21 endpoints
```

---
---

# 🗓️ วันที่ 4 (4 ก.ค. 2026) — Suppliers ทั้งระบบ

> **เป้าหมาย:** จัดการ Supplier + ขอราคา + ขอตัวอย่าง + จ่ายเงิน ครบ

---

## ช่วงเช้า (08:00 - 12:00) — Supplier CRUD + Quotes

```
□ GET    /api/suppliers                                   → List + Search (4 endpoints)
□ GET    /api/suppliers/{id}                              → Detail (include: quotes, samples, bills)
□ POST   /api/suppliers                                   → สร้าง
□ PUT    /api/suppliers/{id}                              → แก้ไข
□ GET    /api/suppliers/{id}/quotes                       → List ใบขอราคา (5 endpoints)
□ POST   /api/suppliers/{id}/quotes                      → สร้างใบขอราคา
□ PUT    /api/suppliers/{id}/quotes/{qid}                 → อัปเดตราคา
□ PATCH  /api/suppliers/{id}/quotes/{qid}/status          → อัปเดตสถานะ
□ POST   /api/suppliers/{id}/quotes/{qid}/generate-link   → สร้าง Session Link
```

## ช่วงบ่าย (13:00 - 17:00) — Supplier Samples + Bills

```
□ GET    /api/suppliers/{id}/samples                      → List ตัวอย่าง (4 endpoints)
□ POST   /api/suppliers/{id}/samples                     → ขอตัวอย่าง
□ PUT    /api/suppliers/{id}/samples/{sid}                → แก้ไข
□ PATCH  /api/suppliers/{id}/samples/{sid}/status         → อัปเดตสถานะ
□ GET    /api/suppliers/{id}/bills                        → List บิล (4 endpoints)
□ POST   /api/suppliers/{id}/bills                       → สร้างบิล
□ PATCH  /api/suppliers/{id}/bills/{bid}/pay              → จ่ายเงิน (bulk pay)
□ POST   /api/suppliers/{id}/bills/{bid}/upload           → อัปโหลด PI/Invoice
```

## ช่วงค่ำ (18:00 - 21:00) — ทดสอบ Flow ครบ

```
□ ทดสอบ: สร้าง Supplier → Quote → Generate Link → Manual Input → Approve ✅
□ ทดสอบ: Sample Request → Update Tracking ✅
□ ทดสอบ: Bill → Pay → Upload PI ✅
```

### ✅ สรุปวันที่ 4:
```
✅ Supplier CRUD 4 + Quotes 5 + Samples 4 + Bills 4 = 17 endpoints
✅ รวมสะสม: 38 endpoints
```

---
---

# 🗓️ วันที่ 5 (5 ก.ค. 2026) — Finance ทั้งระบบ

> **เป้าหมาย:** ออกเอกสาร QU/PI/DP/CI + เก็บเงิน + Auto Doc Number

---

## ช่วงเช้า (08:00 - 12:00) — Finance Documents (6 Endpoints)

```
□ สร้าง DocNumberService (auto: QU-2026-0001, PI-2026-0001 ...)
□ GET    /api/finance/documents               → List + Filter type/status
□ GET    /api/finance/documents/{id}          → Detail (include: items)
□ POST   /api/finance/documents               → สร้าง (auto doc_no + auto due_date)
□ PUT    /api/finance/documents/{id}          → แก้ไข (เฉพาะ Draft)
□ PATCH  /api/finance/documents/{id}/status   → อัปเดตสถานะ (Draft→Sent→Paid)
□ POST   /api/finance/documents/{id}/pdf      → สร้าง PDF (Nice-to-have)
```

## ช่วงบ่าย (13:00 - 17:00) — Payments (4 Endpoints)

```
□ GET    /api/finance/payments                → List รายการรับเงิน
□ POST   /api/finance/payments                → บันทึกรับเงิน
□ PATCH  /api/finance/payments/{id}/verify    → ยืนยันรับเงิน
□ POST   /api/finance/payments/{id}/upload-slip → อัปโหลดสลิป
```

## ช่วงค่ำ (18:00 - 21:00) — Overdue Detection + ทดสอบ

```
□ สร้าง Artisan Command: CheckOverdueDocuments
□ ทดสอบ: สร้าง QU → doc_no QU-2026-0001 ✅
□ ทดสอบ: สร้าง PI → due_date = issue_date + 30 วัน ✅
□ ทดสอบ: Record Payment → deposit_paid เปลี่ยนเป็น true ✅
□ ทดสอบ: Upload Slip ✅
```

### ✅ สรุปวันที่ 5:
```
✅ Finance Document 6 + Payment 4 = 10 endpoints
✅ Auto Doc Number + Credit Term → Due Date
✅ รวมสะสม: 48 endpoints
```

---
---

# 🗓️ วันที่ 6 (6 ก.ค. 2026) — Client Samples + Artwork

> **เป้าหมาย:** ส่งตัวอย่างให้ลูกค้า + อัปโหลด Artwork ครบ

---

## ช่วงเช้า (08:00 - 12:00) — Client Samples (5 Endpoints)

```
□ GET    /api/samples                         → List Project ที่มี Sample
□ GET    /api/samples/project/{pid}           → Sample ทั้งหมดของ Project
□ POST   /api/samples                         → สร้าง Sample (auto code + auto attempt)
□ PUT    /api/samples/{id}                    → แก้ไข
□ PATCH  /api/samples/{id}/status             → อัปเดตสถานะ + feedback
```

## ช่วงบ่าย (13:00 - 17:00) — Artwork (6 Endpoints)

```
□ GET    /api/artworks                        → List Project ที่มี Artwork
□ GET    /api/artworks/project/{pid}          → Artwork ทั้งหมดของ Project
□ POST   /api/artworks                        → เพิ่ม Artwork + Upload File
□ PUT    /api/artworks/{id}                   → แก้ไข
□ PATCH  /api/artworks/{id}/status            → อัปเดตสถานะ
□ PATCH  /api/artworks/{id}/feedback          → อัปเดต feedback
```

## ช่วงค่ำ (18:00 - 21:00) — ทดสอบ

```
□ ทดสอบ Sample Flow: attempt=1 → Reject → attempt=2 → Approve ✅
□ ทดสอบ Artwork Flow: Upload V1 → Reject → Upload V2 → Approve ✅
```

### ✅ สรุปวันที่ 6:
```
✅ Client Sample 5 + Artwork 6 = 11 endpoints
✅ File Upload ทำงานจริง
✅ รวมสะสม: 59 endpoints
```

---
---

# 🗓️ วันที่ 7 (7 ก.ค. 2026) — Logistics: Container + Inventory + Delivery

> **เป้าหมาย:** ติดตามตู้ + คลัง + จัดส่ง + ⚠️ ตัดสต็อก (วันที่สำคัญที่สุด!)

---

## ช่วงเช้า (08:00 - 12:00) — Containers (5 Endpoints)

```
□ GET    /api/containers                      → List + Filter by status
□ GET    /api/containers/{id}                 → Detail + Projects inside
□ POST   /api/containers                      → สร้าง + เชื่อม project_ids
□ PUT    /api/containers/{id}                 → แก้ไข
□ PATCH  /api/containers/{id}/step            → อัปเดตขั้นตอน (Factory→Port→Sailing→Warehouse)
```

## ช่วงบ่าย (13:00 - 17:00) — Inventory (5 Endpoints)

```
□ GET    /api/inventory/warehouses                → List คลัง
□ GET    /api/inventory/warehouses/{id}/stocks    → สต็อกในคลัง + Search
□ POST   /api/inventory/receive                   → รับเข้าคลัง + StockMovement (IN)
□ GET    /api/inventory/movements                 → ประวัติ IN/OUT
□ GET    /api/inventory/low-stock                 → สต็อกใกล้หมด
```

## ช่วงค่ำ (18:00 - 21:00) — ⚠️ Delivery + ตัดสต็อก (5 Endpoints)

```
□ GET    /api/delivery/rounds                     → List รอบส่ง
□ GET    /api/delivery/rounds/{id}                → Detail + Items
□ POST   /api/delivery/rounds                     → สร้างรอบ + Items

□ PATCH  /api/delivery/rounds/{id}/confirm
   ⚠️⚠️⚠️ จุดสำคัญที่สุดของทั้ง 14 วัน ⚠️⚠️⚠️
   - ใช้ DB::transaction + lockForUpdate
   - ตัดสต็อกทุก delivery_item
   - ถ้าสต็อกไม่พอ → throw Exception → Rollback ทั้งหมด

□ PATCH  /api/delivery/rounds/{id}/complete → status = Delivered
□ ทดสอบ: ตัดสต็อกเกินกว่ามี → ต้อง Error + ไม่มีอะไรเปลี่ยน ✅
```

### ✅ สรุปวันที่ 7:
```
✅ Container 5 + Inventory 5 + Delivery 5 = 15 endpoints
✅ Atomic Transaction ตัดสต็อก ทดสอบผ่าน
✅ รวมสะสม: 74 endpoints
```

---
---

# 🗓️ วันที่ 8 (8 ก.ค. 2026) — Dashboard + Reports

> **เป้าหมาย:** รวมข้อมูลจากทุกส่วน แสดง KPI + กราฟ + รายงาน

---

## ช่วงเช้า-บ่าย (08:00 - 17:00) — Dashboard + Reports (7 Endpoints)

```
□ DashboardController:
   □ GET /api/dashboard/summary         → KPI 4 ตัว (active projects, pending orders, revenue MTD, pending payments)
   □ GET /api/dashboard/activities      → Activity Log ล่าสุด 20 รายการ
   □ GET /api/dashboard/revenue-chart   → Revenue by month (12 เดือนล่าสุด)

□ ReportController:
   □ GET /api/reports/financial-summary     → Revenue, COGS, Profit, Margin%
   □ GET /api/reports/operational-summary   → Active Projects, Avg Lead Time, On-time%
   □ GET /api/reports/revenue-by-month      → Bar Chart data
   □ GET /api/reports/profit-by-project     → กำไรรายโปรเจกต์
```

## ช่วงค่ำ (18:00 - 21:00) — ทดสอบ

```
□ ทดสอบ Dashboard summary → ค่า KPI ถูกต้อง ✅
□ ทดสอบ Revenue chart → ข้อมูลรายเดือน ✅
□ ทดสอบ Reports ทั้ง 4 ตัว ✅
```

### ✅ สรุปวันที่ 8:
```
✅ Dashboard 3 + Reports 4 = 7 endpoints
✅ รวมสะสม: 81 endpoints ✅ (ครบ!)
```

---
---

# 🗓️ วันที่ 9 (9 ก.ค. 2026) — Polish: Error Handling + Validation

> **เป้าหมาย:** ทำให้ API ทุกตัวมีคุณภาพระดับ Production

---

## ช่วงเช้า (08:00 - 12:00) — Error Handling

```
□ สร้าง/ปรับปรุง Handler.php:
   - 400 Bad Request → { "success": false, "error": { "code": "BAD_REQUEST" } }
   - 401 Unauthorized
   - 403 Forbidden
   - 404 Not Found → Response ภาษาไทย
   - 422 Validation Error → แสดง field + message ชัดเจน
   - 500 Server Error → ไม่แสดงข้อมูลภายใน (ซ่อน stack trace)
```

## ช่วงบ่าย (13:00 - 17:00) — Form Request Validation

```
□ php artisan make:request StoreCustomerRequest
□ php artisan make:request StoreProjectRequest
□ php artisan make:request StoreFinanceDocRequest
□ สร้าง Form Request สำหรับทุก POST/PUT endpoint สำคัญ
□ ตรวจสอบ Pagination ทุก List API (default 20 per page)
□ ตรวจสอบ Search ทุก List API รองรับ ?search= parameter
```

## ช่วงค่ำ (18:00 - 21:00) — Seed Data + เตรียม Config

```
□ สร้าง DummyDataSeeder:
   - 5 Customers + Contacts + Addresses
   - 10 Projects (คละสถานะ Inquiry → Delivered)
   - 3 Suppliers + Quotes + Samples + Bills
   - 5 Finance Documents
   - 2 Containers, 2 Warehouses + Stock
   - 1 Dispatch Round
□ Run Seed: php artisan db:seed → ข้อมูลจำลองพร้อม
□ เตรียมไฟล์ .env.production / .env.staging
```

### ✅ สรุปวันที่ 9:
```
✅ Error Handling มาตรฐานทั้งระบบ
✅ Form Request Validation ครบ
✅ Seed Data + Config Deploy พร้อม
```

---
---

# 🗓️ วันที่ 10 (10 ก.ค. 2026) — Frontend Integration Support

> **เป้าหมาย:** เตรียม API ให้ Frontend (Flutter) เรียกใช้ได้อย่างสมบูรณ์

---

## ช่วงเช้า-บ่าย (08:00 - 17:00) — Integration

```
□ ตรวจสอบ API Response Format สอดคล้องกัน (success/data/meta/error)
□ ตรวจ CORS Config สำหรับ Production Domain
□ ตรวจสอบ File Upload paths ถูกต้อง + accessible ผ่าน storage:link
□ ทดสอบ API ทั้งหมดจาก Flutter Web → ไม่มี Error
□ อัปเดต API Documentation (Postman Collection) ให้ครบ 81 endpoints
```

## ช่วงค่ำ (18:00 - 21:00) — Pre-deploy Checklist

```
□ ตรวจ .gitignore ว่า .env, storage, node_modules ไม่ถูก commit
□ ตรวจ Storage symlink: php artisan storage:link
□ ทดสอบ: php artisan config:cache + route:cache → ไม่มี Error
□ เตรียม Deployment script / คำสั่ง Upload
```

### ✅ สรุปวันที่ 10:
```
✅ API ทั้ง 81 endpoints พร้อมให้ Frontend เรียกใช้
✅ API Documentation + Postman Collection อัปเดต
✅ Pre-deploy checklist ผ่าน
```

---
---

# 🗓️ วันที่ 11 (11 ก.ค. 2026) — Deploy to Production 🚀

> **เป้าหมาย:** ทุกอย่างทำงานได้บน Server จริง!

---

## ช่วงเช้า (08:00 - 12:00) — Deploy Staging

```
□ Upload ไฟล์ไปที่ Hostatom (FTP / Git)
□ ตั้ง Document Root ชี้ไปที่ /ppn-api/public/
□ Copy .env.staging → .env
□ Run: composer install --no-dev
□ Run: php artisan migrate
□ Run: php artisan db:seed
□ Run: php artisan config:cache && php artisan route:cache
□ Run: php artisan storage:link
□ ทดสอบ: https://staging-api.xxxxx.com/api/auth/login → ได้ Token ✅
```

## ช่วงบ่าย (13:00 - 17:00) — Deploy Production

```
□ Copy ไฟล์เดียวกับ Staging
□ Copy .env.production → .env (ชี้ไป ppn_production DB)
□ Run: php artisan migrate (สร้างตารางเปล่า — ไม่ seed!)
□ Run: php artisan config:cache && php artisan route:cache
□ Run: php artisan storage:link
□ ทดสอบ: https://api.xxxxx.com/api/auth/login → ได้ Token ✅
```

## ช่วงค่ำ (18:00 - 21:00) — Smoke Test on Production

```
□ ทดสอบ Login/Logout/Me ✅
□ ทดสอบ สร้างลูกค้า + Project ✅
□ ทดสอบ Upload ไฟล์ (Artwork/Slip) ✅
□ ทดสอบ Dashboard + Reports ✅
```

### ✅ สรุปวันที่ 11:
```
✅ Staging Deploy สำเร็จ
✅ Production Deploy สำเร็จ
✅ Smoke Test ผ่าน
```

---
---

# 🗓️ วันที่ 12 (12 ก.ค. 2026) — Full Automated Testing

> **เป้าหมาย:** ทดสอบทุก API อย่างเป็นระบบ + ทดสอบ Full Flow

---

## ช่วงเช้า-บ่าย (08:00 - 17:00) — Automated Tests

```
□ เขียน/อัปเดต Laravel Feature Tests:
   □ AuthTest (Login/Me/Logout/Token Expired)
   □ CustomerTest (CRUD + Contacts + Addresses + Stats)
   □ ProjectTest (CRUD + Status Pipeline + Products + Logs)
   □ SupplierTest (CRUD + Quotes + Samples + Bills)
   □ FinanceTest (Documents + Payments + Auto Doc Number)
   □ SampleTest (Multi-attempt + Status Flow)
   □ ArtworkTest (Upload + Version + Status)
   □ ContainerTest (CRUD + Step Update)
   □ InventoryTest (Receive + Stock Check)
   □ DeliveryTest (Create + Confirm/Rollback + Complete)
   □ DashboardTest + ReportTest

□ Run: php artisan test → ผ่าน 100% ✅
```

## ช่วงค่ำ (18:00 - 21:00) — Newman (Postman) Tests

```
□ อัปเดต Postman Collection ครบ 81 endpoints
□ Run Newman: npx newman run PPN_GREAT_Postman_Collection.json → ผ่าน 100% ✅
□ ทดสอบ Full Flow ครบวงจร:
   สร้างลูกค้า → สร้าง Project → ขอราคา Supplier → สั่งผลิต →
   ส่งตัวอย่าง → อนุมัติ Artwork → ออกเอกสาร QU/PI →
   รับเงิน → ติดตามตู้ → รับเข้าคลัง → จัดส่ง → ตัดสต็อก ✅
```

### ✅ สรุปวันที่ 12:
```
✅ Laravel Feature Tests ผ่าน 100%
✅ Newman API Tests ผ่าน 100%
✅ Full Flow ครบวงจรทดสอบผ่าน
```

---
---

# 🗓️ วันที่ 13 (13 ก.ค. 2026) — OWASP Top 10:2025 Security Testing (Part 1)

> **เป้าหมาย:** ทดสอบความปลอดภัยตาม OWASP Top 10:2025 ข้อ A01-A05

---

## A01 — Broken Access Control

```
□ ทดสอบ IDOR (Insecure Direct Object Reference):
   - Login เป็น User A → เรียก GET /api/customers/{id ของ User B} → ต้องถูกบล็อก
   - ทำซ้ำกับทุก resource API (projects, suppliers, finance, etc.)
□ ทดสอบ SSRF:
   - ส่ง URL ภายนอกในฟิลด์ที่รับ input → ไม่ให้เซิร์ฟเวอร์เรียก URL นั้น
□ ตรวจ CORS Production:
   - allowed_origins ต้องระบุ Domain จริง ไม่ใช่ '*'
□ ทดสอบ Horizontal Privilege Escalation:
   - User role=sales พยายามลบ Customer ที่สร้างโดย role=admin → ต้องถูกบล็อก
□ ทดสอบ Vertical Privilege Escalation:
   - User role=designer พยายามเรียก /api/reports/* → ต้องได้ 403
```

## A02 — Security Misconfiguration

```
□ ตรวจ .env บน Production:
   - APP_DEBUG=false ✅
   - APP_ENV=production ✅
□ ตรวจ Response Headers:
   - ไม่มี X-Powered-By header ✅
   - มี X-Content-Type-Options: nosniff ✅
□ ตรวจว่า /api/config หรือ debug routes ไม่เปิดเผยข้อมูลภายใน
□ ตรวจ Directory Listing ปิด
□ ตรวจ phpinfo() ไม่มี route ให้เข้าถึง
```

## A03 — Software Supply Chain Failures

```
□ Run: composer audit → ตรวจ dependencies ที่มี CVE
□ ตรวจ composer.lock → ไม่มี package version ที่มีช่องโหว่ที่ทราบ
□ ตรวจ PHP version ไม่ล้าสมัย (>= 8.2)
□ ตรวจ Laravel version ไม่ล้าสมัย (>= 11.x)
□ ตรวจ tymon/jwt-auth ไม่มี known vulnerability
```

## A04 — Cryptographic Failures

```
□ ตรวจ JWT_SECRET:
   - ไม่ใช่ค่า default ✅
   - มีความยาวเพียงพอ (>= 32 chars) ✅
□ ตรวจรหัสผ่าน:
   - เก็บด้วย bcrypt ✅ (ไม่ใช่ MD5/SHA1)
   - ไม่เก็บเป็น plain text ✅
□ ตรวจ HTTPS:
   - Production URL บังคับ HTTPS ✅
   - redirect HTTP → HTTPS ✅
□ ตรวจ Sensitive data ไม่อยู่ใน:
   - API response ✅
   - Git commit ✅
   - Log files ✅
```

## A05 — Injection

```
□ ทดสอบ SQL Injection:
   - GET /api/customers?search=' OR 1=1 -- → ต้องไม่มี Error + ต้อง escape
   - ทดสอบกับ search, filter, sort parameters ทุก API
□ ทดสอบ XSS:
   - POST /api/customers → name: "<script>alert('xss')</script>" → ต้อง sanitize/escape
□ ทดสอบ Command Injection:
   - ส่ง payload ผ่าน file upload filename → ไม่ให้ execute
□ ตรวจว่าใช้ Eloquent ORM (parameterized queries) ไม่ใช่ raw SQL
```

### ✅ สรุปวันที่ 13:
```
✅ A01 Broken Access Control — ทดสอบผ่าน
✅ A02 Security Misconfiguration — ทดสอบผ่าน
✅ A03 Software Supply Chain — ทดสอบผ่าน
✅ A04 Cryptographic Failures — ทดสอบผ่าน
✅ A05 Injection — ทดสอบผ่าน
```

---
---

# 🗓️ วันที่ 14 (14 ก.ค. 2026) — OWASP Security Testing (Part 2) + Release 🎉

> **เป้าหมาย:** ทดสอบ OWASP ข้อ A06-A10 + แก้ไข Issues + Release v1.1.0

---

## A06 — Insecure Design

```
□ ตรวจ Business Logic:
   - ตัดสต็อกเกินกว่ามี → Exception + Rollback ✅
   - แก้เอกสารที่ไม่ใช่ Draft → 422 Error ✅
   - เลื่อนสถานะ Project ข้ามขั้นตอน → ต้องถูกบล็อก ✅
   - จ่ายเงินให้ Supplier Bill ที่จ่ายแล้ว → ต้องถูกบล็อก ✅
□ ตรวจ Rate Limiting:
   - Login endpoint มี throttle ป้องกัน brute-force ✅
```

## A07 — Authentication Failures

```
□ ทดสอบ Token Expiration:
   - ใช้ Token หมดอายุ → ต้องได้ 401 ✅
□ ทดสอบ Brute-force:
   - Login ผิดรหัส 5+ ครั้ง → ต้องถูก throttle/block ✅
□ ทดสอบ Logout Invalidation:
   - Logout → ใช้ Token เดิม → ต้องได้ 401 ✅
□ ตรวจ Password Policy:
   - รหัสผ่านต้องมีความยาวขั้นต่ำ (>= 8 chars) ✅
```

## A08 — Software or Data Integrity Failures

```
□ ทดสอบ JWT Tampering:
   - แก้ไข JWT payload → ส่งไป → ต้องได้ 401 (signature invalid) ✅
□ ตรวจ Mass Assignment:
   - ส่ง field ที่ไม่ควรแก้ได้ (เช่น role, is_active) ผ่าน POST/PUT → ต้องถูกกรอง ✅
   - ตรวจว่าทุก Model มี $fillable (ไม่ใช้ $guarded = []) ✅
□ ตรวจ File Upload:
   - Upload ไฟล์ .php, .exe → ต้องถูก reject ✅
   - ตรวจ MIME type validation ✅
```

## A09 — Security Logging & Alerting Failures

```
□ ตรวจ Activity Log:
   - Login สำเร็จ/ไม่สำเร็จ มีบันทึก ✅
   - การสร้าง/แก้ไข/ลบข้อมูลสำคัญ มีบันทึก ✅
   - การเปลี่ยนสถานะ Project/Finance มีบันทึก ✅
□ ตรวจ Laravel Log:
   - storage/logs/laravel.log ไม่เปิดเผยต่อ public ✅
   - Log ไม่บันทึก sensitive data (passwords, tokens) ✅
```

## A10 — Mishandling of Exceptional Conditions

```
□ ทดสอบ Error Handling:
   - ส่ง JSON body ผิดรูปแบบ → ตอบ 400 ชัดเจน (ไม่ crash) ✅
   - ส่งค่าว่าง / null ในฟิลด์ required → ตอบ 422 + ระบุ field ✅
   - ส่งค่าติดลบ (qty = -5) → ต้อง validate reject ✅
   - Upload ไฟล์เกินขนาด (> 10MB) → ตอบ error ชัดเจน ✅
□ ทดสอบ Resource Exhaustion:
   - Request Pagination ค่า per_page = 999999 → ต้อง cap ที่ค่าสูงสุด ✅
□ ทดสอบ Concurrent Operations:
   - 2 คนกดสร้างเอกสารพร้อมกัน → doc_no ต้องไม่ซ้ำ ✅
```

---

## ช่วงบ่าย (13:00 - 17:00) — Fix Security Issues + Final Testing

```
□ แก้ไข Security Issues ที่พบทั้งหมด
□ Re-run ทดสอบทุกข้อที่แก้ไข → ผ่าน ✅
□ Re-run Laravel Feature Tests → ผ่าน 100% ✅
□ Re-run Newman Tests → ผ่าน 100% ✅
```

## ช่วงค่ำ (18:00 - 21:00) — Release

```
□ เขียนรายงานสรุปผลการทดสอบความปลอดภัย
□ อัปเดต API Documentation สรุปรวมทั้งระบบ
□ Merge โค้ดทั้งหมดเข้าสู่ main
□ Git Tag: v1.1.0
□ 🎉🎉🎉 DONE! 🎉🎉🎉
```

### ✅ สรุปวันที่ 14:
```
✅ OWASP Top 10:2025 ทดสอบผ่านทั้ง 10 หัวข้อ
✅ Security Issues แก้ไขเรียบร้อย
✅ Automated Tests ผ่าน 100%
✅ Release v1.1.0
```

---
---

# 📊 ตารางสรุปรวม 14 วัน

| วัน | วันที่ | หัวข้อ | Endpoints | สะสม |
|-----|--------|--------|-----------|------|
| 1 | 1 ก.ค. | Foundation + Auth | 3 | 3 |
| 2 | 2 ก.ค. | Customers | 9 | 12 |
| 3 | 3 ก.ค. | Projects + Activity Log | 9 | 21 |
| 4 | 4 ก.ค. | Suppliers (Quotes/Samples/Bills) | 17 | 38 |
| 5 | 5 ก.ค. | Finance (Docs/Payments) | 10 | 48 |
| 6 | 6 ก.ค. | Client Samples + Artwork | 11 | 59 |
| 7 | 7 ก.ค. | Container + Inventory + Delivery | 15 | 74 |
| 8 | 8 ก.ค. | Dashboard + Reports | 7 | 81 |
| 9 | 9 ก.ค. | Polish (Error Handling + Validation) | 0 | 81 |
| 10 | 10 ก.ค. | Frontend Integration + Pre-deploy | 0 | 81 |
| 11 | 11 ก.ค. | Deploy Staging + Production | 0 | **81** |
| 12 | 12 ก.ค. | Automated & Full Flow Testing | 0 | **81** |
| 13 | 13 ก.ค. | OWASP Security Testing (A01-A05) | 0 | **81** |
| 14 | 14 ก.ค. | OWASP Security Testing (A06-A10) + Release | 0 | **81** |

---

> 📝 **สร้างโดย:** Antigravity AI Assistant
> **วันที่:** 6 กรกฎาคม 2026
