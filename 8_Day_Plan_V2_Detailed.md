# 📅 PPN GREAT — แผนงาน 8 วัน ฉบับละเอียดสุดๆ

> **เอกสารนี้เขียนให้ทำตามได้เลย** ทุก Checkbox คือ 1 งานที่ต้องทำ  
> ทำเสร็จแล้วติ๊ก ✅ ไป จะได้ไม่ตกหล่น

---

# 🗓️ วันที่ 1 (4 ก.ค. 2026) — Foundation

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

**ทำไม?** Flutter จะเรียก API ผ่าน URL นี้ ต้อง HTTPS เท่านั้น (เพราะ Web Browser บังคับ)

### 1.2 สร้าง MySQL Database 2 อัน

```
□ เข้า Plesk → Databases → Add Database
□ สร้าง Database #1:
   - ชื่อ: ppn_production
   - User: ppn_prod_user
   - Password: (ตั้งรหัสแข็งๆ → จดไว้!)
□ สร้าง Database #2:
   - ชื่อ: ppn_staging
   - User: ppn_stag_user
   - Password: (ตั้งรหัสอื่น → จดไว้!)
□ ทดสอบเข้า phpMyAdmin ได้ทั้ง 2 อัน
□ จดบันทึก:
   - DB Host: localhost
   - DB Port: 3306
   - Production: ppn_production / ppn_prod_user / xxxx
   - Staging: ppn_staging / ppn_stag_user / yyyy
```

**ทำไมต้อง 2 อัน?** Production = ข้อมูลจริง, Staging = ทดสอบ ลบแก้ได้ไม่กระทบของจริง

### 1.3 สร้าง Laravel Project

```
□ เปิด Terminal บนเครื่อง Dev
□ รันคำสั่ง:
   composer create-project laravel/laravel ppn-api
   cd ppn-api
□ ทดสอบ: php artisan serve → เปิด http://localhost:8000 → เห็นหน้า Welcome
□ แก้ไฟล์ .env:
   APP_NAME=PPN_GREAT_API
   APP_ENV=local
   APP_DEBUG=true
   APP_URL=http://localhost:8000

   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=ppn_staging        ← ใช้ Staging ตอน Dev
   DB_USERNAME=ppn_stag_user
   DB_PASSWORD=yyyy
□ ทดสอบ: php artisan migrate → ต้องผ่าน (สร้าง default tables)
```

### 1.4 ตั้งค่า CORS

```
□ เปิดไฟล์ config/cors.php
□ แก้ไข:
   'paths' => ['api/*'],
   'allowed_origins' => ['*'],     ← ตอน Dev ใส่ * / ตอน Production ระบุ Domain
   'allowed_methods' => ['*'],
   'allowed_headers' => ['*'],
   'supports_credentials' => true,
□ ทดสอบ: เปิด Flutter Web → เรียก API → ต้องไม่มี CORS Error
```

**ทำไม?** ถ้าไม่ตั้ง CORS → Flutter Web จะเรียก API ไม่ได้เลย (Browser บล็อก)

---

## ช่วงบ่าย (13:00 - 17:00) — JWT Auth + Migrations

### 1.5 ติดตั้ง JWT Authentication

```
□ รันคำสั่ง:
   composer require tymon/jwt-auth
□ Publish config:
   php artisan vendor:publish --provider="Tymon\JWTAuth\Providers\LaravelServiceProvider"
□ สร้าง JWT Secret:
   php artisan jwt:secret
   → จะเพิ่ม JWT_SECRET=xxxxx ใน .env อัตโนมัติ
□ แก้ไฟล์ config/auth.php:
   'defaults' => [
       'guard' => 'api',    ← เปลี่ยนจาก 'web' เป็น 'api'
   ],
   'guards' => [
       'api' => [
           'driver' => 'jwt',
           'provider' => 'users',
       ],
   ],
□ แก้ Model app/Models/User.php:
   - implements JWTSubject
   - เพิ่ม getJWTIdentifier() + getJWTCustomClaims()
□ ทดสอบ: php artisan tinker → User::factory()->create() → OK
```

### 1.6 เขียน Migration ทั้ง 26 ตาราง

> ⚠️ **ส่วนนี้ใช้เวลาเยอะที่สุดของวัน** ต้องสร้าง Migration File ทีละตาราง

```
□ php artisan make:migration create_users_table
   - id, email, password, full_name, role (ENUM 7 ค่า), phone,
     is_active, last_login_at, timestamps
   - ทำไม: ทุก API ต้องรู้ว่าใครเรียก ใช้ Role ควบคุมสิทธิ์

□ php artisan make:migration create_customers_table
   - id, name, type (ENUM: Enterprise/Mid-Market/SME), status (Active/Inactive),
     tax_id, branch, industry, lead_source (ENUM 6 ค่า),
     internal_note, billing_address, created_by (FK→users), timestamps
   - ทำไม: ศูนย์กลางข้อมูลลูกค้า ทุก Project ต้องมีลูกค้า

□ php artisan make:migration create_contact_persons_table
   - id, customer_id (FK→customers, CASCADE), name, role, phone,
     email, line_id, other_chat, is_primary, created_at
   - ทำไม: ลูกค้า 1 คนมีผู้ติดต่อได้หลายคน (เช่น ฝ่าย MKT, ฝ่ายจัดซื้อ)

□ php artisan make:migration create_shipping_addresses_table
   - id, customer_id (FK→customers, CASCADE), label, address, is_default, created_at
   - ทำไม: ลูกค้ามีที่อยู่ส่งของได้หลายที่ (สำนักงาน, โกดัง, สาขา)

□ php artisan make:migration create_projects_table
   - id, project_code (UNIQUE), customer_id (FK), contact_person_id (FK),
     status (ENUM 7 สถานะ), step (0-5), priority (0-2),
     is_repeat_order, target_date, order_value (DECIMAL 14,2),
     usage_location, credit_term (ENUM 5 ค่า),
     deposit_paid, balance_paid, ocpb_passed, shipping_mark_ready,
     created_by (FK→users), timestamps
   - ทำไม: หัวใจของระบบ ทุกอย่างเชื่อมกลับมาที่ Project

□ php artisan make:migration create_product_items_table
   - id, project_id (FK, CASCADE), name, qty, specs, target_date, timestamps
   - ทำไม: 1 Project มีสินค้าได้หลายรายการ (เช่น ร่ม + กระเป๋า)

□ php artisan make:migration create_product_variations_table
   - id, product_item_id (FK, CASCADE), variation_name, created_at
   - ทำไม: สินค้า 1 ชิ้นมีตัวเลือกได้ (เช่น สีแดง/น้ำเงิน, ไซส์ S/M/L)

□ php artisan make:migration create_product_files_table
   - id, product_item_id (FK, CASCADE), file_type (ENUM: reference/artwork),
     file_name, file_path, uploaded_at
   - ทำไม: เก็บไฟล์อ้างอิงและ Artwork ที่แนบกับสินค้า

□ php artisan make:migration create_additional_requests_table
   - id, project_id (FK, CASCADE), description, cost (DECIMAL), created_at
   - ทำไม: ลูกค้าขอเพิ่มเติม เช่น ติดสติกเกอร์ +฿5,000

□ php artisan make:migration create_suppliers_table
   - id, name, category, contact_person, phone, wechat, email,
     location, rating (DECIMAL 2,1), notes, is_active, timestamps
   - ทำไม: จัดการโรงงานจีน ต้องมีข้อมูลติดต่อ + ประเมิน Rating

□ php artisan make:migration create_quote_requests_table
   - id, supplier_id (FK), project_id (FK), product_item_id (FK),
     customer_name, product_name, qty, specs, variations, target_date, packing,
     status (ENUM: Waiting Link/Link Sent/Price Filled/Approved),
     quoted_price (DECIMAL), currency (ENUM: USD/THB/CNY),
     lead_time, moq, remark, session_token (UNIQUE), timestamps
   - ทำไม: ขอราคาจากโรงงาน → โรงงานกรอกราคาผ่าน Session Link

□ php artisan make:migration create_supplier_samples_table
   - id, supplier_id (FK), project_id (FK), product_name, customer_name,
     status (ENUM 3 ค่า), specs, cost, tracking_no, expected_date, timestamps
   - ทำไม: ขอตัวอย่างจากโรงงานก่อนสั่งผลิตจริง

□ php artisan make:migration create_supplier_bills_table
   - id, supplier_id (FK), project_id (FK), product_name,
     bill_type (ENUM: Deposit/Balance/Full Payment),
     amount_thb (DECIMAL 14,2), due_month,
     status (ENUM: Pending/Paid/Overdue),
     pi_uploaded, pi_file_path, invoice_uploaded, invoice_file_path,
     paid_at, timestamps
   - ทำไม: AP (จ่ายเงินให้โรงงาน) ต้องติดตามว่าจ่ายแล้วหรือยัง

□ php artisan make:migration create_client_samples_table
   - id, project_id (FK), product_item_id (FK), sample_code,
     attempt (1,2,3...), sample_type (ENUM 4 ค่า), origin (ENUM: China/In-Stock),
     supplier_name, status (ENUM 6 สถานะ), sent_date,
     china_tracking, local_courier, local_tracking, feedback, timestamps
   - ทำไม: ส่งตัวอย่างให้ลูกค้าก่อนผลิตจริง ถูก Reject ได้ → ส่งใหม่ (attempt++)

□ php artisan make:migration create_artwork_logs_table
   - id, project_id (FK), product_item_id (FK), artwork_code,
     attempt, version (V1/V2/V2.1), source (ENUM 4 ค่า),
     status (ENUM 6 สถานะ), file_name, file_path, feedback, timestamps
   - ทำไม: ติดตาม Artwork ตั้งแต่อัปโหลดจนอนุมัติ รองรับหลาย Version

□ php artisan make:migration create_finance_documents_table
   - id, doc_no (UNIQUE), project_id (FK), customer_id (FK),
     doc_type (ENUM: QU/PI/DP/CI), status (ENUM 5 สถานะ),
     total_amount (DECIMAL 14,2), credit_term, issue_date, due_date,
     notes, created_by (FK→users), timestamps
   - ทำไม: ออกเอกสารการเงิน 4 ประเภท (ใบเสนอราคา/แจ้งหนี้/มัดจำ/กำกับสินค้า)

□ php artisan make:migration create_finance_doc_items_table
   - id, finance_document_id (FK, CASCADE), item_name, qty,
     unit_price (DECIMAL), total_price (DECIMAL)
   - ทำไม: 1 เอกสารมีรายการสินค้าได้หลายรายการ (เช่น ร่ม + ค่าส่ง)

□ php artisan make:migration create_payments_table
   - id, project_id (FK), finance_document_id (FK), customer_id (FK),
     payment_type (ENUM: Deposit/Balance/Full), amount (DECIMAL 14,2),
     method (ENUM: Bank Transfer/Cheque/Cash/Other), payment_date,
     status (ENUM: Pending Verification/Confirmed),
     slip_file_path, verified_by (FK→users), verified_at, notes, timestamps
   - ทำไม: บันทึกเงินที่ลูกค้าจ่ายมา (AR = ลูกหนี้)

□ php artisan make:migration create_containers_table
   - id, container_code (UNIQUE), container_no, vessel_name,
     port_origin, port_destination,
     status (ENUM 4 สถานะ),
     factory_departure, domestic_tracking, port_arrival_china,
     etd, eta, actual_arrival,
     customs_cleared, customs_date, warehouse_arrival,
     notes, timestamps
   - ทำไม: ติดตามตู้ Container 3 ขั้นตอน (โรงงาน→ท่าเรือ→เรือ→คลัง)

□ php artisan make:migration create_container_projects_table
   - id, container_id (FK, CASCADE), project_id (FK), UNIQUE(container_id, project_id)
   - ทำไม: 1 ตู้มีของจากหลาย Project ได้ (Many-to-Many)

□ php artisan make:migration create_warehouses_table
   - id, name, location, is_active, created_at
   - ทำไม: บริษัทมีคลังหลายที่ (เช่น บางพลี, รังสิต)

□ php artisan make:migration create_stock_items_table
   - id, warehouse_id (FK), product_item_id (FK), project_id (FK),
     qty_in_stock, qty_reserved, location_in_warehouse,
     last_received_at, timestamps
   - ทำไม: เก็บจำนวนสต็อกจริงแยกตามคลัง

□ php artisan make:migration create_stock_movements_table
   - id, stock_item_id (FK), movement_type (ENUM: IN/OUT/ADJUST),
     qty, reference_type, reference_id, notes, created_by (FK), created_at
   - ทำไม: บันทึกทุกครั้งที่สต็อกเปลี่ยน (เข้า/ออก) เพื่อตรวจสอบย้อนหลัง

□ php artisan make:migration create_dispatch_rounds_table
   - id, dispatch_code (UNIQUE), dispatch_date, driver_name,
     vehicle_plate, status (ENUM 3 สถานะ), notes, created_by (FK), timestamps
   - ทำไม: จัดรอบส่งสินค้า (1 รอบมีหลายลูกค้า)

□ php artisan make:migration create_delivery_items_table
   - id, dispatch_round_id (FK, CASCADE), project_id (FK),
     product_item_id (FK), customer_name, delivery_address,
     qty_to_deliver, warehouse_id (FK), notes
   - ทำไม: แต่ละรอบส่ง มีรายการของที่ต้องส่ง (แยก Project + จำนวน)

□ php artisan make:migration create_activity_logs_table
   - id, user_id (FK), project_id (FK), action, description,
     entity_type, entity_id, created_at
   - ทำไม: บันทึกทุกการกระทำ เพื่อแสดงใน Dashboard + Project Detail

□ Run Migration ทั้งหมด:
   php artisan migrate
   → ต้องผ่านไม่มี Error!
```

---

## ช่วงค่ำ (18:00 - 21:00) — Auth API + ทดสอบ

### 1.7 สร้าง Auth API (3 Endpoints)

```
□ สร้าง Controller:
   php artisan make:controller AuthController

□ Endpoint #1: POST /api/auth/login
   - รับ: { "email": "xxx", "password": "xxx" }
   - ตรวจ: email + password ถูกต้อง?
   - สำเร็จ: ส่ง JWT Token กลับ { "token": "eyJxxx...", "user": {...} }
   - ไม่สำเร็จ: 401 { "error": "Email หรือรหัสผ่านไม่ถูกต้อง" }
   - ทำไม: Flutter ต้อง Login ก่อนถึงจะเรียก API อื่นได้

□ Endpoint #2: POST /api/auth/logout
   - รับ: Header Authorization: Bearer {token}
   - ทำ: Invalidate Token (ทำให้ Token นี้ใช้ไม่ได้อีก)
   - สำเร็จ: { "message": "Logout สำเร็จ" }
   - ทำไม: ความปลอดภัย — ออกจากระบบแล้ว Token ต้องใช้ไม่ได้

□ Endpoint #3: GET /api/auth/me
   - รับ: Header Authorization: Bearer {token}
   - ส่งกลับ: ข้อมูล User ปัจจุบัน { "id": 1, "email": "xxx", "role": "sales", ... }
   - ทำไม: Flutter เปิดแอปมา ต้องเช็คว่ายังล็อกอินอยู่ไหม + ดึงข้อมูล User

□ สร้าง Middleware JWT:
   - ตรวจ Token ทุก Request
   - ถ้าไม่มี Token หรือ Token หมดอายุ → 401 Unauthorized
   - ใส่ใน Kernel.php: 'jwt.auth' => JwtMiddleware::class

□ ลงทะเบียน Routes ใน routes/api.php:
   Route::post('auth/login', [AuthController::class, 'login']);
   Route::middleware('jwt.auth')->group(function () {
       Route::post('auth/logout', [AuthController::class, 'logout']);
       Route::get('auth/me', [AuthController::class, 'me']);
   });

□ สร้าง User ทดสอบ:
   php artisan make:seeder UserSeeder
   → สร้าง admin@ppn.com / password123
   php artisan db:seed --class=UserSeeder
```

### 1.8 ทดสอบ Auth ผ่าน Postman / Thunder Client

```
□ ทดสอบ Login:
   POST http://localhost:8000/api/auth/login
   Body: { "email": "admin@ppn.com", "password": "password123" }
   → ต้องได้ Token กลับมา ✅

□ ทดสอบ Me:
   GET http://localhost:8000/api/auth/me
   Header: Authorization: Bearer eyJxxx...
   → ต้องได้ข้อมูล User กลับมา ✅

□ ทดสอบ ไม่มี Token:
   GET http://localhost:8000/api/auth/me
   (ไม่ใส่ Header)
   → ต้องได้ 401 Unauthorized ✅

□ ทดสอบ Logout:
   POST http://localhost:8000/api/auth/logout
   Header: Authorization: Bearer eyJxxx...
   → ต้องได้ "Logout สำเร็จ" ✅
   → ลองเรียก /me อีกครั้งด้วย Token เดิม → ต้องได้ 401 ✅
```

### ✅ สรุปวันที่ 1 — ต้องผ่านทั้งหมดนี้:

```
✅ Domain ซื้อแล้ว + DNS ตั้งค่าแล้ว
✅ Hosting ตั้ง 2 Subdomain (api + staging-api)
✅ MySQL 2 Database (ppn_production + ppn_staging)
✅ Laravel Project สร้างแล้ว + .env ตั้งค่าแล้ว
✅ JWT Auth ติดตั้งแล้ว + JWT_SECRET ตั้งแล้ว
✅ Migration 26 ตาราง Run ผ่าน
✅ CORS ตั้งค่าแล้ว
✅ Auth API 3 endpoints ทำงานได้
✅ ทดสอบ Login/Me/Logout ผ่าน Postman ผ่าน
```

---

---

# 🗓️ วันที่ 2 (5 ก.ค. 2026) — Core: Customers + Projects

> **เป้าหมาย:** สร้าง/แก้ไข/ค้นหา ลูกค้าและโปรเจกต์ได้ครบ

---

## ช่วงเช้า (08:00 - 12:00) — Customers

### 2.1 สร้าง Customer Model + Controller

```
□ php artisan make:model Customer
□ php artisan make:controller CustomerController --api
□ ตั้งค่า Model:
   - $fillable = ['name','type','status','tax_id','branch','industry', ...]
   - relationships: contacts(), shippingAddresses(), projects()

□ php artisan make:model ContactPerson
□ php artisan make:controller ContactPersonController
□ ตั้งค่า Model:
   - $fillable = ['customer_id','name','role','phone','email','line_id','other_chat','is_primary']
   - relationship: customer()

□ php artisan make:model ShippingAddress
□ php artisan make:controller ShippingAddressController
```

### 2.2 Customer Endpoints (9 อัน)

```
□ Endpoint #1: GET /api/customers
   - รับ Query: ?search=AIS&status=Active&type=Enterprise&page=1&per_page=20
   - ทำ: ค้นหาลูกค้าตามเงื่อนไข + Paginate
   - ส่งกลับ: List ลูกค้า + meta (page, total)
   - ทำไม: หน้า Customers ฝั่งซ้าย แสดงรายชื่อลูกค้า + Search
   - เวลาทำ: ~30 นาที

□ Endpoint #2: GET /api/customers/{id}
   - รับ: Customer ID
   - ทำ: ดึงข้อมูลลูกค้า + contacts + addresses + projects (recent 10)
   - ส่งกลับ: ข้อมูลเต็ม (include relations)
   - ทำไม: หน้า Customer Detail Panel ฝั่งขวา
   - เวลาทำ: ~20 นาที

□ Endpoint #3: POST /api/customers
   - รับ Body: { name, type, tax_id, branch, industry, lead_source, billing_address, contacts: [...], addresses: [...] }
   - Validation: name ต้องกรอก, type ต้องเป็น ENUM
   - ทำ: สร้าง Customer + สร้าง Contacts + สร้าง Addresses พร้อมกัน
   - ทำไม: หน้า "Create Customer" ส่งฟอร์มมา ต้องสร้างทุกอย่างพร้อมกัน
   - ⚠️ จุดสำคัญ: ใช้ DB::transaction() เพราะสร้างหลายตารางพร้อมกัน
   - เวลาทำ: ~45 นาที

□ Endpoint #4: PUT /api/customers/{id}
   - รับ Body: ข้อมูลที่ต้องการแก้
   - ทำ: อัปเดตข้อมูลลูกค้า
   - ทำไม: แก้ไขข้อมูลลูกค้า (ชื่อ, ที่อยู่, ประเภท ฯลฯ)
   - เวลาทำ: ~15 นาที

□ Endpoint #5: POST /api/customers/{id}/contacts
   - รับ Body: { name, role, phone, email, line_id }
   - ทำ: เพิ่มผู้ติดต่อให้ลูกค้า
   - ทำไม: ลูกค้าอาจมีผู้ติดต่อหลายคน (ฝ่าย MKT, ฝ่ายจัดซื้อ)
   - เวลาทำ: ~15 นาที

□ Endpoint #6: PUT /api/customers/{id}/contacts/{cid}
   - ทำ: แก้ไขข้อมูลผู้ติดต่อ
   - เวลาทำ: ~10 นาที

□ Endpoint #7: DELETE /api/customers/{id}/contacts/{cid}
   - ทำ: ลบผู้ติดต่อ
   - ⚠️ ตรวจสอบ: ถ้า contact นี้เชื่อมกับ Project อยู่ → ไม่ให้ลบ หรือ ถอดออก
   - เวลาทำ: ~10 นาที

□ Endpoint #8: POST /api/customers/{id}/addresses
   - รับ Body: { label, address, is_default }
   - ทำ: เพิ่มที่อยู่จัดส่ง
   - ⚠️ ถ้า is_default = true → ต้องเปลี่ยนอันเก่าเป็น false ก่อน
   - เวลาทำ: ~15 นาที

□ Endpoint #9: GET /api/customers/{id}/stats
   - ทำ: คำนวณสถิติลูกค้า
   - ส่งกลับ: {
       revenue_lifetime: (SUM payments),
       revenue_this_year, revenue_last_year,
       projects_completed: (COUNT projects WHERE status=Delivered),
       projects_active: (COUNT projects WHERE status NOT IN Delivered/Cancelled),
       payment_on_time: (COUNT), payment_total: (COUNT),
       customer_since: (MIN created_at),
       avg_projects_year: (COUNT / years),
       has_outstanding: (ยังมียอดค้างไหม)
     }
   - ทำไม: หน้า Customer Detail ฝั่งขวา แสดง Stats Card
   - ⚠️ เป็น Calculated field ไม่ได้เก็บใน DB — ต้อง Query คำนวณ
   - เวลาทำ: ~45 นาที (ซับซ้อนที่สุดของ Customer)
```

---

## ช่วงบ่าย (13:00 - 17:00) — Projects

### 2.3 สร้าง Project Model + Services

```
□ php artisan make:model Project
□ php artisan make:controller ProjectController --api
□ ตั้งค่า Model:
   - $fillable = ทุก field
   - relationships: customer(), contactPerson(), products(), financeDocs(), payments(), logs()
   - $appends = ['days_left', 'days_in_stage']
   - Accessor: getDaysLeftAttribute() → Carbon diff target_date
   - Accessor: getDaysInStageAttribute() → Carbon diff updated_at

□ php artisan make:model ProductItem
□ php artisan make:controller ProductItemController

□ สร้าง Service: app/Services/ProjectCodeService.php
   - generate(): string → "PPN-001", "PPN-002", ...
   - Logic: ดึง project_code ล่าสุด → +1 → format 3 หลัก
   - ทำไม: ทุก Project ต้องมีรหัสอัตโนมัติ ห้ามซ้ำ
```

### 2.4 Project Endpoints (9 อัน)

```
□ Endpoint #1: GET /api/projects
   - รับ Query: ?status=Production&search=AIS&sort=target_date&order=asc&page=1
   - ทำ: ค้นหา Project ตามสถานะ/ชื่อลูกค้า/รหัส/ชื่อสินค้า + Sort + Paginate
   - Include: customer (ชื่อลูกค้า), products (รายการสินค้า)
   - ส่งกลับ: List Projects + days_left + days_in_stage
   - ทำไม: หน้า Project List → Filter Tabs (Inquiry, Sample, Production, ...)
   - เวลาทำ: ~45 นาที

□ Endpoint #2: GET /api/projects/{id}
   - ทำ: ดึงข้อมูล Project แบบเต็ม
   - Include: customer, contactPerson, products (with variations, files),
              additionalRequests, financeDocs, payments, logs (ล่าสุด 20)
   - ส่งกลับ: ข้อมูลครบทุกส่วน
   - ทำไม: หน้า Project Detail Panel ฝั่งขวา
   - เวลาทำ: ~30 นาที

□ Endpoint #3: POST /api/projects
   - รับ Body: {
       customer_id, contact_person_id, priority, is_repeat_order,
       target_date, usage_location, credit_term,
       products: [
         { name, qty, specs, target_date, variations: ["สีแดง","สีน้ำเงิน"] }
       ]
     }
   - ทำ: สร้าง Project (auto project_code) + สร้าง Products + Variations
   - ⚠️ ใช้ DB::transaction()
   - ⚠️ บันทึก Activity Log: "สร้าง Project PRJ-xxx"
   - ทำไม: หน้า Create Project ส่งฟอร์มมา
   - เวลาทำ: ~60 นาที (ซับซ้อนที่สุด — หลาย relation)

□ Endpoint #4: PUT /api/projects/{id}
   - ทำ: แก้ไข Project (ข้อมูลทั่วไป compliance ฯลฯ)
   - เวลาทำ: ~15 นาที

□ Endpoint #5: PATCH /api/projects/{id}/status
   - รับ Body: { status: "Sample" } หรือ { step: 1 }
   - ทำ: เปลี่ยนสถานะ Project (เลื่อน Step ใน Pipeline)
   - ⚠️ Validation: ต้องเลื่อนตามลำดับเท่านั้น (Inquiry→Sample→Production→...)
   - ⚠️ บันทึก Activity Log: "เปลี่ยนสถานะเป็น Sample"
   - ทำไม: เซลส์กดเปลี่ยนสถานะ Project เมื่อมีความคืบหน้า
   - เวลาทำ: ~30 นาที

□ Endpoint #6: POST /api/projects/{id}/products
   - รับ Body: { name, qty, specs, target_date, variations: [...] }
   - ทำ: เพิ่มสินค้าใน Project
   - ทำไม: หลังสร้าง Project แล้ว อาจเพิ่มสินค้าทีหลังได้
   - เวลาทำ: ~20 นาที

□ Endpoint #7: PUT /api/projects/{id}/products/{pid}
   - ทำ: แก้ไขสินค้า (ชื่อ, จำนวน, สเปค)
   - เวลาทำ: ~15 นาที

□ Endpoint #8: POST /api/projects/{id}/additional-requests
   - รับ Body: { description, cost }
   - ทำ: เพิ่มคำขอพิเศษ เช่น "ติดสติกเกอร์บาร์โค้ด +฿8,500"
   - เวลาทำ: ~10 นาที

□ Endpoint #9: GET /api/projects/{id}/logs
   - ทำ: ดึง Activity Log ของ Project นี้ (เรียงจากใหม่สุด)
   - ส่งกลับ: [{ time, user, action, description }, ...]
   - ทำไม: หน้า Project Detail แสดง Timeline กิจกรรม
   - เวลาทำ: ~15 นาที
```

---

## ช่วงค่ำ (18:00 - 21:00) — Activity Log + ทดสอบ

### 2.5 Activity Log System

```
□ php artisan make:model ActivityLog
□ สร้าง Helper Method ที่ใช้ทั่วทั้งระบบ:

   // ใน Model หรือ Service:
   ActivityLog::create([
       'user_id' => auth()->id(),
       'project_id' => $project->id,
       'action' => 'สร้าง Project',
       'description' => "สร้าง Project {$project->project_code} สำหรับ {$customer->name}",
       'entity_type' => 'project',
       'entity_id' => $project->id,
   ]);

□ เพิ่ม Activity Log ใน:
   - สร้าง Project ✅
   - เปลี่ยนสถานะ Project ✅
   - (วันต่อๆ ไปจะเพิ่มใน Module อื่นด้วย)
```

### 2.6 ทดสอบ Customer + Project APIs

```
□ ทดสอบ สร้างลูกค้า:
   POST /api/customers → ส่งข้อมูลเต็ม + contacts + addresses → ได้ ID กลับ ✅

□ ทดสอบ ค้นหาลูกค้า:
   GET /api/customers?search=ทดสอบ → ได้ list ✅

□ ทดสอบ ดูรายละเอียด:
   GET /api/customers/1 → ได้ข้อมูลเต็ม + contacts + addresses ✅

□ ทดสอบ สร้าง Project:
   POST /api/projects → ส่ง customer_id + products → ได้ project_code PPN-001 ✅

□ ทดสอบ เปลี่ยนสถานะ:
   PATCH /api/projects/1/status → { status: "Sample" } → step เปลี่ยนเป็น 1 ✅

□ ทดสอบ Activity Log:
   GET /api/projects/1/logs → เห็นประวัติ "สร้าง Project" + "เปลี่ยนสถานะ" ✅
```

### ✅ สรุปวันที่ 2:

```
✅ Customer CRUD ครบ 9 endpoints (พร้อม contacts, addresses, stats)
✅ Project CRUD ครบ 9 endpoints (พร้อม products, status pipeline)
✅ Auto-generate Project Code (PPN-001, PPN-002)
✅ Activity Log เริ่มทำงาน
✅ ทดสอบผ่าน Postman ทุก endpoint
✅ รวม: 18 endpoints ✅
```

---

---

# 🗓️ วันที่ 3 (6 ก.ค. 2026) — Suppliers ทั้งระบบ

> **เป้าหมาย:** จัดการ Supplier + ขอราคา + ขอตัวอย่าง + จ่ายเงิน ครบ

---

## ช่วงเช้า (08:00 - 12:00) — Supplier CRUD + Quotes

### 3.1 Supplier (4 Endpoints)

```
□ php artisan make:model Supplier
□ php artisan make:controller SupplierController --api

□ Endpoint #1: GET /api/suppliers
   - Query: ?search=Guangzhou&category=Textile
   - ทำ: ค้นหา Supplier + นับจำนวน quotes/samples/bills ของแต่ละราย
   - ทำไม: หน้า Supplier List ฝั่งซ้าย + Badge ตัวเลข
   - เวลาทำ: ~30 นาที

□ Endpoint #2: GET /api/suppliers/{id}
   - Include: quotes, samples, bills (ทั้ง 3 Tab)
   - ทำไม: หน้า Supplier Detail ฝั่งขวา (3 Tabs)
   - เวลาทำ: ~30 นาที

□ Endpoint #3: POST /api/suppliers
   - รับ: { name, category, contact_person, phone, wechat, email, location }
   - ทำ: สร้าง Supplier ใหม่
   - ทำไม: กดปุ่ม "+" บนหน้า Suppliers → Pop-up กรอกข้อมูล
   - เวลาทำ: ~15 นาที

□ Endpoint #4: PUT /api/suppliers/{id}
   - ทำ: แก้ไข Supplier
   - เวลาทำ: ~10 นาที
```

### 3.2 Quote Requests (5 Endpoints)

```
□ php artisan make:model QuoteRequest
□ php artisan make:controller QuoteRequestController

□ Endpoint #5: GET /api/suppliers/{id}/quotes
   - ทำ: ดึงใบขอราคาทั้งหมดของ Supplier นี้
   - ทำไม: Tab "ขอราคา (Quotes)" ในหน้า Supplier Detail
   - เวลาทำ: ~15 นาที

□ Endpoint #6: POST /api/suppliers/{id}/quotes
   - รับ: { project_id, product_items: [{ product_item_id, qty }] }
   - ทำ: สร้างใบขอราคา (อาจขอหลายรายการพร้อมกัน)
   - ⚠️ ดึงข้อมูล Project + Product มาใส่ในใบขอราคาอัตโนมัติ
   - ทำไม: กดปุ่ม "Request Quote" → เลือก Project → ติ๊กสินค้า → Submit
   - เวลาทำ: ~45 นาที

□ Endpoint #7: PUT /api/suppliers/{id}/quotes/{qid}
   - รับ: { quoted_price, currency, lead_time, moq, remark }
   - ทำ: อัปเดตราคาที่ Supplier ตอบกลับ (Manual Input)
   - ⚠️ เปลี่ยน status เป็น "Price Filled" อัตโนมัติ
   - ทำไม: กดปุ่ม "Manual Input" → กรอกราคา/MOQ/Lead Time
   - เวลาทำ: ~20 นาที

□ Endpoint #8: PATCH /api/suppliers/{id}/quotes/{qid}/status
   - รับ: { status: "Approved" }
   - ทำ: อนุมัติ Quote
   - ทำไม: กดปุ่ม "Approve" เมื่อเลือก Supplier นี้แล้ว
   - เวลาทำ: ~10 นาที

□ Endpoint #9: POST /api/suppliers/{id}/quotes/{qid}/generate-link
   - ทำ: สร้าง session_token (UUID) + สร้าง URL
   - ส่งกลับ: { url: "https://api.xxx.com/supplier-portal/{token}" }
   - ⚠️ เปลี่ยน status เป็น "Link Sent"
   - ทำไม: กดปุ่ม "Supplier Session Link" → Copy ลิงก์ส่งให้โรงงาน
   - เวลาทำ: ~30 นาที
```

---

## ช่วงบ่าย (13:00 - 17:00) — Supplier Samples + Bills

### 3.3 Supplier Samples (4 Endpoints)

```
□ php artisan make:model SupplierSample
□ php artisan make:controller SupplierSampleController

□ Endpoint #10: GET /api/suppliers/{id}/samples
   - ทำไม: Tab "ขอตัวอย่าง (Samples)" ในหน้า Supplier Detail
   - เวลาทำ: ~15 นาที

□ Endpoint #11: POST /api/suppliers/{id}/samples
   - รับ: { project_id, product_items: [{ product_item_id }] }
   - ทำ: สร้างใบขอตัวอย่าง (คล้าย Quote แต่ไม่ต้องกรอกราคา)
   - ทำไม: กดปุ่ม "Request Sample" → เลือก Project → ติ๊กสินค้า → Submit
   - เวลาทำ: ~30 นาที

□ Endpoint #12: PUT /api/suppliers/{id}/samples/{sid}
   - ทำ: อัปเดตข้อมูล (tracking_no, expected_date, cost)
   - เวลาทำ: ~15 นาที

□ Endpoint #13: PATCH /api/suppliers/{id}/samples/{sid}/status
   - รับ: { status: "Sample Sent" }
   - เวลาทำ: ~10 นาที
```

### 3.4 Supplier Bills / AP (4 Endpoints)

```
□ php artisan make:model SupplierBill
□ php artisan make:controller SupplierBillController

□ Endpoint #14: GET /api/suppliers/{id}/bills
   - Include: filter by status (Pending/Paid/Overdue)
   - คำนวณ: total pending, total paid
   - ทำไม: Tab "รอบบิลจ่ายเงิน (AP)" → แสดงรายการบิล + ยอดรวม
   - เวลาทำ: ~20 นาที

□ Endpoint #15: POST /api/suppliers/{id}/bills
   - รับ: { project_id, product_name, bill_type, amount_thb, due_month }
   - ทำ: สร้างบิลจ่ายเงินให้ Supplier
   - ทำไม: ฝ่ายจัดซื้อเพิ่มบิลเมื่อสั่งผลิตจริง
   - เวลาทำ: ~20 นาที

□ Endpoint #16: PATCH /api/suppliers/{id}/bills/{bid}/pay
   - ทำ: ทำเครื่องหมาย "Paid" + บันทึกวันที่จ่าย
   - ⚠️ เลือกจ่ายหลายบิลพร้อมกันได้ (bulk pay)
   - ทำไม: กดปุ่ม "Pay Selected Bills" → จ่ายหลายบิลพร้อมกัน
   - เวลาทำ: ~20 นาที

□ Endpoint #17: POST /api/suppliers/{id}/bills/{bid}/upload
   - รับ: file (PI หรือ Invoice PDF/รูป)
   - ทำ: Upload + บันทึก file_path + เปลี่ยน pi_uploaded/invoice_uploaded = true
   - ทำไม: แนบเอกสาร PI / Invoice ของ Supplier
   - เวลาทำ: ~30 นาที
```

---

## ช่วงค่ำ (18:00 - 21:00) — ทดสอบ Flow ครบ

```
□ ทดสอบ Flow:
   1. สร้าง Supplier → POST /api/suppliers ✅
   2. สร้าง Quote Request → POST /api/suppliers/1/quotes ✅
   3. Generate Link → POST .../quotes/1/generate-link → ได้ URL ✅
   4. Manual Input ราคา → PUT .../quotes/1 → status เปลี่ยนเป็น Price Filled ✅
   5. Approve Quote → PATCH .../quotes/1/status ✅
   6. สร้าง Sample Request → POST .../samples ✅
   7. สร้าง Bill → POST .../bills ✅
   8. จ่าย Bill → PATCH .../bills/1/pay ✅
   9. Upload PI → POST .../bills/1/upload ✅
```

### ✅ สรุปวันที่ 3:

```
✅ Supplier CRUD 4 endpoints
✅ Quote Request 5 endpoints (พร้อม Session Link)
✅ Supplier Sample 4 endpoints
✅ Supplier Bill / AP 4 endpoints (พร้อม File Upload)
✅ ทดสอบ Flow ครบวงจร
✅ รวม: 17 endpoints ✅
```

---

---

# 🗓️ วันที่ 4 (7 ก.ค. 2026) — Finance ทั้งระบบ

> **เป้าหมาย:** ออกเอกสาร QU/PI/DP/CI + เก็บเงิน + Auto Doc Number

---

## ช่วงเช้า (08:00 - 12:00) — Finance Documents

### 4.1 DocNumberService + Finance Document (6 Endpoints)

```
□ สร้าง Service: app/Services/DocNumberService.php
   - generate('QU') → "QU-2026-0001"
   - generate('PI') → "PI-2026-0001"
   - Logic: ดึง doc_no ล่าสุดของปีนี้ + ประเภทนี้ → +1 → format 4 หลัก
   - ⚠️ ใช้ DB::transaction + lockForUpdate ป้องกัน Race Condition
   - ทำไม: เลขเอกสารต้องไม่ซ้ำ แม้ 2 คนกดสร้างพร้อมกัน

□ php artisan make:model FinanceDocument
□ php artisan make:model FinanceDocItem
□ php artisan make:controller FinanceDocController

□ Endpoint #1: GET /api/finance/documents
   - Query: ?type=QU&status=Draft&search=AIS&page=1
   - Include: project.customer (ชื่อลูกค้า), items count
   - ทำไม: หน้า Finance → List เอกสาร + Filter ตามประเภท/สถานะ
   - เวลาทำ: ~30 นาที

□ Endpoint #2: GET /api/finance/documents/{id}
   - Include: items (รายการสินค้า), project, customer
   - ทำไม: ดูรายละเอียดเอกสาร (รายการ, ยอดเงิน, สถานะ)
   - เวลาทำ: ~20 นาที

□ Endpoint #3: POST /api/finance/documents
   - รับ: { project_id, doc_type, credit_term, issue_date, notes,
            items: [{ item_name, qty, unit_price }] }
   - ทำ:
     1. Auto-generate doc_no (เช่น QU-2026-0003)
     2. คำนวณ due_date จาก issue_date + credit_term
     3. คำนวณ total_amount จาก SUM(items.total_price)
     4. สร้าง FinanceDocument + FinanceDocItems
   - ⚠️ DB::transaction()
   - ⚠️ บันทึก Activity Log
   - ทำไม: หน้า Finance → กด "สร้างเอกสาร" → เลือก QU/PI/DP/CI → กรอกรายการ
   - เวลาทำ: ~60 นาที (ซับซ้อน — auto number + auto calc)

□ Endpoint #4: PUT /api/finance/documents/{id}
   - ทำ: แก้ไขเอกสาร (เฉพาะ Draft เท่านั้น)
   - ⚠️ ถ้า status ไม่ใช่ Draft → ห้ามแก้ → Return 422
   - เวลาทำ: ~20 นาที

□ Endpoint #5: PATCH /api/finance/documents/{id}/status
   - รับ: { status: "Sent" }
   - Validation: Draft→Sent→Paid (ตามลำดับเท่านั้น)
   - ⚠️ ถ้าเปลี่ยนเป็น Paid → อัปเดต Project (deposit_paid/balance_paid)
   - ทำไม: เซลส์กดเปลี่ยนสถานะเมื่อส่งเอกสารให้ลูกค้า/รับเงินแล้ว
   - เวลาทำ: ~30 นาที

□ Endpoint #6: POST /api/finance/documents/{id}/pdf
   - ทำ: สร้าง PDF (ใช้ DOMPDF หรือ Library อื่น)
   - ⚠️ ถ้าทำไม่ทัน → ข้ามไปก่อน ทำทีหลังได้ (Nice-to-have)
   - เวลาทำ: ~60 นาที (ถ้าทำ) หรือข้ามไป
```

---

## ช่วงบ่าย (13:00 - 17:00) — Payments (AR)

### 4.2 Payment Controller (4 Endpoints)

```
□ php artisan make:model Payment
□ php artisan make:controller PaymentController

□ Endpoint #7: GET /api/finance/payments
   - Query: ?project_id=1&status=Confirmed&page=1
   - Include: project.customer
   - ทำไม: Tab "Record Payment" → List รายการรับเงิน
   - เวลาทำ: ~20 นาที

□ Endpoint #8: POST /api/finance/payments
   - รับ: { project_id, finance_document_id, payment_type, amount,
            method, payment_date, notes }
   - ทำ:
     1. สร้าง Payment Record
     2. ⚠️ อัปเดต Project: deposit_paid = true (ถ้า payment_type = Deposit)
     3. บันทึก Activity Log
   - ทำไม: ฝ่ายการเงินบันทึกเมื่อลูกค้าโอนเงินมา
   - เวลาทำ: ~30 นาที

□ Endpoint #9: PATCH /api/finance/payments/{id}/verify
   - รับ: verified_by (user_id)
   - ทำ: status → Confirmed, verified_at = now()
   - ทำไม: ต้องมีคนยืนยันว่าเงินเข้าจริง (ป้องกันความผิดพลาด)
   - เวลาทำ: ~15 นาที

□ Endpoint #10: POST /api/finance/payments/{id}/upload-slip
   - รับ: file (รูปสลิป jpg/png)
   - ทำ: Upload → บันทึก slip_file_path
   - ทำไม: แนบสลิปเป็นหลักฐาน
   - เวลาทำ: ~20 นาที
```

---

## ช่วงค่ำ (18:00 - 21:00) — Overdue Detection + ทดสอบ

### 4.3 Overdue Detection

```
□ สร้าง Artisan Command: php artisan make:command CheckOverdueDocuments
   - Logic: เอกสาร status = "Sent" && due_date < today → เปลี่ยนเป็น "Overdue"
   - ทำไม: เอกสารที่เลยกำหนดต้องเตือนอัตโนมัติ
   - ⚠️ ต้องตั้ง Scheduled Task ใน Plesk ให้รันทุกวัน
   - เวลาทำ: ~30 นาที
```

### 4.4 ทดสอบ Finance Flow

```
□ ทดสอบ สร้าง QU:
   POST /api/finance/documents → type=QU → ได้ doc_no QU-2026-0001 ✅

□ ทดสอบ สร้าง PI:
   POST /api/finance/documents → type=PI → ได้ doc_no PI-2026-0001 ✅
   → due_date = issue_date + 30 วัน ✅

□ ทดสอบ รับเงิน:
   POST /api/finance/payments → type=Deposit ✅
   → Project deposit_paid เปลี่ยนเป็น true ✅

□ ทดสอบ Upload Slip:
   POST /api/finance/payments/1/upload-slip → ไฟล์ถูกเก็บใน storage/slips/ ✅
```

### ✅ สรุปวันที่ 4:

```
✅ DocNumberService (Auto-generate QU-2026-0001)
✅ Finance Document CRUD 6 endpoints
✅ Credit Term → Due Date คำนวณอัตโนมัติ
✅ Payment (AR) 4 endpoints + Upload Slip
✅ Overdue Detection Command
✅ รวม: 10 endpoints ✅
```

---

---

# 🗓️ วันที่ 5 (8 ก.ค. 2026) — Client Samples + Artwork

> **เป้าหมาย:** ส่งตัวอย่างให้ลูกค้า + อัปโหลด Artwork ครบ

---

## ช่วงเช้า (08:00 - 12:00) — Client Samples (5 Endpoints)

```
□ php artisan make:model ClientSample
□ php artisan make:controller ClientSampleController

□ Endpoint #1: GET /api/samples
   - ทำ: ดึง Project ที่มี Sample (GROUP BY project_id)
   - Include: ข้อมูลสรุป (จำนวน sample, สถานะล่าสุด)
   - ทำไม: หน้า Samples → List Project ที่มีตัวอย่าง
   - เวลาทำ: ~30 นาที

□ Endpoint #2: GET /api/samples/project/{pid}
   - ทำ: ดึง Sample ทั้งหมดของ Project (เรียงตาม attempt)
   - ทำไม: กดเลือก Project → เห็น Sample ทุกครั้งที่ส่ง (attempt 1, 2, 3...)
   - เวลาทำ: ~20 นาที

□ Endpoint #3: POST /api/samples
   - รับ: { project_id, product_item_id, sample_type, origin, supplier_name }
   - ทำ:
     1. Auto-generate sample_code (CS-001)
     2. Auto-calculate attempt (นับจำนวน sample เดิมของ product นี้ + 1)
     3. สร้าง ClientSample
   - ⚠️ attempt สำคัญมาก — ต้องนับจาก product_item_id + project_id เดียวกัน
   - ทำไม: กดปุ่ม "Add Local Sample" → สร้าง Sample ใหม่
   - เวลาทำ: ~40 นาที

□ Endpoint #4: PUT /api/samples/{id}
   - ทำ: แก้ไขข้อมูล Sample (courier, tracking, sent_date ฯลฯ)
   - เวลาทำ: ~15 นาที

□ Endpoint #5: PATCH /api/samples/{id}/status
   - รับ: { status: "Approved", feedback: "สวยมาก ใช้ได้เลย" }
   - ทำ: อัปเดตสถานะ + บันทึก feedback
   - ⚠️ ถ้า Approved → บันทึก Activity Log "ลูกค้าอนุมัติตัวอย่าง"
   - ⚠️ ถ้า Rejected → บันทึก feedback + Activity Log
   - ทำไม: เมื่อลูกค้าตอบกลับว่าตัวอย่าง OK หรือต้องแก้
   - เวลาทำ: ~20 นาที
```

---

## ช่วงบ่าย (13:00 - 17:00) — Artwork (6 Endpoints)

```
□ php artisan make:model ArtworkLog
□ php artisan make:controller ArtworkController

□ Endpoint #6: GET /api/artworks
   - ทำ: ดึง Project ที่มี Artwork (GROUP BY project_id)
   - ทำไม: หน้า Artwork Tracking → List Project
   - เวลาทำ: ~20 นาที

□ Endpoint #7: GET /api/artworks/project/{pid}
   - ทำ: ดึง Artwork Log ทั้งหมดของ Project (เรียงตาม attempt)
   - ทำไม: กดเลือก Project → เห็น Artwork ทุก Version
   - เวลาทำ: ~20 นาที

□ Endpoint #8: POST /api/artworks
   - รับ: { project_id, product_item_id, version, source } + file (artwork image/pdf)
   - ทำ:
     1. Auto-generate artwork_code (ART-001)
     2. Auto-calculate attempt
     3. Upload File → เก็บใน storage/artworks/{project_id}/
     4. สร้าง ArtworkLog
   - ⚠️ รองรับไฟล์: jpg, png, pdf, ai, psd (max 10MB)
   - ทำไม: ดีไซเนอร์อัปโหลด Artwork ใหม่
   - เวลาทำ: ~45 นาที

□ Endpoint #9: PUT /api/artworks/{id}
   - ทำ: แก้ไขข้อมูล (version, source, notes)
   - เวลาทำ: ~10 นาที

□ Endpoint #10: PATCH /api/artworks/{id}/status
   - รับ: { status: "Approved by Client" }
   - ⚠️ ถ้า Need Revision → ต้อง Upload Version ใหม่
   - ⚠️ Activity Log
   - ทำไม: เมื่อลูกค้า/โรงงาน Review Artwork
   - เวลาทำ: ~15 นาที

□ Endpoint #11: PATCH /api/artworks/{id}/feedback
   - รับ: { feedback: "โลโก้เล็กไป ขอขยาย 20%" }
   - ทำ: อัปเดต feedback
   - ทำไม: บันทึกความเห็น/เหตุผลที่ Reject
   - เวลาทำ: ~10 นาที
```

---

## ช่วงค่ำ (18:00 - 21:00) — ทดสอบ

```
□ ทดสอบ Sample Flow:
   1. สร้าง Sample ครั้งที่ 1 (attempt=1) ✅
   2. อัปเดต Tracking ✅
   3. Reject → feedback "สีเพี้ยน" ✅
   4. สร้าง Sample ครั้งที่ 2 (attempt=2 อัตโนมัติ) ✅
   5. Approve ✅

□ ทดสอบ Artwork Flow:
   1. Upload V1 + ไฟล์ ✅
   2. Reject → feedback ✅
   3. Upload V2 ✅
   4. Approve by Client ✅
   5. Upload V2.1 Factory Proof ✅
   6. Approve by Supplier ✅
```

### ✅ สรุปวันที่ 5:

```
✅ Client Sample 5 endpoints (Multi-attempt + Dual Tracking)
✅ Artwork 6 endpoints (Version Management + File Upload)
✅ File Upload ทำงานจริง
✅ รวม: 11 endpoints ✅
```

---

---

# 🗓️ วันที่ 6 (9 ก.ค. 2026) — Logistics: Containers + Inventory + Delivery

> **เป้าหมาย:** ติดตามตู้ + คลัง + จัดส่ง + ⚠️ ตัดสต็อก (วันที่สำคัญที่สุด!)

---

## ช่วงเช้า (08:00 - 12:00) — Containers (5 Endpoints)

```
□ php artisan make:model Container
□ php artisan make:controller ContainerController

□ Endpoint #1: GET /api/containers → List + Filter by status
□ Endpoint #2: GET /api/containers/{id} → Detail + Projects inside
□ Endpoint #3: POST /api/containers → สร้าง + เชื่อม project_ids
□ Endpoint #4: PUT /api/containers/{id} → แก้ไข info
□ Endpoint #5: PATCH /api/containers/{id}/step → อัปเดตขั้นตอน
   - ⚠️ เมื่อ step = "Delivered" (ถึงคลัง) → อัปเดต Project status เป็น "Distributing"
```

---

## ช่วงบ่าย (13:00 - 17:00) — Inventory (5 Endpoints)

```
□ php artisan make:model Warehouse, StockItem, StockMovement
□ php artisan make:controller InventoryController

□ Endpoint #6: GET /api/inventory/warehouses → List คลัง
□ Endpoint #7: GET /api/inventory/warehouses/{id}/stocks → สต็อกในคลัง + Search
□ Endpoint #8: POST /api/inventory/receive → รับเข้าคลัง + สร้าง StockMovement (IN)
□ Endpoint #9: GET /api/inventory/movements → ประวัติ IN/OUT
□ Endpoint #10: GET /api/inventory/low-stock → สต็อกใกล้หมด (qty < threshold)
```

---

## ช่วงค่ำ (18:00 - 21:00) — ⚠️ Delivery + ตัดสต็อก (5 Endpoints)

```
□ php artisan make:model DispatchRound, DeliveryItem
□ php artisan make:controller DeliveryController

□ Endpoint #11: GET /api/delivery/rounds → List รอบส่ง
□ Endpoint #12: GET /api/delivery/rounds/{id} → Detail + Items
□ Endpoint #13: POST /api/delivery/rounds → สร้างรอบ + Items

□ Endpoint #14: PATCH /api/delivery/rounds/{id}/confirm
   - ⚠️⚠️⚠️ จุดสำคัญที่สุดของทั้ง 8 วัน ⚠️⚠️⚠️
   - ทำ (ภายใน DB::transaction):
     1. Loop ทุก delivery_item
     2. ดึง stock_item → lockForUpdate()
     3. เช็ค qty_in_stock >= qty_to_deliver (ถ้าไม่พอ → throw Exception)
     4. ตัดสต็อก: decrement qty_in_stock
     5. สร้าง StockMovement (OUT)
     6. อัปเดต dispatch status → "In Transit"
   - ⚠️ ถ้าอะไรพัง → Rollback ทั้งหมด (ไม่มีสต็อกถูกตัดผิด)
   - ทดสอบ: ตัดสต็อกเกินกว่ามี → ต้อง Error + ไม่มีอะไรเปลี่ยน

□ Endpoint #15: PATCH /api/delivery/rounds/{id}/complete
   - ทำ: status → "Delivered" + อัปเดต Project status
```

### ✅ สรุปวันที่ 6:

```
✅ Container 5 endpoints
✅ Inventory 5 endpoints
✅ Delivery 5 endpoints
✅ ⚠️ Atomic Transaction ตัดสต็อก ทดสอบผ่าน
✅ รวม: 15 endpoints ✅
```

---

---

# 🗓️ วันที่ 7 (10 ก.ค. 2026) — Dashboard + Reports + Polish

> **เป้าหมาย:** รวมข้อมูลจากทุกส่วน + ปรับปรุงคุณภาพโค้ด

---

## ช่วงเช้า (08:00 - 12:00) — Dashboard + Reports (7 Endpoints)

```
□ DashboardController:
   □ GET /api/dashboard/summary → KPI 4 ตัว (query จากหลายตาราง)
   □ GET /api/dashboard/activities → Activity Log ล่าสุด 20 รายการ
   □ GET /api/dashboard/revenue-chart → Revenue by month (GROUP BY MONTH)

□ ReportController:
   □ GET /api/reports/financial-summary → Revenue, COGS, Profit, Margin%
   □ GET /api/reports/operational-summary → Active Projects, Avg Lead Time, On-time%
   □ GET /api/reports/revenue-by-month → Bar Chart data
   □ GET /api/reports/profit-by-project → กำไรรายโปรเจกต์
```

---

## ช่วงบ่าย (13:00 - 17:00) — Polish

```
□ Error Handling:
   - สร้าง app/Exceptions/Handler.php → จัดการ Error Response เป็นระบบ
   - 400 Bad Request → { "success": false, "error": { "code": "BAD_REQUEST" } }
   - 401 Unauthorized
   - 403 Forbidden
   - 404 Not Found
   - 422 Validation Error
   - 500 Server Error

□ Request Validation (Form Requests):
   - php artisan make:request StoreCustomerRequest
   - php artisan make:request StoreProjectRequest
   - php artisan make:request StoreFinanceDocRequest
   - ... (สร้างสำหรับทุก POST/PUT endpoint ที่สำคัญ)

□ Pagination: ทุก List API ต้อง Paginate (default 20 per page)

□ Search: ทุก List API ต้องรองรับ ?search= parameter
```

---

## ช่วงค่ำ (18:00 - 21:00) — Seed Data + เตรียม Deploy

```
□ สร้าง DummyDataSeeder:
   - 5 Customers + Contacts + Addresses
   - 10 Projects (คละสถานะ Inquiry → Delivered)
   - 3 Suppliers + Quotes + Samples + Bills
   - 5 Finance Documents (QU, PI, DP, CI)
   - 2 Containers
   - 2 Warehouses + Stock
   - 1 Dispatch Round

□ Run Seed: php artisan db:seed → ข้อมูลจำลองพร้อม

□ เตรียมไฟล์ Deploy:
   - .env.production (สำหรับ Production DB)
   - .env.staging (สำหรับ Staging DB)
```

### ✅ สรุปวันที่ 7:

```
✅ Dashboard 3 endpoints
✅ Reports 4 endpoints
✅ Error Handling เป็นระบบ
✅ Validation ทุก Request
✅ Seed Data พร้อม
✅ รวม: 7 endpoints ✅
```

---

---

# 🗓️ วันที่ 8 (11 ก.ค. 2026) — Testing + Deploy 🚀

> **เป้าหมาย:** ทุกอย่างทำงานได้บน Server จริง!

---

## ช่วงเช้า (08:00 - 12:00) — Full Testing

```
□ ทดสอบ Auth:
   □ Login ✅  □ Me ✅  □ Logout ✅  □ Token หมดอายุ ✅

□ ทดสอบ Customer:
   □ List ✅  □ Search ✅  □ Create ✅  □ Update ✅
   □ Add Contact ✅  □ Add Address ✅  □ Stats ✅

□ ทดสอบ Project:
   □ List ✅  □ Filter by Status ✅  □ Search ✅
   □ Create (auto PPN-001) ✅  □ Update ✅
   □ Change Status ✅  □ Add Product ✅  □ Logs ✅

□ ทดสอบ Supplier:
   □ List ✅  □ Create ✅  □ Request Quote ✅
   □ Generate Link ✅  □ Manual Input ✅  □ Approve ✅
   □ Request Sample ✅  □ Create Bill ✅  □ Pay Bill ✅

□ ทดสอบ Finance:
   □ Create QU (auto number) ✅  □ Create PI (auto due_date) ✅
   □ Change Status ✅  □ Record Payment ✅
   □ Upload Slip ✅  □ Verify Payment ✅

□ ทดสอบ Samples:
   □ Create (attempt=1) ✅  □ Reject ✅  □ Create (attempt=2) ✅  □ Approve ✅

□ ทดสอบ Artwork:
   □ Upload V1 ✅  □ Reject + Feedback ✅  □ Upload V2 ✅  □ Approve ✅

□ ทดสอบ Container:
   □ Create + Link Projects ✅  □ Update Step ✅

□ ทดสอบ Inventory:
   □ Receive Stock ✅  □ Check Stock ✅

□ ทดสอบ Delivery:
   □ Create Round ✅  □ Confirm (ตัดสต็อก) ✅
   □ ⚠️ ตัดเกิน → Error + Rollback ✅
   □ Complete ✅

□ ทดสอบ Dashboard:
   □ Summary KPIs ✅  □ Activities ✅  □ Revenue Chart ✅

□ ทดสอบ Reports:
   □ Financial ✅  □ Operational ✅
```

---

## ช่วงบ่าย (13:00 - 17:00) — Deploy

```
□ Deploy to Staging:
   1. Upload ไฟล์ผ่าน FTP/Git ไปที่ Hostatom
   2. ตั้ง Document Root ชี้ไปที่ /ppn-api/public/
   3. Copy .env.staging → .env
   4. Run: composer install --no-dev
   5. Run: php artisan migrate
   6. Run: php artisan db:seed
   7. Run: php artisan config:cache
   8. Run: php artisan route:cache
   9. ทดสอบ: https://staging-api.xxxxx.com/api/auth/login → ได้ Token ✅

□ Deploy to Production:
   1. Copy ไฟล์เดียวกับ Staging
   2. Copy .env.production → .env (ชี้ไป ppn_production DB)
   3. Run: php artisan migrate (สร้างตารางเปล่า — ไม่ seed!)
   4. Run: php artisan config:cache
   5. ทดสอบ: https://api.xxxxx.com/api/auth/login → ได้ Token ✅
```

---

## ช่วงค่ำ (18:00 - 21:00) — API Doc + ส่งมอบ

```
□ เขียน API Documentation สรุป:
   - ทุก Endpoint + Method + URL + Body + Response
   - ส่งให้ Frontend Developer (หรือตัวเอง) ใช้เชื่อมต่อ Flutter

□ สรุปสิ่งที่ทำเสร็จ:
   - 26 ตาราง MySQL
   - 81 API Endpoints
   - JWT Authentication
   - File Upload System
   - Atomic Transaction (ตัดสต็อก)
   - Auto-generate Numbers (PPN-001, QU-2026-0001)
   - 2 Environments (Production + Staging)
```

### ✅ สรุปวันที่ 8:

```
✅ ทดสอบทุก API ผ่าน (81 endpoints)
✅ Deploy Staging สำเร็จ ✅
✅ Deploy Production สำเร็จ ✅
✅ API Documentation เสร็จ ✅
✅ 🎉🎉🎉 DONE! 🎉🎉🎉
```

---

---

# 📊 ตารางสรุปรวม 8 วัน

| วัน | วันที่ | หัวข้อ | Endpoints | สะสม |
|-----|--------|--------|-----------|------|
| 1 | 4 ก.ค. | Foundation + Auth | 3 | 3 |
| 2 | 5 ก.ค. | Customers + Projects | 18 | 21 |
| 3 | 6 ก.ค. | Suppliers (Quotes/Samples/Bills) | 17 | 38 |
| 4 | 7 ก.ค. | Finance (Docs/Payments) | 10 | 48 |
| 5 | 8 ก.ค. | Client Samples + Artwork | 11 | 59 |
| 6 | 9 ก.ค. | Container + Inventory + Delivery | 15 | 74 |
| 7 | 10 ก.ค. | Dashboard + Reports + Polish | 7 | 81 |
| 8 | 11 ก.ค. | Testing + Deploy | 0 | **81** |

---

> 📝 **สร้างโดย:** Antigravity AI Assistant  
> **วันที่:** 3 กรกฎาคม 2026
