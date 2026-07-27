# 📑 แผนงานและเช็คลิสต์สถาปัตยกรรม Multi-Tenant & Multi-Branch (`shop_id` / `branch_id`)
**ระบบ PPN GREAT ERP & Analytics Platform**

---

## 📌 สถานะความคืบหน้าภาพรวม (Overall Progress Tracking)

- [x] **Phase 1: สำรวจและออกแบบโครงสร้าง Database (Database Schema & Design)** `[3/3]`
- [x] **Phase 2: สร้างและรัน Database Migrations สำหรับ `shops` และ `branches`** `[4/4]`
- [x] **Phase 3: ปรับปรุงระบบ Authentication & Middleware (`TenantContextMiddleware`)** `[4/4]`
- [x] **Phase 4: ปรับปรุง Controller, Models และ Eloquent Global Scopes** `[5/5]`
- [x] **Phase 5: ปรับปรุง Frontend (Flutter Web) ระบบเลือกสาขา & Scope Header** `[4/4]`
- [x] **Phase 6: ปรับปรุง AI Analytics & Context Security Isolation** `[3/3]`
- [x] **Phase 7: การทดสอบยิง API, สิทธิ์การใช้งาน และ E2E Regression Testing** `[5/5]`
- [x] **Phase 8: Deployment & Post-Deployment Checklist** `[4/4]`

---

## 1. 🔍 สรุประบบปัจจุบัน (Current System Overview)

จากการสำรวจโครงสร้างของระบบปัจจุบันในซอร์สโค้ด (`ppn-api` และ `ppn_great`) พบว่า:

### 1.1 โครงสร้างเทคโนโลยี (Tech Stack)
* **Backend**: Laravel 11.x (PHP 8.2+) พัฒนาเป็น RESTful API
* **Frontend**: Flutter Web (Dart 3.x)
* **Database**: MySQL 8.0 / MariaDB (มีตารางรวม 26 ตาราง)
* **Authentication**: JWT Auth (`php-open-source-saver/jwt-auth`)
* **Real-time Event**: Pusher Channels Cloud SDK

### 1.2 โครงสร้างตารางและโมดูลในระบบปัจจุบัน (26 Tables)
1. **ผู้ใช้งาน & สิทธิ์**: `users`, `password_reset_tokens`, `sessions`
2. **ลูกค้า**: `customers`, `contact_people`, `shipping_addresses`
3. **โปรเจกต์ & สินค้า**: `projects`, `product_items`, `product_variations`, `product_files`, `additional_requests`
4. **จัดซื้อ & โรงงานจีน**: `suppliers`, `quote_requests`, `quote_request_revisions`, `supplier_bills`
5. **ตัวอย่างสินค้า & อาร์ตเวิร์ก**: `supplier_samples`, `client_samples`, `artwork_logs`
6. **การเงิน & ชำระเงิน**: `finance_documents`, `finance_doc_items`, `payments`
7. **โลจิสติกส์ & สต็อก**: `containers`, `warehouses`, `stock_items`, `stock_movements`, `dispatch_rounds`, `delivery_items`
8. **บันทึกกิจกรรม**: `activity_logs`

---

## 2. ⚠️ ปัญหาที่พบ (Identified Issues & Multi-tenant Risks)

1. **ระบบปัจจุบันเป็นแบบ Single-Tenant (Single-Store)**:
   - ตารางทั้งหมดในระบบ **ไม่มีการระบุ `shop_id` และ `branch_id`**
   - ผู้ใช้งานทุกคนที่ Login ผ่านระบบจะมองเห็นและแก้ไขข้อมูลชุดเดียวกันทั้งหมด (Flat Data Access)
2. **ความเสี่ยงข้อมูลข้ามร้าน/ข้ามสาขา (Data Leakage Risks)**:
   - หากเปิดใช้งานหลายร้านค้า ข้อมูลโปรเจกต์ (`projects`), สต็อกสินค้า (`stock_items`), และรายงานการเงิน (`finance_documents`) จะปะปนกันทันที
3. **ขาดระบบ Scope & Middleware ในการกรองสิทธิ์**:
   - Controller ปัจจุบันค้นหาข้อมูลด้วย `Model::findOrFail($id)` โดยไม่มีเงื่อนไข `WHERE shop_id = ? AND branch_id = ?` ทำให้หากสุ่มเปลี่ยน ID ใน URL จะสามารถอ่าน/แก้ไขข้อมูลของผู้อื่นได้
4. **ความเสี่ยงฝั่ง AI Analytics (AI Data Contamination)**:
   - หากเพิ่มระบบ AI Chat/Analytics ในอนาคต โดยไม่บังคับกรอง Scope ฝั่ง Backend มีความเสี่ยงที่ AI จะดึงข้อมูลสรุปยอดขายของร้านค้า/สาขาอื่นไปตอบ หรือถูก Prompt Injection ให้หลุดข้อมูลคู่แข่ง

---

## 3. 🏗️ โครงสร้าง `shop_id` และ `branch_id` ที่แนะนำ (Recommended Architecture)

ลำดับขั้นการปกครองข้อมูล (Data Hierarchy):
```text
ผู้ใช้งาน (Users)
└── ร้านค้า (shops: shop_id) [Tenant Level]
    └── สาขา (branches: branch_id) [Branch Level]
        ├── สินค้า / ราคาขายเฉพาะสาขา (branch_products)
        ├── โปรเจกต์ & ออเดอร์ (projects / orders)
        ├── ตัวอย่างสินค้า & อาร์ตเวิร์ก (samples / artworks)
        ├── เอกสารการเงิน & สลิปโอนเงิน (finance_documents / payments)
        ├── ตู้คอนเทนเนอร์ & ขนส่ง (containers / dispatch_rounds)
        ├── คลังสินค้า & สต็อก (warehouses / stock_items / stock_movements)
        ├── ประวัติกิจกรรม (activity_logs)
        └── บริบทข้อมูลวิเคราะห์ AI (AI Context Scope)
```

---

## 4. 🗄️ ตารางและ Field ที่ต้องแก้ไข/เพิ่มใหม่ (Database Schema Modifications)

### 4.1 ตารางสร้างใหม่ (New Tables)

#### 1. ตารางร้านค้า (`shops`)
```sql
CREATE TABLE `shops` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(191) NOT NULL,
  `code` VARCHAR(50) UNIQUE NULL,
  `owner_user_id` BIGINT UNSIGNED NOT NULL,
  `status` ENUM('active', 'suspended', 'closed') DEFAULT 'active',
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL
);
```

#### 2. ตารางสาขา (`branches`)
```sql
CREATE TABLE `branches` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `shop_id` BIGINT UNSIGNED NOT NULL,
  `code` VARCHAR(50) NOT NULL,
  `name` VARCHAR(191) NOT NULL,
  `address` TEXT NULL,
  `phone` VARCHAR(50) NULL,
  `status` ENUM('active', 'inactive') DEFAULT 'active',
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL
);
```

#### 3. ตารางผูกสิทธิ์สมาชิกร้านค้า (`user_shop_permissions`)
```sql
CREATE TABLE `user_shop_permissions` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `shop_id` BIGINT UNSIGNED NOT NULL,
  `role` ENUM('super_admin', 'shop_owner', 'shop_manager', 'auditor') NOT NULL,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL
);
```

#### 4. ตารางผูกสิทธิ์สมาชิกสาขา (`user_branch_permissions`)
```sql
CREATE TABLE `user_branch_permissions` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` BIGINT UNSIGNED NOT NULL,
  `shop_id` BIGINT UNSIGNED NOT NULL,
  `branch_id` BIGINT UNSIGNED NOT NULL,
  `role` ENUM('branch_manager', 'sales', 'purchasing', 'finance', 'warehouse', 'employee') NOT NULL,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL
);
```

---

## 5. 📑 เช็คลิสต์ติดตามการดำเนินงานรายเฟส (Detailed Phase-by-Phase Checklist)

### 🟩 Phase 1: สำรวจและออกแบบโครงสร้าง Database
- [x] `[x]` 1.1 สำรวจตารางเดิมทั้ง 26 ตารางใน `database/migrations/`
- [x] `[x]` 1.2 ออกแบบจุดเชื่อมต่อ Foreign Key `shop_id` และ `branch_id`
- [x] `[x]` 1.3 จัดทำ Migration Blueprint ให้รองรับ Data Migration สำหรับข้อมูลเก่า

### 🟩 Phase 2: สร้างและรัน Database Migrations
- [x] `[x]` 2.1 สร้าง Migration สำหรับตารางใหม่ `shops`, `branches`, `user_shop_permissions`, `user_branch_permissions`
- [x] `[x]` 2.2 สร้าง Migration เพิ่มฟิลด์ `shop_id` และ `branch_id` ให้ตารางเดิมทั้ง 19 ตาราง
- [x] `[x]` 2.3 สร้าง Migration Script สำหรับเติมค่า Default (`shop_id=1, branch_id=1`) ให้ข้อมูลเดิม
- [x] `[x]` 2.4 สั่งรัน `php artisan migrate:fresh --seed` และตรวจสอบความถูกต้องของโครงสร้าง DB

### 🟩 Phase 3: Authentication & Middleware Alignment
- [x] `[x]` 3.1 ปรับปรุงคลาส `User.php` และ JWT Claims ให้ฝัง `authorized_shop_id` และ `active_branch_id`
- [x] `[x]` 3.2 สร้าง `TenantContextMiddleware` ใน `app/Http/Middleware/` เพื่อดักจับและตรวจสอบสิทธิ์ในทุก Request
- [x] `[x]` 3.3 ลงทะเบียน Middleware ใน `bootstrap/app.php` หรือ `app/Http/Kernel.php`
- [x] `[x]` 3.4 อัปเดต `AuthController.php` ให้ส่งคืนสิทธิ์ร้านค้าและสาขาที่ผู้ใช้เข้าถึงได้

### 🟩 Phase 4: Models, Controllers & Global Scopes
- [x] `[x]` 4.1 สร้าง Eloquent Trait `BelongsToTenant` สำหรับใส่เงื่อนไข `WHERE shop_id = ? AND branch_id = ?` อัตโนมัติ
- [x] `[x]` 4.2 นำ Trait `BelongsToTenant` ไปใช้กับ Models หลัก (Project, Customer, StockItem, FinanceDocument ฯลฯ)
- [x] `[x]` 4.3 ปรับปรุง Controllers (ProjectController, CustomerController, FinanceDocController) ให้บันทึก `shop_id` และ `branch_id` อัตโนมัติ
- [x] `[x]` 4.4 ปรับปรุง ReportController และ DashboardController ให้แสดงยอดสรุปแยกรายสาขาและรวมทั้งร้าน
- [x] `[x]` 4.5 ทดสอบยิง API เพิ่ม/ดึงข้อมูลผ่าน Postman หรือ PHP Script

### 🟩 Phase 5: Frontend Update (Flutter Web)
- [x] `[x]` 5.1 อัปเดต Data Models ใน `ppn_great` ให้มีฟิลด์ `shopId` และ `branchId`
- [x] `[x]` 5.2 สร้าง `BranchProvider` หรือ `TenantProvider` สำหรับบริหารจัดการ State สาขาที่กำลังเลือกใช้งาน
- [x] `[x]` 5.3 เพิ่ม Dropdown เลือกสาขาในส่วน Header / Sidebar ของ `MainLayout`
- [x] `[x]` 5.4 ปรับปรุง Dio API Client ให้แนบ Header `X-Shop-Id` และ `X-Branch-Id` หรือใช้ URL Scope อัตโนมัติ

### 🟩 Phase 6: AI Analytics & Context Isolation
- [x] `[x]` 6.1 สร้าง `AIContextBuilderService` ดึงข้อมูลเฉพาะ `WHERE shop_id = ? AND branch_id = ?`
- [x] `[x]` 6.2 ใส่ System Instruction กำหนดให้ AI ตอบคำถามเฉพาะข้อมูลใน Scope ที่ได้รับเท่านั้น
- [x] `[x]` 6.3 ปรับปรุงการเก็บ Chat History ให้ผูกกับ `shop_id` และ `branch_id`
- [x] `[x]` 6.4 ตั้งค่า Cache Prefix สำหรับ AI คำตอบด้วย `ai_cache:shop_X:branch_Y`

### 🟩 Phase 7: การทดสอบระบบ (Quality Assurance & Testing)
- [x] `[x]` 7.1 รัน Database Test Cases (ตรวจสอบ FK, Constraints, Multi-branch Data Insertion)
- [x] `[x]` 7.2 รัน Auth & Permission Test Cases (ทดสอบการสลับบัญชีข้ามร้าน/ข้ามสาขา ต้องได้ 403 Forbidden)
- [x] `[x]` 7.3 รัน API Test Cases (ทดสอบการส่ง Parameter ผิดสาขา ต้องดึงข้อมูลไม่ได้)
- [x] `[x]` 7.4 รัน AI Context Isolation Test (ทดสอบ Prompt Injection ข้ามร้าน)
- [x] `[x]` 7.5 รัน Regression Test ทุกโมดูลเดิม (Login, Projects, Customers, Finance, Stock, Delivery)

### 🟩 Phase 8: Deployment & Monitoring
- [x] `[x]` 8.1 ทำการ Backup Full Production/Staging Database
- [x] `[x]` 8.2 สั่งรัน Database Migration และ Data Migration Script บน Staging/Production
- [x] `[x]` 8.3 ตรวจสอบ Log ความเรียบร้อยใน `storage/logs/laravel.log`
- [x] `[x]` 8.4 สอบทานผลงานร่วมกับผู้บริหารและทีมงาน

---

## 9. 🛡️ บทวิเคราะห์กรณีศึกษา: Developer ทดสอบระบบบน Production ร่วมกับลูกค้าจริง (5 Scenario Analysis)

### 🔴 Scenario 1: Developer สั่งรันคำสั่งรีเซ็ต DB (Destructive Database Commands)
* **สถานการณ์**: Dev เผลอรันคำสั่ง `php artisan migrate:fresh --seed` บน Production
* **ผลกระทบ**: ข้อมูลลูกค้าจริงลบหายทั้งหมด
* **🛡️ วิธีแก้ไข/ป้องกัน**: ใส่ Code Safeguard บล็อกคำสั่ง `migrate:fresh` บน `APP_ENV=production` และแยก DB `ppn_staging` ออกจาก `ppn_production`

### 🔴 Scenario 2: ข้อมูลทดสอบปะปนกับข้อมูลจริง (Dummy Data Contamination)
* **สถานการณ์**: Dev สร้างโปรเจกต์ทดสอบ *"Test 999"* ลงใน Shop ID เดียวกับลูกค้า
* **ผลกระทบ**: ลูกค้าเห็นออเดอร์แปลกปลอมและรายงานยอดขายคำนวณตัวเลขเพี้ยน
* **🛡️ วิธีแก้ไข/ป้องกัน**: สร้าง **Dev Sandbox Shop (`shop_id = 999`)** สำหรับ Dev โดยเฉพาะ ข้อมูลทดสอบจะไม่ปะปนกับ `shop_id = 1` ของลูกค้า 100%

### 🔴 Scenario 3: สัญญาณ Real-time เด้งไปรบกวนลูกค้า (Broadcast Notification Leak)
* **สถานการณ์**: Dev ยิง API Real-time ทดสอบเปลี่ยนสถานะออเดอร์
* **ผลกระทบ**: ป๊อปอัปแจ้งเตือนเด้งไปแสดงบนหน้าจอของลูกค้าจริงทุกคน
* **🛡️ วิธีแก้ไข/ป้องกัน**: เติม `-shop-{id}` ท้าย Pusher Channel เช่น `projects-channel-shop-999` สัญญาณจะเด้งเฉพาะหน้าจอ Dev เท่านั้น

### 🔴 Scenario 4: Query หนักจนฐานข้อมูลช้า (Database Lock & High CPU)
* **สถานการณ์**: Dev เขียน Query ทดสอบดึงข้อมูลขนาดใหญ่แบบไม่มี Index
* **ผลกระทบ**: หน้าเว็บลูกค้าหมุนค้าง (Timeout 504)
* **🛡️ วิธีแก้ไข/ป้องกัน**: ตั้งค่า API Query Timeout Limit 10 วินาที และแยก Query หนักไปทำบน Read-Replica DB

### 🔴 Scenario 5: ส่ง LINE / Email ออกไปหาลูกค้าจริง (External Alert Leakage)
* **สถานการณ์**: Dev กดอัปเดตออเดอร์ใน Sandbox แต่ระบบยิง LINE / Email หาลูกค้าจริง
* **ผลกระทบ**: ลูกค้าตกใจเข้าใจว่ามีออเดอร์เกิดขึ้นจริง
* **🛡️ วิธีแก้ไข/ป้องกัน**: ตรวจสอบ `if ($shopId === 999) return;` ระงับการยิง LINE/Email จาก Dev Sandbox ทันที

---

## 10. 📊 สรุปบทวิเคราะห์เปรียบเทียบสถาปัตยกรรม 3 แบบ (3 Multi-Tenant Models)

1. **Model 1: Discriminator Column (`shop_id`) [เลือกใช้งาน]**:
   - **ข้อดี**: เร็วที่สุด ประหยัดทรัพยากรเซิร์ฟเวอร์สูงสุด อัปเดตโค้ดง่ายที่สุด
   - **วิธีทำให้อ่านง่ายใน phpMyAdmin**: สร้าง **MySQL View** (เช่น `v_shop1_projects`) ดูแยกรายร้านได้ทันที
2. **Model 2: Table-Driven (`s1_projects`, `s2_projects`)**:
   - **ข้อเสียร้ายแรง**: เกิด Table Explosion (100 ร้านค้า = 2,600 ตาราง) ทำให้ MySQL ช้าและเครื่องล่มได้ง่าย
3. **Model 3: Database-per-Tenant (`ppn_shop1`, `ppn_shop2`)**:
   - **ข้อดี**: ปลอดภัยสูงสุด แต่ค่าใช้จ่าย Hosting สูงกว่า
