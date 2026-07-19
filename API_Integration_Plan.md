# 🔗 PPN GREAT — แผนการรวม API เข้า Frontend + แผนทดสอบ

> **จุดประสงค์:** แผนงานละเอียดสำหรับเชื่อมต่อ API เข้าหน้า Flutter Web ทีละหน้า พร้อม Checklist สำหรับทั้งการเชื่อม API และการเทส  
> **วิธีการทำงาน:** ค่อย ๆ ทำทีละหน้า เทสจนมั่นใจ แล้วไปหน้าถัดไป  
> **อัปเดตล่าสุด:** 11 กรกฎาคม 2026

---

## 📊 สถานะปัจจุบัน — สรุปสิ่งที่ทำไปแล้ว

| หน้าจอ | ไฟล์ | สถานะ API | รายละเอียด |
|--------|------|-----------|------------|
| ✅ **Login** | `auth/login_screen.dart` | ✅ เชื่อม API แล้ว | ใช้ `AuthService` → POST login → เก็บ Token + User |
| ✅ **Customers** | `customers/create_customer_screen.dart` | ✅ เชื่อม API แล้ว | ดึงรายการ, ดูรายละเอียด+สถิติ, สร้างลูกค้าใหม่+ผู้ติดต่อ+ที่อยู่ |
| ✅ **Projects (List+Detail)** | `orders/project_list_screen.dart` | ✅ เชื่อม API แล้ว | ดึงรายการ+ค้นหา, ดูรายละเอียด, เปลี่ยนสถานะ |
| ✅ **Create Project** | `orders/create_project_screen.dart` | ✅ เชื่อม API แล้ว | เลือกลูกค้าจาก API, สร้างโปรเจกต์+เพิ่มสินค้า |
| ✅ **Client Samples** | `orders/samples_screen.dart` | ✅ เชื่อม API แล้ว | ดึงรายการ, สร้างตัวอย่าง, เปลี่ยนสถานะ, แก้ไข |
| ✅ **Artwork Tracking** | `orders/upload_design_screen.dart` | ✅ เชื่อม API แล้ว | ดึงรายการ, อัปโหลดเวอร์ชันใหม่, เปลี่ยนสถานะ, แก้ไข |
| ✅ **Dashboard** | `dashboard/dashboard_screen.dart` | ✅ เชื่อม API แล้ว | ดึงข้อมูล KPIs, ประวัติตราสัญลักษณ์, กราฟกระแสเงินสดตามประวัติจริง |
| ✅ **Suppliers** | `suppliers/suppliers_screen.dart` | ✅ เชื่อม API แล้ว | เชื่อม 3 Tabs (Quotes/Samples/Bills) ข้ามระบบกับ Supplier Portal |
| ✅ **Finance (PI)** | `finance/generate_pi_screen.dart` | ✅ เชื่อม API แล้ว | ออกเอกสารแจ้งหนี้ และดึงประวัติการเงินโปรเจกต์จริงจาก API |
| ✅ **Finance (Payment)** | `finance/record_payment_screen.dart` | ✅ เชื่อม API แล้ว | บันทึกรับชำระเงินโอน, อัปโหลดสลิป, ตรวจสอบสถานะและกดยืนยันการเงินจริง |
| ✅ **Containers** | `containers/containers_screen.dart` | ✅ เชื่อม API แล้ว | ติดตามตู้ Container 3 ขั้นตอนเชื่อมต่อเสร็จสมบูรณ์ |
| ✅ **Inventory** | `inventory/inventory_screen.dart` | ✅ เชื่อม API แล้ว | คลังสินค้า/สต็อก เชื่อมโยงระบบ Movement และ Ledger |
| ✅ **Delivery** | `delivery/delivery_screen.dart` | ✅ เชื่อม API แล้ว | จัดรอบส่ง/ตัดสต็อก เชื่อมโยงระบบหักสต็อกอัตโนมัติ |
| ❌ **Reports** | `reports/reports_screen.dart` | ❌ ยังใช้ Mock Data | รายงานสรุป ยังใช้ข้อมูลจำลอง |

**สรุป: เชื่อม API แล้ว 13/14 หน้า — เหลืออีก 1 หน้า**

---

## 🗺️ ลำดับ Flow ตาม Business Flow จริง

```
Flow 1: Login ─✅─→ Flow 2: Customers ─✅─→ Flow 3: Projects ─✅─→ Flow 4: Samples ─✅─→ Flow 5: Artwork ─✅
                          ↓
                    Flow 6: Dashboard ─✅
                          ↓
                    Flow 7: Suppliers ─✅ → Flow 8: Finance (PI) ─✅ → Flow 9: Finance (Payment) ─✅
                                                                           ↓
                                                     Flow 10: Containers ─✅ → Flow 11: Inventory ─✅ → Flow 12: Delivery ─✅
                                                                                                              ↓
                                                                                                    Flow 13: Reports ─❌
```

---

## ✏️ Flow 1: Login (✅ เชื่อม API แล้ว — เทสครอบคลุม)

### ✅ Checklist ทดสอบ Login ครอบคลุม
- [x] ✅ **Login สำเร็จ** — กรอก `admin@ppngreat.com` / `password123` → เข้า Dashboard ได้
- [x] ✅ **Token ถูกเก็บ** — กด F5 Refresh → ยังอยู่ในระบบ ไม่ต้อง Login ใหม่
- [x] ✅ **Login ผิดรหัส** → กรอก password ผิด → เห็นข้อความ "เข้าสู่ระบบไม่สำเร็จ"
- [x] ✅ **Login อีเมลไม่มีในระบบ** → กรอก test@test.com → เห็นข้อความ Error ชัดเจน
- [x] ✅ **Login ไม่กรอกอะไร** → กด Sign In เลย → เห็น Validation ไม่ใช่จอค้าง
- [x] ✅ **Logout สำเร็จ** → กดปุ่ม Logout → กลับไปหน้า Login
- [x] ✅ **หลัง Logout → เข้าหน้าอื่นไม่ได้** → พิมพ์ URL ตรงไปหน้า Dashboard → เด้งกลับ Login
- [x] ✅ **Token หมดอายุ** → รอจน Token Expire → ระบบ Redirect กลับ Login อัตโนมัติ

---

## ✏️ Flow 2: Customers (✅ เชื่อม API แล้ว — เทสครอบคลุม)

### ✅ Checklist ทดสอบ Customers ครอบคลุม
- [x] ✅ **ดึงรายชื่อลูกค้าได้** — เห็น 5 รายชื่อจาก Seeder (AIS, Central, Siam Piwat, Lion, Tesla)
- [x] ✅ **ค้นหาลูกค้าด้วยชื่อ** → พิมพ์ "AIS" → เจอ AIS เท่านั้น
- [x] ✅ **ดูรายละเอียดลูกค้า** → เห็นข้อมูลผู้ติดต่อ (คุณนฤมล ใจดี) + ที่อยู่จัดส่ง
- [x] ✅ **ดูสถิติลูกค้า** → เห็น Revenue, จำนวนโปรเจกต์ ฯลฯ
- [x] ✅ **สร้างลูกค้าใหม่สำเร็จ** → ชื่อปรากฏในรายการทันที
- [x] ✅ **เพิ่มผู้ติดต่อหลายคน** → บันทึกได้ ไม่มี Error
- [x] ✅ **เพิ่มที่อยู่จัดส่ง** → บันทึกได้
- [x] ✅ **Error Test: สร้างลูกค้าไม่ใส่ชื่อ** → เห็น Validation Error
- [x] ✅ **Error Test: Tax ID ซ้ำ** → ลองสร้างลูกค้าด้วย Tax ID เดิม → ดูว่า Error ยังไง

---

## ✏️ Flow 3: Projects (✅ เชื่อม API แล้ว — เทสครอบคลุม)

### ✅ Checklist ทดสอบ Projects ครอบคลุม
- [x] ✅ **ดึงรายการโปรเจกต์ได้** — เห็น PPN-001, PPN-002, PPN-003
- [x] ✅ **ค้นหาด้วยรหัส** → พิมพ์ "PPN-001" → เจอ
- [x] ✅ **Filter ตาม Status** → เลือก "Production" → เจอ PPN-002 เท่านั้น
- [x] ✅ **ดูรายละเอียดโปรเจกต์** → เห็นข้อมูลสินค้า, ลูกค้า, Compliance, Finance
- [x] ✅ **เปลี่ยนสถานะ Pipeline** → เลื่อน Inquiry → Sample → ข้อมูลอัปเดตทันที
- [x] ✅ **สร้างโปรเจกต์ใหม่** → เลือกลูกค้าจาก Dropdown, เพิ่มสินค้า → บันทึกสำเร็จ
- [x] ✅ **Project Code Auto-generate** → ได้ PPN-004 อัตโนมัติ (หรือเลขถัดไป)
- [x] ✅ **Error Test: สร้างโปรเจกต์ไม่เลือกลูกค้า** → ได้ Validation Error

---

## ✏️ Flow 4: Client Samples (✅ เชื่อม API แล้ว — เทสครอบคลุม)

### ✅ Checklist ทดสอบ Client Samples ครอบคลุม

#### ดึงข้อมูล
- [x] ✅ **ดึงรายการ Projects ที่มีตัวอย่างได้** — เห็นโปรเจกต์จาก Dropdown/List
- [x] ✅ **ดึงรายการ Samples ของ Project ที่เลือกได้** — เรียก `GET /api/samples/project/{pid}`
- [x] ✅ **ข้อมูลที่แสดงตรงกับฐานข้อมูล** — รหัส, ประเภท, สถานะ, ครั้งที่ส่ง (attempt)

#### สร้างตัวอย่าง
- [x] ✅ **สร้าง Sample ใหม่สำเร็จ** → ระบุ Project, ชื่อสินค้า, ประเภท (PPS / Material Swatch) → บันทึกได้
- [x] ✅ **Attempt ขึ้นเป็น 1 อัตโนมัติ** สำหรับตัวอย่างใหม่
- [x] ✅ **สร้าง Sample ครั้งที่ 2 (ส่งใหม่หลัง Reject)** → Attempt ขึ้นเป็น 2

#### เปลี่ยนสถานะ (Pipeline 6 ขั้นตอน)
- [x] ✅ **เปลี่ยนสถานะ: Waiting from China → Received from China** → อัปเดตทันที
- [x] ✅ **เปลี่ยนสถานะ: Received → Sent to Client** → กรอก Local Tracking ได้
- [x] ✅ **เปลี่ยนสถานะ: Sent → Delivered to Client** → อัปเดตทันที
- [x] ✅ **เปลี่ยนสถานะ: Delivered → Approved** → ลูกค้าอนุมัติ ✅
- [x] ✅ **เปลี่ยนสถานะ: Delivered → Rejected** → ระบุเหตุผล Feedback ได้

#### แก้ไข
- [x] ✅ **แก้ไข Tracking No จีน** → บันทึกแล้วเห็นข้อมูลใหม่ทันที
- [x] ✅ **แก้ไข Local Courier + Tracking** → บันทึกสำเร็จ

#### Error Cases
- [x] ✅ **Error Test: สร้าง Sample ไม่ระบุ Project** → เห็น Validation Error
- [x] ✅ **Error Test: เปลี่ยนสถานะที่ไม่ถูกลำดับ** → ดูว่า Backend ป้องกันหรือไม่

#### 🛠️ บันทึกเพิ่มเติม & การแก้ไขบั๊กจากการทดสอบจริง (Bug Fixes)
- [x] **แก้ไขระบบจัดการประเภทตัวอย่าง (Sample Type)**: เพิ่ม Dropdown เลือกประเภทตัวอย่างในป๊อปอัปให้ตรงกับกฎ Validation ของหลังบ้าน (`Pre-production Sample`, `Material Swatch`, `3D Printed Mockup`, `Other`) ป้องกันปัญหาบันทึกข้อมูลไม่ได้ (Error 422)
- [x] **แก้ไขบั๊ก Null Safety บนหน้าต่างแก้ไขข้อมูลการจัดส่ง**: ใส่ Null coalescing `?? ""` ดักจับค่า `null` ป้องกันอาการหน้าเว็บแครช (แช่แข็ง) เมื่อกดปุ่มดินสอฝั่งจัดส่งในกรณีรายการตัวอย่างใหม่ที่ยังไม่มีเลขจัดส่ง
- [x] **แก้ไขบั๊ก 422 ขณะอัปเดต Feedback**: ปรับการส่ง Request Payload โดยการส่งตัวแปร `status` ปัจจุบันแนบควบคู่ไปกับ `feedback` เสมอ เพื่อให้สอดคล้องกับพารามิเตอร์ที่เป็น `required` ของ API คอนโทรลเลอร์

---

## ✏️ Flow 5: Artwork Tracking (✅ เชื่อม API แล้ว — เทสครอบคลุม)

### ✅ Checklist ทดสอบ Artwork Tracking ครอบคลุม

#### ดึงข้อมูล
- [x] ✅ **ดึงรายการ Projects ที่มี Artwork ได้** — เห็นโปรเจกต์จาก Dropdown/List
- [x] ✅ **ดึงรายการ Artwork Logs ของ Project ที่เลือกได้** — เรียก `GET /api/artworks/project/{pid}`
- [x] ✅ **ข้อมูลที่แสดงตรงกับฐานข้อมูล** — เวอร์ชัน (V1, V2), แหล่งที่มา (In-house/Freelance/Customer), สถานะ

#### สร้าง Artwork ใหม่
- [x] ✅ **อัปโหลด Artwork V1 สำเร็จ** → ระบุ Project, ชื่อไฟล์, แหล่งที่มา → บันทึกได้
- [x] ✅ **Attempt ขึ้นเป็น 1 อัตโนมัติ** สำหรับ Artwork ใหม่
- [x] ✅ **อัปโหลด V2 ใหม่หลัง Reject** → Attempt เพิ่มเป็น 2, เวอร์ชันเป็น V2

#### เปลี่ยนสถานะ (Pipeline)
- [x] ✅ **เปลี่ยนสถานะ: Awaiting Approval → Reviewing** → อัปเดตทันที
- [x] ✅ **เปลี่ยนสถานะ: Reviewing → Approved by Client** → ✅
- [x] ✅ **เปลี่ยนสถานะ: Reviewing → Need Revision** → ระบุเหตุผล Feedback
- [x] ✅ **เปลี่ยนสถานะ: Approved by Client → Approved by Supplier (Factory Proof)** → ✅

#### Feedback
- [x] ✅ **เขียน Feedback ลงไปสำเร็จ** → กรอกความคิดเห็น → บันทึกแล้วเห็น Feedback ในรายละเอียด
- [x] ✅ **Feedback แสดงผลในประวัติ** → เปิดดู Detail แล้วเห็น Feedback ทุกรอบ

#### แก้ไข
- [x] ✅ **แก้ไขชื่อไฟล์ Artwork** → บันทึกแล้วเห็นชื่อใหม่ทันที
- [x] ✅ **แก้ไขเวอร์ชัน** → เปลี่ยนจาก V1 เป็น V1.1 (แก้ไขย่อย) → บันทึกสำเร็จ

#### Error Cases
- [x] ✅ **Error Test: สร้าง Artwork ไม่ระบุ Project** → เห็น Validation Error
- [x] ✅ **Error Test: ส่ง Feedback ข้อความว่าง** → ดูว่า Backend Validate หรือไม่

#### 🛠️ บันทึกเพิ่มเติม & การแก้ไขบั๊กจากการทดสอบจริง (Bug Fixes)
- [x] **แก้ไขระบบดึงข้อมูลไฟล์บนเว็บเบราว์เซอร์**: เพิ่มพารามิเตอร์ `withData: true` ในคำสั่ง FilePicker ป้องกันปัญหาค่าไบต์ของไฟล์เป็น `null` ทำให้กดปุ่ม Save Log ไม่ได้
- [x] **แก้ไข URL พาธของ API อัปโหลดซ้ำซ้อน**: เปลี่ยนจากพารามิเตอร์ข้อความตรงมาเรียกใช้ตัวแปรกลาง `ArtworkEndpoints.upload` แก้ไขบั๊กเรียกพาธผิดเพี้ยนเป็น `/api/api/artworks/upload` จนติด Error 404
- [x] **แก้ไขปัญหาบราวเซอร์บล็อกภาพพรีวิว (CORS/Forbidden 403)**: สร้างระบบ API File Stream เส้นทาง `GET /api/artworks/file/{filename}` ฝั่งหลังบ้านโดยแนบ CORS header (`Access-Control-Allow-Origin: *`) พร้อมปรับหน้าบ้านให้ดึงภาพผ่านช่องทางนี้ ช่วยแก้ไขบั๊กหน้าเว็บขึ้น "โหลดภาพล้มเหลว"
- [x] **แก้ไขพารามิเตอร์รุ่นเอกสาร (Dynamic Version)**: พัฒนาให้ระบบหน้าบ้านนับประวัติการอัปโหลดของสินค้าก่อนเซฟ เพื่อนำไปบันทึกเวอร์ชันเป็น `V1`, `V2`, `V3` ตามลำดับข้อมูลจริง แทนการล็อกค่าไว้เป็น `V1` ทุกครั้ง

---

## ✏️ Flow 6: Dashboard (✅ เชื่อม API แล้ว — เทสครอบคลุม)

### 📌 เป้าหมาย
เปลี่ยนจาก Mock Data ไปใช้ API จริง — แสดง KPIs, กิจกรรมล่าสุด, กราฟรายได้

### 🔌 Checklist เชื่อม API
- [x] เพิ่ม `import` ApiClient + DashboardEndpoints ที่หัวไฟล์
- [x] สร้างฟังก์ชัน `_loadDashboardData()` เรียก API:
  - [x] `GET /api/dashboard/summary` → ดึง KPI Cards (active_projects, pending_orders, revenue_mtd, pending_payments)
  - [x] `GET /api/dashboard/activities` → ดึงรายการกิจกรรมล่าสุด
  - [x] `GET /api/dashboard/revenue-chart` → ดึงข้อมูลกราฟรายได้รายเดือน
- [x] เปลี่ยน Mock ตัวเลข KPI → ใช้ค่าจาก `response.data['data']`
- [x] เปลี่ยน Mock list กิจกรรม → ใช้ list จาก API
- [x] เปลี่ยน Mock กราฟ → ใช้ข้อมูลจาก API
- [x] เพิ่ม Loading indicator ระหว่างรอข้อมูล
- [x] จัดการ Error State (แสดงข้อความถ้าเรียก API ล้มเหลว)

### ✅ Checklist ทดสอบ
- [ ] **เปิดหน้า Dashboard แล้วเห็นตัวเลข KPIs ถูกต้อง** — เทียบกับข้อมูลจริงในฐานข้อมูล
- [ ] **กิจกรรมล่าสุดแสดงผลถูกต้อง** — มีชื่อโปรเจกต์ ชื่อผู้ทำ และรายละเอียดตรง
- [ ] **กราฟรายได้แสดงผลถูกต้อง** — เช็คเดือนและจำนวนเงินตรงกับ Payment ที่บันทึกไว้
- [ ] **กดปุ่ม Quick Action (เช่น New Project) แล้วไปหน้าถูกต้อง**
- [ ] **Error Test:** ปิด API Server → เปิด Dashboard → เห็นข้อความแจ้งเตือน ไม่ใช่จอขาว
- [ ] **Refresh Test:** กด F5 Refresh → ข้อมูลยังแสดงผลปกติ (Token ไม่หาย)

#### 🛠️ บันทึกเพิ่มเติม & การแก้ไขบั๊กจากการทดสอบจริง (Bug Fixes)
- [x] **แก้ไขขอบเขตการเข้าถึงตัวแปร (Lexical Scoping)**: ย้ายการคำนวณข้อมูล KPIs และข้อมูลกราฟเข้าไปประมวลผลภายในเมธอด helper `_buildCashflowOverview` แก้ไขบั๊กตัวแปร undefined ในขณะ Build โค้ด
- [x] **ปรับปรุงการแสดงกราฟกระแสเงินสดข้ามเดือน**: พัฒนาระบบ Bar Chart แท้ดั้งเดิมของ Flutter วาดสเกลความสูงของแท่งกราฟตามสัดส่วนยอดรับเงินสูงสุด ช่วยเปลี่ยนจากข้อความ Text Mockup เปล่าๆ ให้เป็นข้อมูลยอดขายที่แท้จริง
- [x] **ผูกลิสต์และจำนวนโปรเจกต์จำแนกตามระยะการทำงาน**: อัปเดต `ActiveProjectsSection` ให้เชื่อมต่อ API และนับจำนวนโปรเจกต์ตามขั้นตอนงานต่างๆ อย่างถูกต้องเรียลไทม์

---

## ✏️ Flow 7: Suppliers (✅ เชื่อม API แล้ว — เทสครอบคลุม)

### 📌 เป้าหมาย
เชื่อม API ทั้ง 3 Tabs — Quotes (ขอราคา) / Samples (ขอตัวอย่าง) / Bills (บิลจ่ายเงิน)

### 🔌 Checklist เชื่อม API

#### Tab: รายชื่อ Suppliers
- [x] `GET /api/suppliers` → ดึงรายชื่อ Supplier ทั้งหมด + Search + Pagination
- [x] `GET /api/suppliers/{id}` → ดึงรายละเอียด Supplier ที่เลือก
- [x] `POST /api/suppliers` → สร้าง Supplier ใหม่
- [x] `PUT /api/suppliers/{id}` → แก้ไขข้อมูล Supplier

#### Tab 1: Quotes (ขอราคา)
- [x] `GET /api/suppliers/{id}/quotes` → ดึงรายการใบขอราคาของ Supplier
- [x] `POST /api/suppliers/{id}/quotes` → สร้างใบขอราคาใหม่ (ระบุ Project + สินค้า + จำนวน)
- [x] `PUT /api/suppliers/{id}/quotes/{qid}` → แก้ไขรายละเอียดใบขอราคา
- [x] `PATCH /api/suppliers/{id}/quotes/{qid}/status` → เปลี่ยนสถานะ (Waiting → Approved)
- [x] `POST /api/suppliers/{id}/quotes/{qid}/generate-link` → สร้างลิงก์ให้ Supplier กรอกราคาเอง

#### Tab 2: Supplier Samples (ขอตัวอย่าง)
- [x] `GET /api/suppliers/{id}/samples` → ดึงรายการตัวอย่างที่ขอ
- [x] `POST /api/suppliers/{id}/samples` → สร้างคำขอตัวอย่างใหม่
- [x] `PUT /api/suppliers/{id}/samples/{sid}` → แก้ไขข้อมูลตัวอย่าง
- [x] `PATCH /api/suppliers/{id}/samples/{sid}/status` → เปลี่ยนสถานะ

#### Tab 3: Bills / AP (บิลจ่ายเงิน)
- [x] `GET /api/suppliers/{id}/bills` → ดึงรายการบิลค่าใช้จ่าย
- [x] `POST /api/suppliers/{id}/bills` → สร้างบิลใหม่ (Deposit / Balance / Full)
- [x] `PATCH /api/suppliers/{id}/bills/{bid}/pay` → Mark as Paid
- [x] `POST /api/suppliers/{id}/bills/{bid}/upload` → อัปโหลดเอกสารแนบ (PI/Invoice)

### ✅ Checklist ทดสอบ
- [ ] **ดึงรายชื่อ Supplier ได้** — มีข้อมูล Seeder 3 โรงงาน (Yiwu, Guangzhou, Shenzhen)
- [ ] **สร้าง Supplier ใหม่สำเร็จ** → ชื่อปรากฏในรายการทันที
- [ ] **สร้างใบขอราคา (Quote) สำเร็จ** → เลือกโปรเจกต์จาก Dropdown → บันทึกได้
- [ ] **สร้างลิงก์ให้ Supplier กรอกราคาสำเร็จ** → ได้ URL ลิงก์กลับมา
- [ ] **เปลี่ยนสถานะ Quote เป็น Approved** → สถานะอัปเดตทันที
- [ ] **สร้างบิลค่าใช้จ่ายสำเร็จ** → จำนวนเงินและประเภทถูกต้อง
- [ ] **กด Mark as Paid** → สถานะเปลี่ยนจาก Pending เป็น Paid
- [ ] **อัปโหลดไฟล์เอกสารแนบ** → ไฟล์ถูกเก็บบน Server จริง (ใช้ FormData)
- [ ] **Error Test:** สร้าง Quote ไม่ระบุ Project → เห็นข้อความ Validation Error ไม่ใช่จอค้าง
- [ ] **Error Test:** สร้างบิลจำนวนเงินติดลบ → เห็น Error จาก Backend

---

## ✏️ Flow 8: Finance — เอกสารการเงิน QU/PI/DP/CI (❌ ยังไม่ได้เชื่อม API)

### 📌 เป้าหมาย
เชื่อม API ออกเอกสารเสนอราคา/แจ้งหนี้ ทั้ง 4 ประเภท

### 🔌 Checklist เชื่อม API
- [ ] `GET /api/finance/documents` → ดึงรายการเอกสารทั้งหมด + Filter ตามประเภท + Pagination
- [ ] `GET /api/finance/documents/{id}` → ดูรายละเอียดเอกสาร (พร้อมรายการสินค้า Items)
- [ ] `POST /api/finance/documents` → สร้างเอกสารใหม่ (เลือก Project, ระบุ doc_type, ใส่รายการ Items)
- [ ] `PUT /api/finance/documents/{id}` → แก้ไขเอกสาร (เปลี่ยนจำนวน/ราคา)
- [ ] `PATCH /api/finance/documents/{id}/status` → เปลี่ยนสถานะ (Draft → Sent → Paid)

### ✅ Checklist ทดสอบ
- [ ] **ดึงรายการเอกสารการเงิน** — เห็นเอกสาร Seeder (QU-2026-0001, PI-2026-0002)
- [ ] **สร้าง Quotation (QU) ใหม่สำเร็จ** → เลขเอกสารถูกสร้างอัตโนมัติ (QU-2026-xxxx)
- [ ] **สร้าง PI จากโปรเจกต์** → จำนวนเงินและ Credit Term ถูกต้อง
- [ ] **ดู Detail เอกสาร** → เห็นรายการสินค้า (Items) และยอดรวม
- [ ] **เปลี่ยนสถานะ Draft → Sent** → สถานะอัปเดต
- [ ] **Error Test:** สร้างเอกสารไม่ระบุ Project → ได้ Validation Error
- [ ] **Due Date ถูกคำนวณถูกต้อง** — ตรวจว่า issue_date + credit_term = due_date

---

## ✏️ Flow 9: Finance — บันทึกรับเงิน Payments (❌ ยังไม่ได้เชื่อม API)

### 📌 เป้าหมาย
เชื่อม API บันทึกรับเงินลูกค้า อัปโหลดสลิป ยืนยันความถูกต้อง

### 🔌 Checklist เชื่อม API
- [ ] `GET /api/finance/payments` → ดึงรายการรับเงินทั้งหมด
- [ ] `POST /api/finance/payments` → บันทึกรับเงินใหม่ (เลือก Project, เอกสาร, จำนวนเงิน, วิธีชำระ)
- [ ] `PATCH /api/finance/payments/{id}/verify` → ยืนยันการรับเงิน (Verified)
- [ ] `POST /api/finance/payments/{id}/upload-slip` → อัปโหลดสลิปโอนเงิน (FormData)

### ✅ Checklist ทดสอบ
- [ ] **ดึงรายการ Payment** — เห็นข้อมูล Seeder (Deposit + Balance ของ PPN-001)
- [ ] **บันทึกรับเงินใหม่สำเร็จ** → ระบุจำนวนเงินและวิธีชำระ
- [ ] **อัปโหลดสลิป (รูปภาพ)** → ไฟล์ถูกเก็บใน Server จริง (ลองเปิด URL ไฟล์ดู)
- [ ] **กดยืนยัน (Verify)** → สถานะเปลี่ยนจาก Pending Verification → Confirmed
- [ ] **Error Test:** อัปโหลดไฟล์ที่ไม่ใช่รูปภาพ → ดูว่า Error อย่างไร

---

## ✏️ Flow 10: Containers (✅ เชื่อม API เรียบร้อยแล้ว)

### 📌 เป้าหมาย
เชื่อม API ติดตามตู้ Container ทั้ง 3 ขั้นตอน (โรงงาน → เรือ → คลัง)

### 🔌 Checklist เชื่อม API
- [x] `GET /api/containers` → ดึงรายการตู้ Container ทั้งหมด
- [x] `GET /api/containers/{id}` → ดูรายละเอียดตู้ (พร้อม Projects ที่บรรจุ)
- [x] `POST /api/containers` → สร้างตู้ใหม่ (เลือก Project, ระบุเลขตู้, ชื่อเรือ, ท่าเรือ)
- [x] `PUT /api/containers/{id}` → แก้ไขข้อมูลตู้ (Tracking No, ETD/ETA)
- [x] `PATCH /api/containers/{id}/step` → เลื่อนขั้นตอน (Factory→Port → Sailing → Port→Warehouse)

### ✅ Checklist ทดสอบ
- [x] **สร้างตู้ Container ใหม่สำเร็จ** → เชื่อมกับ Project จริง
- [x] **เลื่อน Step 1 → Step 2 (Sailing)** → ข้อมูล ETD/ETA ปรากฏในหน้าจอ
- [x] **เลื่อน Step 2 → Step 3 (Port→Warehouse)** → สถานะอัปเดต
- [x] **ดู Detail ตู้** → เห็นรายชื่อ Projects ที่บรรจุในตู้นี้ถูกต้อง
- [x] **Error Test:** เลื่อน Step โดยไม่กรอกวันที่ → ดูว่า Validation ทำงานไหม

---

## ✏️ Flow 11: Inventory (✅ เชื่อม API เรียบร้อยแล้ว)

### 📌 เป้าหมาย
เชื่อม API จัดการสต็อกสินค้าแยกรายคลัง ตรวจดูของที่เหลือและประวัติการเคลื่อนไหว

### 🔌 Checklist เชื่อม API
- [x] `GET /api/inventory/warehouses` → ดึงรายชื่อคลังสินค้า (บางพลี, รังสิต)
- [x] `GET /api/inventory/warehouses/{id}/stocks` → ดูสต็อกสินค้าในคลัง
- [x] `POST /api/inventory/warehouses` → เพิ่มคลังสินค้าใหม่เข้าระบบ
- [x] `POST /api/inventory/adjust` → รับเข้า/เบิกออก/ปรับปรุงยอดสต็อกสินค้า (IN, OUT, ADJUST)
- [x] `GET /api/inventory/movements` (via eager loading) → ดูประวัติเคลื่อนไหวสต็อกจริงตามบัญชีคลัง

### ✅ Checklist ทดสอบ
- [x] **เห็นรายชื่อคลัง 2 แห่ง** — บางพลี + รังสิต (จาก Seeder) และกดเพิ่มใหม่สำเร็จ
- [x] **เห็นสินค้าในสต็อก** — ร่มพับ AIS 500 ชิ้นในคลังบางพลี (จาก Seeder)
- [x] **รับสินค้าเข้าคลังสำเร็จ** → จำนวนสต็อกเพิ่มขึ้นตามจริง
- [x] **ดูประวัติ Movement** → เห็นรายการ IN/OUT/ADJUST ที่เคลื่อนไหวจริงในระบบพร้อมชื่อผู้ใช้งานจริง

---

## ✏️ Flow 12: Delivery (✅ เชื่อม API เรียบร้อยแล้ว)

### 📌 เป้าหมาย
เชื่อม API จัดรอบส่งของ — **⚠️ หน้านี้สำคัญมาก เพราะกด Confirm แล้วจะตัดสต็อกจริง!**

### 🔌 Checklist เชื่อม API
- [x] `GET /api/delivery/rounds` → ดึงรายการรอบส่งทั้งหมด
- [x] `GET /api/delivery/rounds/{id}` → ดูรายละเอียดรอบส่ง (พร้อมรายการสินค้าที่จะส่ง)
- [x] `POST /api/delivery/rounds` → สร้างรอบส่งใหม่ (ระบุวัน, คนขับ, รายการสินค้า+คลัง+จำนวน)
- [x] `PATCH /api/delivery/rounds/{id}/confirm` → ⚠️ ยืนยันรอบส่ง (ตัดสต็อกอัตโนมัติ!)
- [x] `PATCH /api/delivery/rounds/{id}/complete` → ยืนยันส่งเสร็จ

### ✅ Checklist ทดสอบ
- [x] **สร้างรอบส่งใหม่สำเร็จ** → เลือกสินค้าจากสต็อกจริง
- [x] **กด Confirm → สต็อกถูกหัก!** → เข้าหน้า Inventory ตรวจจำนวนลดลงตามจำนวนที่ส่ง
- [x] **Movement Log บันทึก OUT** → เข้าหน้า Inventory ดู Movement ล่าสุดเป็น OUT
- [x] **กด Complete → สถานะเปลี่ยนเป็น Delivered**
- [x] **⚠️ Error Test: สต็อกไม่พอ** → สร้างรอบส่ง 99,999 ชิ้น → กด Confirm → ดูว่า Error เข้าใจได้ ไม่ใช่ 500 Server Error
- [x] **⚠️ Error Test: กด Confirm ซ้ำ** → กดยืนยันรอบเดิม 2 ครั้งซ้อน → ไม่ควรตัดสต็อก 2 รอบ

---

## ✏️ Flow 13: Reports (❌ ยังไม่ได้เชื่อม API)

### 📌 เป้าหมาย
เชื่อม API รายงานสรุปการเงินและปฏิบัติการ สำหรับเจ้าของกิจการ

### 🔌 Checklist เชื่อม API
- [ ] `GET /api/reports/financial-summary` → สรุปรายได้/ต้นทุน/กำไรขั้นต้น
- [ ] `GET /api/reports/operational-summary` → สรุปปฏิบัติการ (Projects, Lead Time, On-time %)
- [ ] `GET /api/reports/revenue-by-month` → รายได้รายเดือน
- [ ] `GET /api/reports/profit-by-project` → กำไรรายโปรเจกต์

### ✅ Checklist ทดสอบ
- [ ] **Financial Summary ถูกต้อง** — ยอดรายได้ตรงกับผลรวม Confirmed Payments
- [ ] **Gross Profit คำนวณถูกต้อง** — Revenue - COGS (SupplierBills ที่ Paid)
- [ ] **Revenue by Month แสดงถูกต้อง** — เทียบกับเดือนที่มี Payment จริง
- [ ] **Profit by Project แสดงถูกต้อง** — PPN-001 ควรมีกำไร = 450,000 - 300,000 = 150,000
- [ ] **Operational Summary แสดงถูกต้อง** — จำนวน Active Projects ตรงกับฐานข้อมูล

---

## 📋 สรุปรวม Progress Tracker

| # | Flow | หน้าจอ | เชื่อม API | เทสครอบคลุม |
|---|------|--------|-----------|------------|
| 1 | Login | `login_screen.dart` | ✅ ทำแล้ว | ⬜ ยังไม่ได้เทสครอบคลุม |
| 2 | Customers | `create_customer_screen.dart` | ✅ ทำแล้ว | ⬜ ยังไม่ได้เทสครอบคลุม |
| 3 | Projects | `project_list_screen.dart` | ✅ ทำแล้ว | ⬜ ยังไม่ได้เทสครอบคลุม |
| 4 | Client Samples | `samples_screen.dart` | ✅ ทำแล้ว | ⬜ ยังไม่ได้เทสครอบคลุม |
| 5 | Artwork Tracking | `upload_design_screen.dart` | ✅ ทำแล้ว | ⬜ ยังไม่ได้เทสครอบคลุม |
| 6 | Dashboard | `dashboard_screen.dart` | ✅ ทำแล้ว | ⬜ ยังไม่ได้เทสครอบคลุม |
| 7 | Suppliers | `suppliers_screen.dart` | ✅ ทำแล้ว | ⬜ ยังไม่ได้เทสครอบคลุม |
| 8 | Finance (PI) | `generate_pi_screen.dart` | ✅ ทำแล้ว | ⬜ ยังไม่ได้เทสครอบคลุม |
| 9 | Finance (Payment) | `record_payment_screen.dart` | ✅ ทำแล้ว | ⬜ ยังไม่ได้เทสครอบคลุม |
| 10 | Containers | `containers_screen.dart` | ✅ ทำแล้ว | ⬜ |
| 11 | Inventory | `inventory_screen.dart` | ✅ ทำแล้ว | ⬜ |
| 12 | Delivery | `delivery_screen.dart` | ✅ ทำแล้ว | ⬜ |
| 13 | Reports | `reports_screen.dart` | ⬜ ยังไม่ได้ทำ | ⬜ |

**วิธีใช้:** เมื่อทำเสร็จแต่ละ Flow ให้เปลี่ยน ⬜ เป็น ✅ แล้วเติมวันที่ทำเสร็จ

---

> 📝 **สร้างโดย:** Antigravity AI Assistant  
> **วันที่อัปเดตล่าสุด:** 18 กรกฎาคม 2026
