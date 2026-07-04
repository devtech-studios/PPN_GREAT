# คู่มือการทดสอบ PPN GREAT API (Backend) แบบละเอียด จากศูนย์จนครบถ้วน

คู่มือนี้ระบุขั้นตอนการตั้งค่าเครื่องและทดสอบ API ของ PPN GREAT ทั้งหมดในปัจจุบัน (Phase 1: Auth, Customers, Projects) ตั้งแต่ขั้นเตรียมฐานข้อมูล การรันเซิร์ฟเวอร์ ไปจนถึงตัวอย่างคำสั่งทดสอบทีละขั้นตอนด้วย **Postman** และ **PowerShell / curl**

---

## 🛠️ ขั้นตอนที่ 1: การเตรียมระบบและรันเซิร์ฟเวอร์ (Local Setup)

ก่อนเริ่มต้นทดสอบ ต้องแน่ใจว่าติดตั้ง XAMPP หรือ PHP และ MySQL เรียบร้อยแล้ว

### 1.1 ตรวจสอบและตั้งค่าฐานข้อมูล
เปิด MySQL ใน XAMPP (หรือเครื่องมืออื่น ๆ เช่น phpMyAdmin/HeidiSQL) และสร้างฐานข้อมูลว่างสำหรับ Staging:
```sql
CREATE DATABASE ppn_staging CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 1.2 ติดตั้ง Dependencies และ Migrations
เปิด Terminal/PowerShell ในโฟลเดอร์โปรเจกต์ `ppn-api` (`d:\07_Projects\Work\PNN\ppn-api`) แล้วรันคำสั่งเหล่านี้:

1. **ติดตั้ง Composer Packages:**
   ```bash
   composer install --ignore-platform-reqs
   ```
2. **สร้างไฟล์การตั้งค่าระบบ (`.env`):**
   คัดลอกไฟล์ `.env.example` มาเป็น `.env` และตั้งชื่อฐานข้อมูลรวมถึงการตั้งค่า JWT:
   ```ini
   DB_DATABASE=ppn_staging
   DB_USERNAME=root
   DB_PASSWORD=
   
   JWT_SECRET=WwQzW4bRtU... (หรือรันคำสั่งด้านล่างเพื่อสร้างคีย์อัตโนมัติ)
   ```
3. **สร้าง Application Key และ JWT Key:**
   ```bash
   php artisan key:generate
   php artisan jwt:secret
   ```
4. **รัน Migration และเติมข้อมูลตั้งต้น (Seeder):**
   ```bash
   php artisan migrate:fresh --seed
   ```
   *หมายเหตุ: คำสั่งนี้จะสร้าง 26 ตาราง และสร้างบัญชีผู้ใช้เริ่มต้นคือ `admin@ppngreat.com` (รหัสผ่าน: `password123`) และคลังสินค้าอัตโนมัติ 2 แห่ง*

### 1.3 เปิดรัน API Server
ก่อนรันคำสั่ง ต้องเปลี่ยนโฟลเดอร์เข้าไปที่โฟลเดอร์ย่อย `ppn-api` ก่อนทุกครั้ง:
```powershell
cd ppn-api
```

หากกดรันแล้วพบข้อผิดพลาดว่าไม่รู้จักคำสั่ง `php` (The term 'php' is not recognized...) ให้รันคำสั่งแอด PATH ของ XAMPP ชั่วคราวก่อนเริ่มใช้งานดังนี้:

**สำหรับ PowerShell:**
```powershell
$env:PATH = "C:\xampp\php;$env:PATH"
php artisan serve --port=8000
```

**สำหรับ Command Prompt (CMD):**
```cmd
set PATH=C:\xampp\php;%PATH%
php artisan serve --port=8000
```

เซิร์ฟเวอร์จะเปิดใช้งานที่ `http://127.0.0.1:8000`

---

## 📇 ขั้นตอนที่ 2: วิธีการส่ง Request เพื่อทดสอบ

คุณสามารถเลือกทดสอบได้ 2 วิธีหลัก:
1. **ผ่าน Postman (แนะนำสำหรับการกรอกง่ายและมี UI สวยงาม)**
2. **ผ่าน PowerShell (สำหรับทดสอบด้วยสคริปต์อัตโนมัติที่ทำงานเร็ว)**

### ข้อสำคัญในการเรียกใช้งาน API ทุกตัว (ยกเว้น Login):
*   ต้องนำ **JWT Token** ที่ได้จาก API Login ส่งมาใน HTTP Headers ทุกครั้ง ในรูปแบบ:
    *   **Header Name:** `Authorization`
    *   **Header Value:** `Bearer <JWT_TOKEN_HERE>`
*   ต้องระบุ Header พิเศษเพื่อให้ API คืนค่าเป็น JSON และรับค่าภาษาไทยได้ถูกต้อง:
    *   `Content-Type`: `application/json; charset=utf-8`
    *   `Accept`: `application/json`

---

## 🏃‍♂️ ขั้นตอนที่ 3: ลำดับฉากทดสอบ (Step-by-Step Test Scenarios)

ทำตามขั้นตอนด้านล่างทีละข้อเพื่อทดสอบ Flow การทำงานของระบบทั้งหมดตั้งแต่เข้าสู่ระบบ สร้างลูกค้า และทำโปรเจกต์งาน

### 🔑 ฉากที่ 1: การเข้าสู่ระบบและการขอสิทธิ์ (Authentication)

#### 1.1 ส่งคำขอเข้าสู่ระบบ (Login)
*   **Method:** `POST`
*   **URL:** `http://127.0.0.1:8000/api/auth/login`
*   **Body (JSON):**
    ```json
    {
      "email": "admin@ppngreat.com",
      "password": "password123"
    }
    ```
*   **ผลลัพธ์ที่คาดหวัง:** ตอบกลับรหัส 200 พร้อมกับมี `token` อยู่ในข้อมูล `data` ดังนี้:
    ```json
    {
      "success": true,
      "data": {
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "token_type": "bearer",
        "expires_in": 3600
      },
      "message": "เข้าสู่ระบบสำเร็จ"
    }
    ```
    *(ให้คัดลอกค่า token นี้ไปใส่ในส่วน Authorization Header ของ API ตัวถัดไป)*

#### 1.2 ตรวจสอบข้อมูลผู้ใช้ปัจจุบัน (Get Current User Profile)
*   **Method:** `GET`
*   **URL:** `http://127.0.0.1:8000/api/auth/me`
*   **Headers:** `Authorization: Bearer <token>`
*   **ผลลัพธ์ที่คาดหวัง:** ข้อมูลโปรไฟล์ของผู้ใช้คนนั้น เช่น `id`, `name`, `email` และบทบาท

#### 1.3 ออกจากระบบ (Logout)
*   **Method:** `POST`
*   **URL:** `http://127.0.0.1:8000/api/auth/logout`
*   **Headers:** `Authorization: Bearer <token>`
*   **ผลลัพธ์ที่คาดหวัง:** `"message": "ออกจากระบบสำเร็จ"` และโทเคนเดิมจะใช้งานไม่ได้อีกต่อไป

---

### 👥 ฉากที่ 2: ระบบจัดการลูกค้าและผู้ติดต่อ (Customer Management)

#### 2.1 เพิ่มลูกค้าใหม่ (Create Customer)
*   **Method:** `POST`
*   **URL:** `http://127.0.0.1:8000/api/customers`
*   **Headers:** `Authorization: Bearer <token>`
*   **Body (JSON):**
    ```json
    {
      "name": "บริษัท ปูนซิเมนต์ไทย จำกัด (มหาชน)",
      "type": "Enterprise",
      "tax_id": "0105556000123",
      "industry": "Construction",
      "phone": "02-586-3333",
      "email": "info@scg.com",
      "website": "https://www.scg.com",
      "lead_source": "Website",
      "notes": "ลูกค้ารายใหญ่ ต้องการสั่งทำของพรีเมียมบ่อยครั้ง"
    }
    ```
*   **ผลลัพธ์ที่คาดหวัง:** ข้อมูลลูกค้าใหม่ที่บันทึกพร้อมค่า `id` และสร้างประวัติ Log ในฐานข้อมูลอัตโนมัติ

#### 2.2 เพิ่มผู้ติดต่อหลักของลูกค้า (Add Contact Person)
*   **Method:** `POST`
*   **URL:** `http://127.0.0.1:8000/api/customers/1/contacts`
*   *(เปลี่ยนเลข `1` ตาม ID ของลูกค้าที่ได้จากการบันทึกก่อนหน้า)*
*   **Headers:** `Authorization: Bearer <token>`
*   **Body (JSON):**
    ```json
    {
      "name": "คุณสมชาย รักชาติ",
      "position": "ผู้จัดการฝ่ายจัดซื้อ",
      "phone": "081-234-5678",
      "email": "somchai.r@scg.com",
      "line_id": "somchai_scg",
      "is_primary": true
    }
    ```
*   **ผลลัพธ์ที่คาดหวัง:** บันทึกผู้ติดต่อเข้าตาราง `contact_people` และเมื่อระบุ `is_primary: true` ระบบจะนำผู้ติดต่อหลักคนเก่าของลูกค้าออกให้อัตโนมัติ

#### 2.3 เพิ่มที่อยู่จัดส่งของลูกค้า (Add Shipping Address)
*   **Method:** `POST`
*   **URL:** `http://127.0.0.1:8000/api/customers/1/addresses`
*   **Headers:** `Authorization: Bearer <token>`
*   **Body (JSON):**
    ```json
    {
      "recipient_name": "ฝ่ายคลังสินค้า SCG บางซื่อ",
      "phone": "02-586-4444",
      "address_line1": "1 ถนนปูนซิเมนต์ไทย",
      "address_line2": "แขวงบางซื่อ เขตบางซื่อ",
      "province": "กรุงเทพมหานคร",
      "postal_code": "10800",
      "is_default": true
    }
    ```

#### 2.4 ตรวจสอบข้อมูลสถิติของลูกค้า (Get Customer Statistics)
*   **Method:** `GET`
*   **URL:** `http://127.0.0.1:8000/api/customers/1/stats`
*   **Headers:** `Authorization: Bearer <token>`
*   **ผลลัพธ์ที่คาดหวัง:** ข้อมูลสรุป KPI เชิงพาณิชย์:
    ```json
    {
      "success": true,
      "data": {
        "customer_id": 1,
        "lifetime_revenue": 0.00,
        "total_projects": 0,
        "active_projects": 0,
        "payment_on_time_rate": 100
      }
    }
    ```

---

### 📂 ฉากที่ 3: ระบบท่อส่งงานและโปรเจกต์สินค้า (Projects & Pipelines)

#### 3.1 สร้างโปรเจกต์งานขายสินค้าพรีเมียม (Create Project)
*   **Method:** `POST`
*   **URL:** `http://127.0.0.1:8000/api/projects`
*   **Headers:** `Authorization: Bearer <token>`
*   **Body (JSON):**
    ```json
    {
      "customer_id": 1,
      "name": "โครงการสั่งผลิตกระเป๋าผ้าลดโลกร้อน SCG ครบรอบ 110 ปี",
      "sales_owner_id": 1,
      "source": "Referral",
      "status": "Inquiry",
      "end_client_info": "กลุ่มลูกค้าทั่วไปและคู่ค้าของ SCG",
      "estimated_value": 350000.00,
      "target_delivery_date": "2026-10-31",
      "special_instructions": "ต้องการโลโก้สีพิเศษและกล่องพลาสติกย่อยสลายได้"
    }
    ```
*   **ผลลัพธ์ที่คาดหวัง:** ตอบกลับข้อมูลที่สร้างเสร็จ โดยมี `project_code` เป็น **`PPN-001`** (ระบบจะรันนิ่งเป็น `PPN-002`, `PPN-003` ตามลำดับถัดไปแบบเรียงกันโดยไม่ซ้ำซ้อน)

#### 3.2 เพิ่มสินค้าเข้าไปในโปรเจกต์ (Add Product Item)
*   **Method:** `POST`
*   **URL:** `http://127.0.0.1:8000/api/projects/1/products`
*   *(เปลี่ยนเลข `1` ตาม ID ของโครงการที่สร้างเสร็จ)*
*   **Headers:** `Authorization: Bearer <token>`
*   **Body (JSON):**
    ```json
    {
      "name": "กระเป๋าผ้าแคนวาส 14 ออนซ์ หูหิ้วเชือกคอตตอน",
      "qty": 5000,
      "specs": "ขนาด 12x14x3 นิ้ว สีเบจธรรมชาติ สกรีนโลโก้ SCG 1 สีทองกากเพชร",
      "target_date": "2026-10-15"
    }
    ```

#### 3.3 เพิ่มคำขอเพิ่มเติมของลูกค้า (Add Additional Request)
*   **Method:** `POST`
*   **URL:** `http://127.0.0.1:8000/api/projects/1/additional-requests`
*   **Headers:** `Authorization: Bearer <token>`
*   **Body (JSON):**
    ```json
    {
      "request_type": "Other",
      "description": "ขอรับตัวอย่างผ้าตัวจริงมาลองสัมผัสเนื้อผิวภายใน 5 วัน",
      "status": "Pending"
    }
    ```

#### 3.4 อัปเดตสถานะของโครงการตามขั้นตอนจริง (Update Pipeline Status)
เมื่อเปลี่ยนสถานะการทำงานจากสอบถามราคา → สั่งผลิตสินค้าตัวอย่าง ให้เปลี่ยนค่าสถานะผ่าน API
*   **Method:** `PATCH`
*   **URL:** `http://127.0.0.1:8000/api/projects/1/status`
*   **Headers:** `Authorization: Bearer <token>`
*   **Body (JSON):**
    ```json
    {
      "status": "Sample"
    }
    ```
*   **ผลลัพธ์ที่คาดหวัง:** ได้รับการยืนยันการบันทึกสำเร็จ และระบบจะสร้างล็อกการเข้าสู่ขั้นตอนตัวอย่างอัตโนมัติ

#### 3.5 ตรวจสอบบันทึกกิจกรรมย้อนหลัง (Get Activity Logs)
ดึงรายการความเคลื่อนไหวทั้งหมดว่าใครทำอะไรกับโปรเจกต์นี้บ้าง:
*   **Method:** `GET`
*   **URL:** `http://127.0.0.1:8000/api/projects/1/logs`
*   **Headers:** `Authorization: Bearer <token>`
*   **ผลลัพธ์ที่คาดหวัง:** จะเห็นประวัติการเปลี่ยนแปลงทั้งหมด ตั้งแต่การสร้างงาน, การเพิ่มสินค้า, และบันทึกการปรับสถานะเป็น `Sample`

---

## 💻 ขั้นตอนที่ 4: สคริปต์รันการทดสอบอัตโนมัติด้วย PowerShell (รันปุ๊บรู้ผลทันที)

หากต้องการความเร็วสูงสุดและไม่ต้องกรอก Postman ด้วยมือทีละตัว คุณสามารถเปิด **PowerShell** บน Windows และคัดลอกโค้ดทั้งหมดด้านล่างไปวางเพื่อรันระบบทดสอบได้ทันที:

```powershell
# 1. ล็อกอินเข้าใช้งานเพื่อดึง JWT Token
$bodyAuth = @{ email = "admin@ppngreat.com"; password = "password123" } | ConvertTo-Json
$resAuth = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/auth/login" -Method Post -Body $bodyAuth -ContentType "application/json; charset=utf-8"
$token = $resAuth.data.token
Write-Host ">>> เข้าสู่ระบบสำเร็จ ได้รับ Token แล้ว: Bearer $token" -ForegroundColor Green

$headers = @{ Authorization = "Bearer $token" }

# 2. บันทึกสร้างลูกค้า SCG
$bodyCustomer = @{
    name = "บริษัท ปูนซิเมนต์ไทย จำกัด (มหาชน)"
    type = "Enterprise"
    tax_id = "0105556000123"
    industry = "Construction"
    phone = "02-586-3333"
    email = "info@scg.com"
} | ConvertTo-Json
$resCust = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/customers" -Method Post -Headers $headers -Body $bodyCustomer -ContentType "application/json; charset=utf-8"
$custId = $resCust.data.id
Write-Host ">>> บันทึกผู้ใช้สำเร็จ ID: $custId" -ForegroundColor Green

# 3. เพิ่มผู้ติดต่อหลัก
$bodyContact = @{
    name = "คุณสมชาย รักชาติ"
    position = "ผู้จัดการจัดซื้อ"
    phone = "081-234-5678"
    email = "somchai.r@scg.com"
    is_primary = $true
} | ConvertTo-Json
$resContact = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/customers/$custId/contacts" -Method Post -Headers $headers -Body $bodyContact -ContentType "application/json; charset=utf-8"
Write-Host ">>> เพิ่มผู้ติดต่อเรียบร้อย" -ForegroundColor Green

# 4. สร้างโปรเจกต์และสินค้าพรีเมียม
$bodyProject = @{
    customer_id = $custId
    name = "โครงการเสื้อยืดพรีเมียม SCG ครบรอบ 110 ปี"
    sales_owner_id = 1
    status = "Inquiry"
    estimated_value = 180000.00
} | ConvertTo-Json
$resProj = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/projects" -Method Post -Headers $headers -Body $bodyProject -ContentType "application/json; charset=utf-8"
$projId = $resProj.data.id
Write-Host ">>> สร้างโปรเจกต์สำเร็จ รหัสโปรเจกต์: $($resProj.data.project_code)" -ForegroundColor Green

# 5. เพิ่มสินค้าเข้าไปในโปรเจกต์
$bodyProduct = @{
    name = "เสื้อยืดโปโลเนื้อผ้าพรีเมียมพิมพ์ลายพิเศษ"
    qty = 1000
    specs = "เนื้อผ้าโปโลคอตตอนหนาพิเศษ ปักลายโลโก้ทอง"
} | ConvertTo-Json
$resProd = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/projects/$projId/products" -Method Post -Headers $headers -Body $bodyProduct -ContentType "application/json; charset=utf-8"
Write-Host ">>> เพิ่มสินค้าพรีเมียมสำเร็จ: $($resProd.data.name)" -ForegroundColor Green

# 6. ดึงข้อมูลประวัติกิจกรรมย้อนหลัง
$resLogs = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/projects/$projId/logs" -Method Get -Headers $headers
Write-Host "`n>>> ประวัติการทำงานในโปรเจกต์ (Logs):" -ForegroundColor Cyan
foreach ($log in $resLogs.data) {
    Write-Host "[$($log.created_at)] โดยผู้ใช้งาน ID $($log.user_id): Action -> $($log.action)" -ForegroundColor Cyan
}
```

---

## 🗄️ ขั้นตอนที่ 5: วิธีการตรวจสอบข้อมูลจริงในฐานข้อมูล (Database Validation)

หลังจากทำการยิงทดสอบแล้ว คุณสามารถเขียน Query ด้านล่างเพื่อยืนยันว่าข้อมูลต่าง ๆ รวมไปถึง **ภาษาไทย** ถูกเซฟลงในตารางเรียบร้อยโดยไม่มีการแตกของตัวอักษร:

```sql
-- 1. ดูรายการลูกค้า
SELECT id, name, type, tax_id, email FROM ppn_staging.customers;

-- 2. ดูผู้ติดต่อเชื่อมโยงกับลูกค้า
SELECT id, customer_id, name, position, is_primary FROM ppn_staging.contact_people;

-- 3. ตรวจสอบโปรเจกต์และรหัส PPN อัตโนมัติ
SELECT id, project_code, name, status, estimated_value FROM ppn_staging.projects;

-- 4. ตรวจสอบรายการสินค้าสเปกภาษาไทยในตาราง
SELECT id, project_id, name, qty, specs FROM ppn_staging.product_items;

-- 5. ตรวจสอบประวัติการบันทึกกิจกรรม Log
SELECT id, project_id, action, notes, created_at FROM ppn_staging.activity_logs ORDER BY id DESC;
```
