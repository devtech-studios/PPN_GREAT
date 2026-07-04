# PPN GREAT Backend — Master Context

> **⚠️ ไฟล์นี้ให้ AI อ่านทุกครั้งที่เปิด Chat ใหม่**  
> Copy ข้อความ "อ่าน @MASTER_PROMPT.md" ใส่ทุก Chat แรก

---

## Tech Stack
- **Backend:** Laravel 11 + PHP 8.3
- **Database:** MySQL (Hostatom Plesk)
- **Auth:** JWT (tymon/jwt-auth)
- **API:** REST → JSON Response
- **Hosting:** Hostatom (Plesk Panel)
- **Frontend:** Flutter Web (เรียก API ผ่าน HTTP)
- **File Storage:** เก็บบน Hosting (storage/app/public/)

---

## API Response Format (ใช้ทุก Endpoint เหมือนกันหมด!)

```json
// ✅ Success (Single item)
{
    "success": true,
    "data": { "id": 1, "name": "..." },
    "message": "สร้างสำเร็จ"
}

// ✅ Success (List + Pagination)
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

// ❌ Error
{
    "success": false,
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "กรุณากรอกชื่อลูกค้า",
        "details": { "name": ["กรุณากรอกชื่อ"] }
    }
}
```

---

## Naming Conventions

| ประเภท | รูปแบบ | ตัวอย่าง |
|--------|--------|---------|
| Table | snake_case พหูพจน์ | `customers`, `stock_items` |
| Model | PascalCase เอกพจน์ | `Customer`, `StockItem` |
| Controller | PascalCase+Controller | `CustomerController` |
| Foreign Key | {table_singular}_id | `customer_id`, `project_id` |
| Route | /api/{resource} | `/api/customers`, `/api/finance/documents` |
| Migration | create_{table}_table | `create_customers_table` |

---

## Database Tables (26 ตาราง)

```
users                    ← ผู้ใช้งาน (ตอนนี้ Super Admin เท่านั้น, เพิ่ม Role ทีหลัง)
customers                ← ลูกค้า
contact_persons          ← ผู้ติดต่อ (belongs to customer)
shipping_addresses       ← ที่อยู่จัดส่ง (belongs to customer)
projects                 ← โปรเจกต์ (belongs to customer)
product_items            ← สินค้าใน Project
product_variations       ← ตัวเลือกสินค้า (สี/ไซส์)
product_files            ← ไฟล์อ้างอิง
additional_requests      ← คำขอพิเศษ
suppliers                ← ซัพพลายเออร์ (โรงงานจีน)
quote_requests           ← ใบขอราคา
supplier_samples         ← ตัวอย่างจาก Supplier
supplier_bills           ← AP (จ่ายเงินโรงงาน)
client_samples           ← ตัวอย่างส่งลูกค้า
artwork_logs             ← ประวัติ Artwork
finance_documents        ← เอกสารการเงิน (QU/PI/DP) ⚠️ CI รอลูกค้ายืนยัน
finance_doc_items        ← รายการในเอกสาร
payments                 ← รับเงินจากลูกค้า (AR)
containers               ← ตู้ Container
container_projects       ← Pivot: Container ↔ Projects
warehouses               ← คลังสินค้า
stock_items              ← สต็อกสินค้า
stock_movements          ← ประวัติเคลื่อนไหวสต็อก
dispatch_rounds          ← รอบจัดส่ง
delivery_items           ← รายการส่งสินค้า
activity_logs            ← บันทึกกิจกรรม
```

---

## สถานะ ENUM ที่สำคัญ

```
User Roles:       super_admin (ตอนนี้แค่นี้ก่อน — ออกแบบ DB ให้เพิ่ม Role ได้ง่ายทีหลัง)
                  ⚠️ ลูกค้าจะส่ง Role อื่นมาเพิ่มภายหลัง
Project Status:   Inquiry → Sample → Production → Shipping → Distributing → Delivered | Cancelled
Finance Doc Type: QU (ใบเสนอราคา), PI (แจ้งหนี้), DP (มัดจำ)
                  ⚠️ CI (Commercial Invoice) รอลูกค้ายืนยัน Format — ข้ามไปก่อน
Finance Status:   Draft → Sent → Paid → Overdue | Cancelled
Quote Status:     Waiting Link → Link Sent → Price Filled → Approved
Client Sample:    Waiting from China → Received from China → Sent to Client → Delivered to Client → Approved | Rejected
Artwork Status:   Awaiting Approval → Reviewing → Need Revision → Rejected → Approved by Client → Approved by Supplier
Container Status: Factory to Port → Sailing → Port to Warehouse → Delivered
Payment Status:   Pending Verification → Confirmed
Dispatch Status:  Scheduled → In Transit → Delivered
Stock Movement:   IN, OUT, ADJUST
Currency (Supplier): USD (ฝั่ง Supplier ใช้ USD)
Currency (Client):   THB (ฝั่งลูกค้าใช้ THB อย่างเดียว ไม่ต้องมี Currency field)
```

---

## Auto-generate Number Rules

```
Project Code:   PPN-001, PPN-002, PPN-003...     (ไม่รีเซ็ตรายปี, 3 หลัก)
Finance Doc:    QU-2026-0001, PI-2026-0002...     (รีเซ็ตรายปี, 4 หลัก)
Sample Code:    CS-001, CS-002...                  (ไม่รีเซ็ต, 3 หลัก)
Artwork Code:   ART-001, ART-002...                (ไม่รีเซ็ต, 3 หลัก)
Dispatch Code:  DSP-001, DSP-002...                (ไม่รีเซ็ต, 3 หลัก)
Container Code: CTN-001, CTN-002...                (ไม่รีเซ็ต, 3 หลัก)
```

---

## จุดสำคัญที่ต้องจำ

1. **ตัดสต็อก (Delivery Confirm):** ต้องใช้ `DB::transaction()` + `lockForUpdate()` เสมอ
2. **Due Date:** คำนวณจาก `issue_date + credit_term` (30 Days → +30 วัน)
3. **Activity Log:** บันทึกทุกการเปลี่ยนแปลงสำคัญ (สร้าง/แก้/เปลี่ยนสถานะ)
4. **CORS:** ตั้งค่าใน `config/cors.php` ให้ Flutter Web เรียก API ได้
5. **File Upload:** เก็บใน `storage/app/public/{type}/{project_id}/` + Symbolic Link
6. **Pagination:** ทุก List API ต้อง Paginate (default `per_page=20`)
7. **Search:** ทุก List API ต้องรองรับ `?search=` parameter
8. **Role:** ตอนนี้ทำแค่ Super Admin → ไม่ต้องเช็คสิทธิ์แยก Role (ทำทุกอย่างได้หมด) → เพิ่ม Role + Middleware ทีหลัง
9. **Currency:** ฝั่ง Supplier = USD / ฝั่งลูกค้า = THB เท่านั้น (ไม่ต้องมี currency field ในเอกสารฝั่งลูกค้า)
10. **Invoice (CI):** ⚠️ ข้ามไปก่อน — รอลูกค้ายืนยัน Format

---

## API Endpoints ทั้งหมด (76 อัน — ข้าม CI + ลด Role middleware)

### Auth (3)
```
POST   /api/auth/login
POST   /api/auth/logout
GET    /api/auth/me
```

### Dashboard (3)
```
GET    /api/dashboard/summary
GET    /api/dashboard/activities
GET    /api/dashboard/revenue-chart
```

### Customers (9)
```
GET    /api/customers
GET    /api/customers/{id}
POST   /api/customers
PUT    /api/customers/{id}
POST   /api/customers/{id}/contacts
PUT    /api/customers/{id}/contacts/{cid}
DELETE /api/customers/{id}/contacts/{cid}
POST   /api/customers/{id}/addresses
GET    /api/customers/{id}/stats
```

### Projects (9)
```
GET    /api/projects
GET    /api/projects/{id}
POST   /api/projects
PUT    /api/projects/{id}
PATCH  /api/projects/{id}/status
POST   /api/projects/{id}/products
PUT    /api/projects/{id}/products/{pid}
POST   /api/projects/{id}/additional-requests
GET    /api/projects/{id}/logs
```

### Suppliers (4)
```
GET    /api/suppliers
GET    /api/suppliers/{id}
POST   /api/suppliers
PUT    /api/suppliers/{id}
```

### Quote Requests (5)
```
GET    /api/suppliers/{id}/quotes
POST   /api/suppliers/{id}/quotes
PUT    /api/suppliers/{id}/quotes/{qid}
PATCH  /api/suppliers/{id}/quotes/{qid}/status
POST   /api/suppliers/{id}/quotes/{qid}/generate-link
```

### Supplier Samples (4)
```
GET    /api/suppliers/{id}/samples
POST   /api/suppliers/{id}/samples
PUT    /api/suppliers/{id}/samples/{sid}
PATCH  /api/suppliers/{id}/samples/{sid}/status
```

### Supplier Bills (4)
```
GET    /api/suppliers/{id}/bills
POST   /api/suppliers/{id}/bills
PATCH  /api/suppliers/{id}/bills/{bid}/pay
POST   /api/suppliers/{id}/bills/{bid}/upload
```

### Client Samples (5)
```
GET    /api/samples
GET    /api/samples/project/{pid}
POST   /api/samples
PUT    /api/samples/{id}
PATCH  /api/samples/{id}/status
```

### Artwork (6)
```
GET    /api/artworks
GET    /api/artworks/project/{pid}
POST   /api/artworks
PUT    /api/artworks/{id}
PATCH  /api/artworks/{id}/status
PATCH  /api/artworks/{id}/feedback
```

### Finance Documents (5) ⚠️ CI ข้ามไปก่อน — รอลูกค้ายืนยัน
```
GET    /api/finance/documents
GET    /api/finance/documents/{id}
POST   /api/finance/documents              ← doc_type: QU/PI/DP เท่านั้น (ไม่มี CI)
PUT    /api/finance/documents/{id}
PATCH  /api/finance/documents/{id}/status
```

### Payments (4)
```
GET    /api/finance/payments
POST   /api/finance/payments
PATCH  /api/finance/payments/{id}/verify
POST   /api/finance/payments/{id}/upload-slip
```

### Containers (5)
```
GET    /api/containers
GET    /api/containers/{id}
POST   /api/containers
PUT    /api/containers/{id}
PATCH  /api/containers/{id}/step
```

### Inventory (5)
```
GET    /api/inventory/warehouses
GET    /api/inventory/warehouses/{id}/stocks
POST   /api/inventory/receive
GET    /api/inventory/movements
GET    /api/inventory/low-stock
```

### Delivery (5)
```
GET    /api/delivery/rounds
GET    /api/delivery/rounds/{id}
POST   /api/delivery/rounds
PATCH  /api/delivery/rounds/{id}/confirm    ← ⚠️ ตัดสต็อก (Transaction!)
PATCH  /api/delivery/rounds/{id}/complete
```

### Reports (4)
```
GET    /api/reports/financial-summary
GET    /api/reports/operational-summary
GET    /api/reports/revenue-by-month
GET    /api/reports/profit-by-project
```
