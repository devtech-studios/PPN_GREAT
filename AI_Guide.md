# 🤖 คู่มือใช้ AI เขียน Backend PPN GREAT ให้ครบ

> **ปัญหาหลัก:** กลัว Context Overflow (AI ลืมคำสั่งก่อนหน้า ทำงานผิดพลาด)  
> **เอกสารนี้:** แก้ปัญหานี้ + วางแผนใช้ AI ให้มีประสิทธิภาพสูงสุด

---

## 📌 สารบัญ

1. [ปัญหา Context Overflow คืออะไร?](#1-ปัญหา-context-overflow-คืออะไร)
2. [วิธีแก้: Master Prompt + ไฟล์อ้างอิง](#2-วิธีแก้-master-prompt--ไฟล์อ้างอิง)
3. [แผนใช้ AI ทำงานรายวัน](#3-แผนใช้-ai-ทำงานรายวัน)
4. [เครื่องมือ AI ที่แนะนำ](#4-เครื่องมือ-ai-ที่แนะนำ)
5. [เทคนิคสั่ง AI ให้ได้ผลดี](#5-เทคนิคสั่ง-ai-ให้ได้ผลดี)
6. [Checklist ก่อนสั่ง AI ทุกครั้ง](#6-checklist-ก่อนสั่ง-ai-ทุกครั้ง)

---

## 1. ปัญหา Context Overflow คืออะไร?

### อธิบายง่ายๆ:

```
AI มี "ความจำ" จำกัด เหมือนกระดาษ A4 แผ่นเดียว

ถ้าคุณสั่ง AI ทำงาน 100 อย่าง → ข้อมูลมันล้นกระดาษ → มันลืมอย่างแรกๆ

ตัวอย่าง:
┌────────────────────────────────────────────────────┐
│  ตอนเริ่ม Chat:                                     │
│  "สร้าง users table ให้ฉัน"       ← AI จำได้ ✅      │
│  "สร้าง customers table"         ← AI จำได้ ✅      │
│  "สร้าง projects table"          ← AI จำได้ ✅      │
│  ... (คุยไปเรื่อยๆ 50 ข้อความ) ...                  │
│  "สร้าง delivery_items table"    ← AI จำได้ ✅      │
│  ...                                              │
│  ⚠️ ตรงนี้ AI ลืม users table ไปแล้ว!              │
│  พอถาม "users table มี field อะไร?" → AI ตอบผิด ❌  │
└────────────────────────────────────────────────────┘
```

### ผลเสียจริง:

| ปัญหา | ตัวอย่าง |
|--------|---------|
| **ตั้งชื่อไม่ตรงกัน** | ตอนแรกตั้ง `customer_id` แต่ทีหลัง AI เขียน `client_id` |
| **Schema ไม่ตรง** | ตอนแรกตกลง `status ENUM('Active','Inactive')` แต่ทีหลัง AI ใส่ `status VARCHAR` |
| **ลืม Relation** | ลืมว่า Project ต้อง FK ไป Customer → ไม่ใส่ FK |
| **Logic ขัดกัน** | ตอนแรกตกลง "ตัดสต็อกตอน Confirm" แต่ทีหลัง AI ตัดตอน "Create Round" |
| **Response Format ไม่ตรง** | บาง API ส่ง `{ success: true }` บางอัน ส่ง `{ status: "ok" }` |

---

## 2. วิธีแก้: Master Prompt + ไฟล์อ้างอิง

### 💡 หลักการสำคัญ: "อย่าพึ่งความจำ AI → พึ่งไฟล์!"

```
แทนที่จะหวังว่า AI จะจำทุกอย่าง:
→ เขียนทุกอย่างเป็นไฟล์ .md
→ ทุกครั้งที่เริ่ม Chat ใหม่ → ให้ AI อ่านไฟล์ก่อน
→ AI จะมี Context เดิมเสมอ ไม่ว่า Chat ใหม่กี่ครั้ง
```

### สร้างไฟล์ Master Prompt

สร้างไฟล์ชื่อ **`MASTER_PROMPT.md`** เก็บไว้ในโปรเจกต์:

```markdown
# PPN GREAT Backend — Master Context

## Tech Stack
- Laravel 11 + PHP 8.3
- MySQL (Hostatom Plesk)
- JWT Auth (tymon/jwt-auth)
- REST API → JSON Response

## API Response Format (ใช้ทุก Endpoint)
```json
// Success
{ "success": true, "data": {...}, "message": "..." }

// Error
{ "success": false, "error": { "code": "...", "message": "..." } }

// List + Pagination
{ "success": true, "data": [...], "meta": { "current_page": 1, "last_page": 5, "per_page": 20, "total": 100 } }
```

## Database Tables (26 ตาราง)
(ดูรายละเอียดใน Backend_Map.md)

## Naming Conventions
- Table: snake_case พหูพจน์ (customers, projects, stock_items)
- Model: PascalCase เอกพจน์ (Customer, Project, StockItem)
- Controller: PascalCase + Controller (CustomerController)
- FK: {table_singular}_id (customer_id, project_id)
- Route: /api/{resource} (kebab-case ถ้าหลายคำ เช่น /api/finance-documents)

## สถานะที่สำคัญ
- Project Status: Inquiry → Sample → Production → Shipping → Distributing → Delivered → Cancelled
- Finance Doc Type: QU (ใบเสนอราคา), PI (แจ้งหนี้), DP (มัดจำ), CI (กำกับสินค้า)
- Finance Doc Status: Draft → Sent → Paid → Overdue → Cancelled
- Quote Status: Waiting Link → Link Sent → Price Filled → Approved
- Sample Status: Waiting from China → Received → Sent to Client → Delivered → Approved / Rejected

## Auto-generate Numbers
- Project Code: PPN-001, PPN-002 (ไม่รีเซ็ตรายปี)
- Finance Doc: QU-2026-0001 (รีเซ็ตรายปี)
- Sample Code: CS-001
- Artwork Code: ART-001
- Dispatch Code: DSP-001
- Container Code: CTN-001

## จุดสำคัญ
- ตัดสต็อก: ต้องใช้ DB::transaction() + lockForUpdate()
- Due Date: คำนวณจาก issue_date + credit_term
- Activity Log: บันทึกทุกการเปลี่ยนแปลงสำคัญ
```

---

### วิธีใช้ Master Prompt:

```
ทุกครั้งที่เริ่ม Chat ใหม่กับ AI ให้ทำแบบนี้:

1. เปิด Chat ใหม่
2. ส่งข้อความแรก:

   "อ่านไฟล์เหล่านี้ก่อน แล้วเริ่มทำงาน:
    @MASTER_PROMPT.md
    @Backend_Map.md
    @8_Day_Plan_V2_Detailed.md
    
    วันนี้เป็นวันที่ 3 ของแผน (Suppliers)
    ทำตาม Checklist วันที่ 3 ต่อจากข้อ 3.2 Quote Requests"

3. AI จะอ่านไฟล์ทั้งหมด → มี Context ครบ → ทำงานถูกต้อง!
```

---

## 3. แผนใช้ AI ทำงานรายวัน

### กลยุทธ์หลัก: "1 Chat = 1 โมดูล"

```
❌ อย่าทำ: ใช้ Chat เดียวทำทุกอย่าง 8 วัน → Context ล้นแน่นอน!

✅ ให้ทำ: แยก Chat ตามโมดูล

Chat 1: Setup + Auth                    (วันที่ 1 เช้า)
Chat 2: Migration 26 ตาราง              (วันที่ 1 บ่าย)
Chat 3: Customer Module                 (วันที่ 2 เช้า)
Chat 4: Project Module                  (วันที่ 2 บ่าย)
Chat 5: Supplier + Quotes               (วันที่ 3 เช้า)
Chat 6: Supplier Samples + Bills         (วันที่ 3 บ่าย)
Chat 7: Finance Documents               (วันที่ 4 เช้า)
Chat 8: Payments                         (วันที่ 4 บ่าย)
Chat 9: Client Samples                  (วันที่ 5 เช้า)
Chat 10: Artwork                         (วันที่ 5 บ่าย)
Chat 11: Containers                      (วันที่ 6 เช้า)
Chat 12: Inventory                       (วันที่ 6 บ่าย)
Chat 13: Delivery + ตัดสต็อก             (วันที่ 6 ค่ำ)
Chat 14: Dashboard + Reports             (วันที่ 7)
Chat 15: Testing + Deploy                (วันที่ 8)
```

### ทุก Chat เริ่มด้วย:

```
"อ่านไฟล์เหล่านี้ก่อน:
@MASTER_PROMPT.md
@Backend_Map.md

วันนี้ทำโมดูล: [ชื่อโมดูล]
ต้องสร้าง:
1. Model: [ชื่อ]
2. Controller: [ชื่อ]
3. Migration: [ชื่อตาราง]
4. Routes: [list]
5. Endpoints: [list ตาม Checklist]

ทำทีละ Endpoint ให้ฉัน Review ก่อนไปอันถัดไป"
```

---

## 4. เครื่องมือ AI ที่แนะนำ

### 🥇 ตัวที่ 1: Gemini CLI / Antigravity (ตัวนี้ที่คุณใช้อยู่)

```
ข้อดี:
✅ อ่านไฟล์ในโปรเจกต์ได้ (@file mention)
✅ แก้ไขไฟล์ได้โดยตรง (ไม่ต้อง copy-paste)
✅ รัน Terminal ได้ (php artisan make:model, migrate ฯลฯ)
✅ มี MCP (Supabase, Tools) ถ้าจะใช้
✅ Context ยาว (อ่านไฟล์ได้เยอะ)

ข้อจำกัด:
⚠️ ถ้า Chat ยาวมากๆ ก็ยังมี Context Limit

วิธีใช้ให้ดีที่สุด:
→ ใช้ @file mention ให้ AI อ่าน MASTER_PROMPT.md ทุกครั้ง
→ ใช้ /goal command สำหรับงานที่ต้องทำยาวๆ ไม่หยุด
→ แยก Chat ตามโมดูล (ตามแผนด้านบน)
```

**ตัวอย่างสั่งงาน:**

```
@MASTER_PROMPT.md @Backend_Map.md

สร้าง CustomerController ให้ฉัน ครบ 9 endpoints ตาม Backend_Map.md
Section 4.3 Customers

ทำทีละ endpoint:
1. เริ่มจาก GET /api/customers (List + Search + Paginate)
2. แล้วค่อยทำ GET /api/customers/{id}
3. แล้ว POST /api/customers
...

ใช้ Response Format ตาม MASTER_PROMPT.md
ทุก endpoint ต้องมี Validation
```

### 🥈 ตัวที่ 2: Cursor / Windsurf (AI Code Editor)

```
ข้อดี:
✅ เขียนโค้ดเก่งมาก (เห็นทั้ง Codebase)
✅ Auto-complete แม่นยำ
✅ มี .cursorrules (เหมือน Master Prompt)

วิธีใช้ร่วมกัน:
→ ใช้ Gemini/Antigravity วางแผน + สร้างไฟล์หลัก
→ ใช้ Cursor เขียนโค้ดจริง + Debug

ถ้าจะใช้ Cursor สร้างไฟล์ .cursorrules:
→ Copy เนื้อหาจาก MASTER_PROMPT.md ไปวางใน .cursorrules
→ Cursor จะอ่านไฟล์นี้ทุกครั้ง (ไม่ลืม!)
```

### 🥉 ตัวที่ 3: Claude / ChatGPT (Web Chat)

```
ข้อดี:
✅ Projects Feature (Claude) — อัปโหลดไฟล์อ้างอิงไว้ถาวร
✅ Custom Instructions (ChatGPT) — ตั้ง System Prompt ถาวร

วิธีใช้:
→ ใช้เป็น "ที่ปรึกษา" ถาม Logic ซับซ้อน
→ เช่น "ช่วยเขียน SQL Query คำนวณ Profit by Project ให้หน่อย"
→ ไม่เหมาะเขียนโค้ดยาวๆ (ต้อง copy-paste)
```

---

## 5. เทคนิคสั่ง AI ให้ได้ผลดี

### 🔑 เทคนิค #1: "ให้ Context ก่อนสั่ง" (สำคัญที่สุด!)

```
❌ คำสั่งแย่:
"สร้าง API สร้างลูกค้าให้หน่อย"

✅ คำสั่งดี:
"อ่าน @MASTER_PROMPT.md ก่อน
สร้าง POST /api/customers ตามนี้:
- รับ Body: { name, type, tax_id, ... }
- Validation: name required, type ต้องเป็น Enterprise/Mid-Market/SME
- ใช้ DB::transaction() เพราะสร้าง contacts + addresses พร้อมกัน
- Response ตาม format ใน MASTER_PROMPT
- บันทึก Activity Log"
```

### 🔑 เทคนิค #2: "ทำทีละอัน ไม่ทำพร้อมกันหมด"

```
❌ แย่: "สร้าง 9 endpoints ของ Customer ทั้งหมดเลย"
→ AI จะเขียนยาวมาก → ผิดพลาดเยอะ → Context เต็มเร็ว

✅ ดี: "สร้าง GET /api/customers ก่อน แค่อันเดียว"
→ Review → ถูกต้อง → "ต่อไป POST /api/customers"
→ Review → แก้ไข → "OK ต่อไป PUT"
```

### 🔑 เทคนิค #3: "ให้ AI สร้างไฟล์จริง ไม่ใช่แค่แสดงโค้ด"

```
❌ แย่: "แสดงโค้ด CustomerController ให้ดู"
→ ต้อง copy-paste เอง → อาจ copy ผิด

✅ ดี: "สร้างไฟล์ app/Http/Controllers/CustomerController.php ให้ฉัน"
→ AI สร้างไฟล์จริง → ไม่ต้อง copy
→ (Antigravity/Gemini ทำได้!)
```

### 🔑 เทคนิค #4: "ให้ AI รัน Test ทันที"

```
❌ แย่: "สร้าง endpoint แล้วบอกฉัน"
→ ไม่รู้ว่าทำงานจริงไหม

✅ ดี: "สร้าง endpoint แล้วรัน php artisan route:list ให้ดูว่า route ขึ้นไหม"
→ รู้ทันทีว่าทำงาน
```

### 🔑 เทคนิค #5: "ให้ AI อัปเดตไฟล์ติดตามความคืบหน้า"

```
หลังจากทำแต่ละ Endpoint เสร็จ:
"อัปเดตไฟล์ PROGRESS.md ว่า Endpoint นี้เสร็จแล้ว"

ไฟล์ PROGRESS.md จะเป็นตัวบอกว่าทำถึงไหนแล้ว
→ เปิด Chat ใหม่ → ให้ AI อ่าน PROGRESS.md → AI รู้ว่าต้องทำต่อจากไหน
```

---

## 6. Checklist ก่อนสั่ง AI ทุกครั้ง

### เมื่อเปิด Chat ใหม่:

```
□ 1. ให้ AI อ่าน MASTER_PROMPT.md
□ 2. ให้ AI อ่าน Backend_Map.md (ถ้าต้องรู้ Schema / Endpoints)
□ 3. ให้ AI อ่าน PROGRESS.md (ถ้ามี — เพื่อรู้ว่าทำถึงไหน)
□ 4. บอก AI ว่าวันนี้ทำโมดูลอะไร
□ 5. บอก AI ว่าต้องสร้างไฟล์อะไรบ้าง
□ 6. สั่งทำทีละ Endpoint
```

### เมื่อ AI สร้างโค้ดเสร็จ:

```
□ 1. อ่านโค้ดคร่าวๆ — ตรงกับ Spec ไหม?
□ 2. เช็ค Naming Convention — ตรงกับ MASTER_PROMPT ไหม?
□ 3. เช็ค Response Format — ใช้ format เดียวกันทุก API ไหม?
□ 4. เช็ค FK / Relation — ตรงกับ Schema ใน Backend_Map ไหม?
□ 5. ให้ AI รัน php artisan route:list เช็คว่า Route ขึ้น
□ 6. ทดสอบ API ผ่าน Postman / Thunder Client
□ 7. อัปเดต PROGRESS.md
```

---

## 7. Template คำสั่งสำเร็จรูป (Copy ไปใช้ได้เลย)

### Template: เริ่ม Chat ใหม่

```
อ่านไฟล์เหล่านี้เพื่อทำความเข้าใจโปรเจกต์ก่อน:
@MASTER_PROMPT.md
@Backend_Map.md
@PROGRESS.md

=== งานวันนี้ ===
โมดูล: [ชื่อโมดูล เช่น Customers]
ไฟล์ที่ต้องสร้าง:
1. Model: app/Models/Customer.php
2. Controller: app/Http/Controllers/CustomerController.php
3. Form Request: app/Http/Requests/StoreCustomerRequest.php
4. Routes: เพิ่มใน routes/api.php

Endpoints ที่ต้องทำ:
1. GET /api/customers (List + Search + Paginate)
2. GET /api/customers/{id} (Detail + Relations)
3. POST /api/customers (Create + Contacts + Addresses)
4. PUT /api/customers/{id} (Update)

เริ่มจาก Endpoint #1 ก่อน สร้างไฟล์จริงให้ฉัน
```

### Template: สั่งสร้าง Endpoint

```
สร้าง [METHOD] /api/[path] ให้ฉัน

รายละเอียด:
- รับ: [Body / Query params]
- Validation: [กฎ]
- Logic: [ต้องทำอะไร step-by-step]
- Response: ใช้ format ตาม MASTER_PROMPT.md
- Activity Log: [ต้องบันทึกไหม / บันทึกว่าอะไร]
- ⚠️ จุดระวัง: [ถ้ามี เช่น ต้องใช้ Transaction]

สร้างเป็นไฟล์จริง แล้วรัน php artisan route:list ให้ดูด้วย
```

### Template: ตรวจสอบงานเก่า

```
อ่าน @PROGRESS.md แล้วบอกฉันว่า:
1. ทำเสร็จไปกี่ Endpoint แล้ว
2. เหลืออีกกี่ Endpoint
3. มีอะไรที่ยังไม่ได้ทดสอบ
4. งานถัดไปที่ต้องทำคืออะไร
```

---

## 8. ไฟล์ที่ต้องมีในโปรเจกต์ (สำหรับ AI อ้างอิง)

```
ppn-api/
├── MASTER_PROMPT.md      ← ⭐ ไฟล์สำคัญที่สุด! AI อ่านทุกครั้ง
│                            (Tech Stack, Naming, Response Format, Schema สรุป)
│
├── Backend_Map.md         ← Schema ละเอียดทุกตาราง + API Endpoints ทั้งหมด
│                            (ให้ AI อ่านเมื่อต้องรู้ Schema)
│
├── 8_Day_Plan_V2_Detailed.md ← Checklist รายวัน
│                            (ให้ AI อ่านเมื่อต้องรู้ว่าทำอะไรวันนี้)
│
├── PROGRESS.md            ← ⭐ ไฟล์ติดตามความคืบหน้า (AI อัปเดตทุกครั้ง)
│                            (ให้ AI อ่านเมื่อเปิด Chat ใหม่)
│
├── .cursorrules           ← ถ้าใช้ Cursor (copy จาก MASTER_PROMPT.md)
│
└── (ไฟล์โค้ด Laravel ทั้งหมด)
```

---

## 9. ตัวอย่างไฟล์ PROGRESS.md

```markdown
# 📊 PPN GREAT Backend — Progress Tracking

## สถานะรวม: 21/81 Endpoints (26%)

### ✅ วันที่ 1 (4 ก.ค.) — DONE
- [x] Laravel Project Setup
- [x] JWT Auth ติดตั้ง
- [x] Migration 26 ตาราง
- [x] POST /api/auth/login ✅
- [x] POST /api/auth/logout ✅
- [x] GET /api/auth/me ✅

### ✅ วันที่ 2 (5 ก.ค.) — DONE
- [x] GET /api/customers ✅
- [x] GET /api/customers/{id} ✅
- [x] POST /api/customers ✅
- [x] PUT /api/customers/{id} ✅
- [x] POST /api/customers/{id}/contacts ✅
- [x] PUT /api/customers/{id}/contacts/{cid} ✅
- [x] DELETE /api/customers/{id}/contacts/{cid} ✅
- [x] POST /api/customers/{id}/addresses ✅
- [x] GET /api/customers/{id}/stats ✅
- [x] GET /api/projects ✅
- [x] GET /api/projects/{id} ✅
- [x] POST /api/projects ✅
- [x] PUT /api/projects/{id} ✅
- [x] PATCH /api/projects/{id}/status ✅
- [x] POST /api/projects/{id}/products ✅
- [x] PUT /api/projects/{id}/products/{pid} ✅
- [x] POST /api/projects/{id}/additional-requests ✅
- [x] GET /api/projects/{id}/logs ✅

### 🔄 วันที่ 3 (6 ก.ค.) — IN PROGRESS
- [x] GET /api/suppliers ✅
- [x] GET /api/suppliers/{id} ✅
- [ ] POST /api/suppliers          ← ทำถึงตรงนี้!
- [ ] PUT /api/suppliers/{id}
- [ ] GET /api/suppliers/{id}/quotes
- [ ] POST /api/suppliers/{id}/quotes
- [ ] ...

### ⬜ วันที่ 4-8 — NOT STARTED
```

---

## 10. สรุป — กฎ 5 ข้อ ป้องกัน Context Overflow

```
กฎ #1: สร้าง MASTER_PROMPT.md → AI อ่านทุกครั้งที่เปิด Chat ใหม่
กฎ #2: แยก Chat ตามโมดูล → อย่าใช้ Chat เดียวทำทุกอย่าง
กฎ #3: ให้ AI อัปเดต PROGRESS.md → เปิด Chat ใหม่แล้วรู้ว่าทำถึงไหน
กฎ #4: ทำทีละ Endpoint → Review → ต่อ → ไม่ทำพร้อมกันหมด
กฎ #5: ตรวจ Naming + Format ทุกครั้ง → อ้างอิงจาก MASTER_PROMPT เสมอ
```

```
ถ้าทำตาม 5 กฎนี้:
✅ AI จะไม่ลืม Context
✅ โค้ดจะ Consistent ทั้งโปรเจกต์
✅ เปิด Chat ใหม่ 100 ครั้ง ก็ไม่มีปัญหา
✅ คนอื่นมาอ่านโค้ดก็เข้าใจ
```

---

> 📝 **สร้างโดย:** Antigravity AI Assistant  
> **วันที่:** 3 กรกฎาคม 2026
