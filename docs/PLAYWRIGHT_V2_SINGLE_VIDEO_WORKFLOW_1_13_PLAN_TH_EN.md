# Playwright V2 Single-Video Workflow 1–13 Plan — แผนคลิปยาวทดสอบทั้งระบบ

สถานะ: Implementation in progress  
วันที่: 18 กรกฎาคม 2026  
ขอบเขต: Local Desktop 1440×1000, Flutter Admin + Supplier Portal + Laravel + MySQL `ppn_e2e`

## 1. เป้าหมาย

สร้าง Playwright test เพียง `หนึ่ง test()` เพื่อให้ได้ไฟล์วิดีโอ `.webm` ยาวไฟล์เดียว ตั้งแต่ฐานข้อมูลว่างจนจบวงจรธุรกิจ โดยครอบคลุม Workflow 1–13, Supplier Portal, expected errors, valid business variants และ logistics edge cases ที่เกิดขึ้นจริง

ข้อบังคับ:

- reset ได้เฉพาะ `ppn_e2e`
- หลัง reset เหลือ Administrator 1 identity และ Supplier 1 identity
- Customer, Project, Product, Artwork, Sample, Quote, Documents, Payments, Warehouse, Container, Stock และ Delivery ต้องเริ่มเป็นศูนย์
- prerequisite และ business mutation ทำผ่าน UI เท่านั้น
- API ใช้เป็น read-only oracle เพื่อตรวจ ID, relation, status, amount และ stock
- ห้ามแก้ product code เพื่อทำให้ผลผ่าน
- ถ้า stage ใดผิดพลาด ให้บันทึก finding, แสดง error card 6 วินาที และเดิน stage ถัดไปที่ยังทำได้
- ตอนจบรวม unexpected findings แล้วทำให้ test fail หลังจากวิดีโอและหลักฐานครบ ไม่หยุดกลางคลิป

## 2. One-Video Architecture

- file: `e2e/adversarial-v2/long.paired.spec.ts`
- 1 Playwright test = 1 browser context = 1 video
- `workers: 1`, `retries: 0`, `maxFailures: 0`
- timeout สำหรับ long journey: 2 ชั่วโมง
- `slowMo`: 1,000 ms/action
- normal card: 3 วินาที
- important/success card: 4 วินาที
- expected/unexpected error card: 6 วินาที
- final reconciliation card: 10 วินาที
- stage runner แยกผลเป็น `PASS`, `EXPECTED-REJECTION`, `POLICY-OBSERVATION`, `PRODUCT-MISMATCH`, `BLOCKED` และ `COVERAGE-GAP`

## 3. Baseline ที่ต้องเห็นในคลิป

| Entity | Expected |
|---|---:|
| users | 1 Admin |
| suppliers | 1 active Supplier |
| customers | 0 |
| projects/products | 0 |
| artworks/samples | 0 |
| quote requests | 0 |
| finance documents/payments | 0 |
| warehouses/stocks/movements | 0 |
| containers/delivery rounds | 0 |

## 4. Workflow 1–13 และ use cases ในคลิป

### Workflow 1 — Authentication / การเข้าสู่ระบบ

1. Submit ฟอร์มว่าง → ต้องเห็น validation และไม่มี login request
2. กรอก Admin + password ผิด → ต้องได้ 401 และยังอยู่หน้า Sign In
3. แก้เป็น credentials ถูกต้อง → Dashboard ต้องเปิดได้

### Workflow 2 — Customers / ลูกค้า

1. กดสร้างลูกค้าโดยไม่กรอกชื่อ → ต้องถูกปฏิเสธ
2. กรอก Company, Tax ID, Contact, Billing Address และ Same-as-Billing ผ่าน UI
3. บันทึกสำเร็จและค้นหาลูกค้าที่สร้างได้

### Workflow 3 — Projects / โครงการและสินค้า

1. กด Create Project โดยไม่เลือก Customer/Contact → ต้องเห็น validation
2. เลือกลูกค้าที่สร้างจาก Workflow 2
3. สร้าง Project + Product 1,000 ชิ้น พร้อม specification
4. ตรวจ Project/Product relation ด้วย read-only oracle

### Workflow 4 + 5 — Sample/Artwork Enforced Sequence

เลข workflow เดิมวาง Sample ก่อน Artwork แต่ business policy ล่าสุดกำหนด Artwork Approved ก่อน Sample Request จึงทดสอบดังนี้:

1. Negative probe: พยายาม Add Local Sample ก่อน Artwork Approved
2. Expected: UI/API ต้องบล็อกและ sample count ต้องไม่เพิ่ม
3. หาก sample ถูกสร้าง ให้บันทึก `PRODUCT-MISMATCH`; ไม่แก้ product
4. Artwork error: Save Log โดยไม่เลือกไฟล์ → ต้องถูกปฏิเสธ
5. อัปโหลด Artwork V1 → Reviewing → Need Revision พร้อม feedback
6. อัปโหลด Artwork V2 → Reviewing → Approved by Client
7. กลับ Sample หลัง Artwork Approved → สร้าง attempt ที่ถูกต้อง
8. Reject sample พร้อม feedback แล้วสร้าง attempt ถัดไป → Approved by Client

### Workflow 6 — Dashboard / ภาพรวม

1. เปิด Dashboard หลังมี Customer/Project/Artwork/Sample
2. ตรวจ KPI/Recent Activity ไม่ crash
3. ใช้ quick action/navigation ต่อไปยัง workflow ถัดไป

### Workflow 7 — Suppliers + Supplier Portal / โรงงานและขอราคา

1. เลือก Supplier baseline
2. สร้าง Quote Request สำหรับ Project/Product ผ่าน UI
3. Generate Supplier Session Link
4. Supplier login ด้วย session token จริง
5. Error: Submit Quote โดยไม่กรอกราคา/lead time → ต้องถูกปฏิเสธ
6. Recovery: กรอกราคา, lead time, MOQ, sample terms และ remarks → submit สำเร็จ
7. Admin กลับมาตรวจและ Approve Quote
8. สร้างและจ่าย Supplier Deposit Bill พร้อมอัปโหลด PI/Invoice

### Workflow 8 — Finance Documents / เอกสารลูกค้า

1. ออก PI ก่อน QU → ต้องสำเร็จในฐานะ `POLICY-OBSERVATION`
2. ออก QU ภายหลัง → ต้องสำเร็จ
3. หลังจัดส่ง แต่อยู่ก่อนชำระครบ ออก CI → ต้องสำเร็จในฐานะ `POLICY-OBSERVATION`

### Workflow 9 — Customer Payments / รับชำระหลายงวด

1. Error: จำนวนติดลบ → UI ต้องปฏิเสธและ payment count ไม่เพิ่ม
2. งวดที่ 1: 30,000 บาท → upload slip → confirm
3. งวดที่ 2: 20,000 บาท → upload slip → confirm
4. จัดส่งสินค้าในขณะที่ยัง outstanding 99,000 บาท → ต้องอนุญาตและเก็บยอดค้าง
5. ออก CI ก่อนรับครบ
6. งวดที่ 3 หลังส่งของ: 99,000 บาท → upload slip → confirm
7. รวม confirmed payments = 149,000 บาทพอดี

### Workflow 10 — Containers / ตู้และขนส่งระหว่างประเทศ

1. Error: สร้างตู้โดยไม่กรอก container number → ต้องปฏิเสธ
2. สร้าง container และเชื่อม Project
3. Error: พยายาม Set Sailing โดยไม่ใส่ Factory Departure → ต้องไม่ข้ามสถานะ
4. Recovery: ใส่วันที่และเดิน Factory to Port → Sailing → Port to Warehouse → Delivered
5. แสดงกรณี ETA/actual arrival ผ่าน timeline จริง

### Workflow 11 — Inventory / คลังและสต๊อก

1. สร้าง Warehouse ผ่าน UI
2. รับ 100 ชิ้นจาก Container เข้า Warehouse เพื่อเป็น buffer 10%
3. Error: รับ container/project/product เดิมซ้ำ → ต้องถูกปฏิเสธและ stock ไม่เพิ่ม
4. ตรวจ IN movement และ stock = 100

ข้อจำกัดจากไฟล์จริง: Container UI รองรับเฉพาะ inventory route หนึ่งเส้นทาง ไม่มี control สำหรับ direct + inventory split ใน dialog เดียว จึงบันทึก `COVERAGE-GAP` และใช้ Delivery UI แสดง 90/10 split จริงแทน

### Workflow 12 — Delivery / จัดส่งลูกค้า

1. Error: สร้าง warehouse delivery 101 ชิ้นขณะที่ stock มี 100 → ต้องปฏิเสธและไม่ reserve
2. Recovery/real logistics split ในรอบเดียว:
   - 900 ชิ้น = Direct Shipped ไม่ตัดคลัง PPN
   - 100 ชิ้น = Warehouse buffer ตัด stock
3. Confirm/Depart → warehouse stock 100 → 0 และมี OUT movement
4. ตรวจว่าปุ่ม Depart ซ้ำไม่เหลือให้กดหลัง In Transit
5. Complete → Delivered
6. ยืนยันว่าการส่งก่อนลูกค้าชำระครบทำได้ และ outstanding balance ยังอยู่

### Workflow 13 — Reports / รายงานและกระทบยอด

1. เปิด Reports หลังธุรกรรมครบ
2. สลับ Revenue, Profitability, Cash Flow, Tax, Delivery, Lead Time และ Customer Portfolio ตาม control ที่มีจริง
3. ตรวจ payment, supplier bills, QU/PI/CI, stock, IN/OUT movement และ Delivered round
4. เปิด Dashboard สรุปอีกครั้ง
5. แสดง Final Summary Card 10 วินาที พร้อม passed/expected/mismatch/blocked/gap

## 5. Business Policies ที่ใช้ตัดสินผล

| Policy | Expected |
|---|---|
| ส่งก่อนลูกค้าชำระครบ | Allowed, `POLICY-OBSERVATION`, ต้องเห็น outstanding balance/history |
| แบ่งชำระหลายงวด | `CONTRACT-CONFIRMED`, ต้องสำเร็จและยอดรวม reconcile |
| PI ไม่มี QU ก่อนหน้า | Allowed, `POLICY-OBSERVATION` |
| CI ก่อนรับเงินครบ | Allowed, `POLICY-OBSERVATION` |
| Sample Request ก่อน Artwork Approved | `EXPECTED-REJECTION`; หากสร้างได้เป็น `PRODUCT-MISMATCH` |

## 6. Evidence

วิดีโอเดียวต้องมี title card ก่อนแต่ละ workflow และ result card หลัง use case สำคัญ พร้อมแนบ:

- `long-journey-findings.json`
- `long-journey-summary.json`
- screenshot ตอน final report
- Playwright trace ทั้ง journey
- HTML report
- API/database read-only reconciliation

## 7. Run Command

```powershell
cd D:\07_Projects\Work\PNN\ppn_great
.\scripts\run-adversarial-v2-e2e-video.ps1 -ConfirmReset -Pack LONG
```

ข้าม build เมื่อ build ปัจจุบันตรงกับ source:

```powershell
.\scripts\run-adversarial-v2-e2e-video.ps1 -ConfirmReset -SkipBuild -Pack LONG
```

ผลที่ต้องได้: 1 Playwright test และ 1 video file ไม่ว่าภายในจะมี expected errors หรือ product mismatches กี่รายการ
