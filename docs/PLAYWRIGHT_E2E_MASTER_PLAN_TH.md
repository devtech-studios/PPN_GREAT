# PPN GREAT — Playwright E2E Master Plan

อัปเดตจากการตรวจ source จริงวันที่ 18 กรกฎาคม 2026

## 1. ขอบเขตและแหล่งข้อมูลที่ตรวจ

เอกสารนี้ไม่ได้อ้างอิง mockup เพียงอย่างเดียว แต่เทียบข้อมูลจาก 4 แหล่ง:

1. `14_Day_Plan_V2_Detailed.md` — business scope, 14-day delivery plan, 81-endpoint target และ full-flow expectation
2. `API_Integration_Plan.md` — flow 1–13 และ checklist เชื่อม frontend
3. Flutter Web ใน `lib/` — หน้าจอ, ปุ่ม, dialog, validation, navigation และ API call ที่มีจริง
4. Laravel ใน `ppn-api/routes/api.php` และ controllers — route/validation/status transition ที่มีจริง
5. Supplier Portal ใน `Supplier_ui_moocup/index/index.php` — HTML controls และ public supplier flow ที่เรียก API จริง

ผลตรวจ route ด้วย `php artisan route:list --path=api`: มี **95 routes** ไม่ใช่ 81 ตามแผนเดิม แบ่งเป็น Artworks 8, Auth 3, Containers 6, Customers 11, Dashboard 3, Delivery 5, Finance 11, Inventory 7, Projects 11, Public Quotes 2, Reports 4, Samples 5, Supplier Portal 2 และ Suppliers 17

## 2. สถานะระบบจริงและความต่างจากแผน

| โมดูล | Source จริง | API จริง | สถานะที่ควรใช้วางเทส |
|---|---|---|---|
| Login | `login_screen.dart` | login/me/logout | Implemented |
| Dashboard | `dashboard_screen.dart` | summary/activities/revenue-chart/projects | Implemented; schedule บางรายการยังเป็นข้อความคงที่ |
| Customers | `create_customer_screen.dart` | CRUD + contacts + addresses + stats | Implemented |
| Projects | list/detail/create ใน 2 screens | CRUD + products + status + logs + PO | Implemented |
| Client Samples | `samples_screen.dart` | list/create/update/status | Implemented; DB ปัจจุบันเริ่มต้นที่ 0 records |
| Artwork | `upload_design_screen.dart` | list/create/upload/update/status/feedback/file | Implemented; DB ปัจจุบันเริ่มต้นที่ 0 records |
| Suppliers | `suppliers_screen.dart` | supplier + quotes + samples + bills | Implemented |
| Supplier Portal | PHP page | portal login/submit quote | Implemented และเรียก backend จริง |
| Finance Docs | `generate_pi_screen.dart` | documents + supplier bills | Implemented แม้ section เก่าใน plan ยังเขียน ❌ |
| Payments | `record_payment_screen.dart` | list/create/verify/upload/file | Implemented แม้ section เก่าใน plan ยังเขียน ❌ |
| Containers | `containers_screen.dart` | CRUD + step + route goods | Implemented |
| Inventory | `inventory_screen.dart` | warehouses/stocks/receive/adjust/movement/low-stock | Implemented |
| Delivery | `delivery_screen.dart` | create/confirm/complete | Implemented; confirm เป็น destructive stock mutation |
| Reports | `reports_screen.dart` | 4 report APIs | Source เรียก API แล้ว แม้ progress tracker เก่ายังเขียน ❌ |
| Settings | placeholder ใน `main_layout.dart` | ไม่มี | Not implemented |
| Role/permission UI | เมนูมีข้อความ SUPER ADMIN/OWNER ONLY | API ใช้เพียง `auth:api` | Gap: ยังไม่มี role guard จริง |

ข้อสรุป: ใช้ source/routes เป็น source of truth ส่วน checkbox ใน `API_Integration_Plan.md` มีข้อมูลคนละช่วงเวลาและขัดกันเอง

## 3. Test architecture ที่จัดทำ

Playwright อยู่ที่ root ของ Flutter project เพื่อให้ build และ test ได้ด้วยคำสั่งเดียว:

```text
ppn_great/
├─ package.json
├─ playwright.config.ts
├─ e2e/
│  ├─ support/
│  │  ├─ env.ts
│  │  ├─ flutter.ts
│  │  └─ api.ts
│  ├─ auth.spec.ts
│  ├─ navigation.spec.ts
│  ├─ module-actions.spec.ts
│  ├─ supplier-portal.spec.ts
│  └─ semantics-audit.spec.ts
├─ test-results/
└─ playwright-report/
```

Playwright projects:

- `admin-chromium`: Flutter Web ที่ `http://127.0.0.1:4173`
- `supplier-chromium`: Supplier Portal ที่ `http://localhost:3000`
- API: Laravel ที่ `http://127.0.0.1:8000/api`

Config reuse server ที่รันอยู่แล้ว หรือเริ่ม Laravel, static Flutter build และ Supplier PHP server ให้เอง ค่า URL/credential override ผ่าน environment variables ได้

## 4. กติกา selector สำหรับ Flutter Web

Flutter ไม่ได้สร้าง DOM แบบ React/Vue ปกติ การใช้ `.class`, `input[type=password]` หรือ widget class จะไม่เสถียร ชุดนี้จึงใช้หลักต่อไปนี้:

1. รอ `flt-glass-pane`
2. activate `flt-semantics-placeholder` ด้วย DOM evaluation
3. ใช้ `getByRole()` และ accessible name เป็นหลัก
4. ใช้ `getByText(..., { exact: true })` เมื่อ control ไม่มี role ชัดเจน
5. ช่อง password ใช้ `pressSequentially()` เพราะ `fill()` เคยไม่ส่งค่ากลับเข้า Flutter state ใน build นี้
6. ปุ่ม icon ที่ไม่มี tooltip ใช้ตำแหน่งได้เฉพาะชั่วคราว และต้องเปิด test audit เพื่อผลักดันให้เพิ่ม `tooltip`/`Semantics(label:)`
7. ไม่ใช้ `waitForTimeout` เป็น assertion; ใช้เฉพาะรอ animation/API settle ของ Flutter และควรแทนด้วย response/state assertion เมื่อเพิ่ม testability แล้ว

รัน audit accessibility ของทุกหน้า:

```powershell
$env:E2E_SEMANTICS_AUDIT='1'
npx playwright test e2e/semantics-audit.spec.ts --project=admin-chromium --workers=1
```

## 5. Page/Button/Test inventory

### AUTH — Login

Controls: Email/Username, Password, show/hide password, Sign In

- `AUTH-001` ช่องว่างทั้งสองช่อง → local validation
- `AUTH-002` email ไม่ถูกต้อง → POST login ตอบ 401 และไม่ navigate
- `AUTH-003` login สำเร็จ → Dashboard
- `AUTH-004` Enter ที่ช่อง password → submit
- `AUTH-005` show/hide password → ค่าไม่หาย
- `AUTH-006` reload → token ยังอยู่และ Dashboard เปิดได้
- `AUTH-007` logout cancel → ยังอยู่ระบบ
- `AUTH-008` logout confirm → token/user ถูกลบและกลับ Login
- `AUTH-009` token หมดอายุ/ปลอม → interceptor ลบ token และ redirect Login

### DASH — Dashboard

Controls ที่ semantics ตรวจพบ: search, status filters 8 ปุ่ม, view toggle 2 ปุ่ม, project cards/arrows, calendar links, finance link และ quick actions 6 ปุ่ม

- `DASH-001` KPI ตรงกับ `dashboard/summary`
- `DASH-002` activities ตรงกับ `dashboard/activities`
- `DASH-003` revenue bars/เดือนตรงกับ `revenue-chart`
- `DASH-004` search แสดง/ซ่อน dropdown และเลือกผลลัพธ์
- `DASH-005..012` All Active/Inquiry/Artwork/Deposit/Sample/Production/Shipping/Delivered filter
- `DASH-013` card/table toggle
- `DASH-014..019` Create Project, Manage Samples, Upload Artwork, Generate PI, Book Container, Record Payment → หน้าถูกต้อง → Back
- `DASH-020` refresh หลัง login
- `DASH-021` API unavailable แสดง error state ไม่ใช่ white screen

### CUST — Customers

Controls: Back, collapse list, Create Customer, customer cards, Edit Customer Detail, Create New Project, Cancel, Save/Update, add/remove contacts, add/remove address, tier, lead-source chips, discard/save confirmations

- list/search/select/detail/stats
- create happy path ด้วยชื่อ/Tax ID ที่ unique
- required name, duplicate Tax ID, invalid email/phone
- add/edit/delete contact
- add/edit/delete shipping address
- SME/Mid-Market/Enterprise และ lead source ทุกค่า
- cancel → Cancel Creation → No / Yes Discard
- edit → Save/Cancel confirmation
- create project จาก customer ต้อง preselect customer ที่ถูกต้อง

### PROJ — Projects

Controls: search, collapse/expand, card/table, All Status dropdown, Target Date sort, project cards, Edit, Re-order, Create New Project, Request Sample, Add Note, pipeline/compliance, cancel project

- list/search/filter/sort/toggle/detail
- create project: customer, target date, product, qty options, custom product, requirement
- product add/remove confirm และ cancel form confirm
- edit project/product
- status pipeline ที่ถูกลำดับและ status ที่ผิดลำดับ
- compliance confirmation
- request sample dialog validation
- activity log/additional request
- cancel project; หลัง cancel ต้อง update ไม่ได้

### SAMP — Client Samples

Controls: Back, search/select project, Add Local Sample, product/type dropdowns, date/courier/tracking, status dropdown, China/local tracking edit, feedback edit

- seed project/product ผ่าน API ก่อน UI test
- create PPS/material swatch
- required project/product
- status flow Created → Sent to Supplier → Received → Sent to Client → Approved/Rejected
- reject → feedback → create next attempt
- edit China/local tracking และ null tracking regression

### ART — Artwork

Controls: Back, search/select project, Add Artwork Log, file picker, product/type/status dropdowns, Edit Note/feedback/status

- create V1, upload supported image/PDF/design file
- reject + feedback → upload V2 → approve
- version increments V1/V2/V3
- no project/file/empty feedback validation
- file preview URL ผ่าน `/api/artworks/file/{filename}`
- invalid extension/oversize/CORS error

### SUP — Suppliers และ Supplier Portal

Admin controls: Back, Add New Supplier, Edit Supplier, Quotes/Samples/AP tabs, Request Quote/Sample/Add Bill, session link, manual input, review/revise/approve, tracking, pay/upload

Portal controls: username, token, Login, Pending, History, Logout, Submit Quote, Revise/Resubmit, Cancel, Submit Revision

- supplier CRUD/search
- quote: create → generate link → portal login → fill mass/sample quote → submit → admin review
- admin Need Revision + buyer note → portal revision → admin Approve
- manual quote input path
- supplier sample create/tracking/received/status
- bill create, negative amount validation, upload, pay selected
- portal missing fields, invalid supplier, invalid token
- portal selects a real supplier email from API; ไม่พึ่ง mock username `guangzhou_bags`

### FIN — Finance Documents

Controls: project filter/search, Inbound/Outbound, Document/Expense Logs, QU/PI/DP/CI tabs, Preview A4, Save & Issue, Confirm Payment, Record Expense, file View/Change, Shipping Mark PDF

- list/detail and auto document number
- QU → PI → DP → CI flow
- totals, discount, VAT, withholding, credit term/due date
- Preview vs saved payload
- status Draft → Sent → Paid และ illegal transition
- PO upload/view/change
- outbound expense create and supplier-bill auto-fill
- logs drawer open/close

### PAY — Record Payment

เข้าจาก Dashboard quick action `Record Payment`

- project search/select
- amount/date/method/reference validation
- create payment
- upload/view/replace slip; non-image and oversize
- verify once; repeat verify must not duplicate totals
- receipt preview and reload

### CONT — Containers

Controls: Back, add icon, search/list, Tracking/Plan/Customs tabs, date fields, save general/customs, step transitions

- create dialog required container number and at least one project
- duplicate container number
- detail project relation
- update tracking/ETD/ETA
- Factory to Port → Sailing → Port to Warehouse → Delivered
- skip/repeat transition rejected
- Plan/Customs persist after reload

### INV — Inventory

Controls: Back, add warehouse, search/select, Manual Adjust, movement history, project/product/type/warehouse dropdowns

- warehouse create required name/address/province
- stock list and search
- IN/OUT/ADJUST with reason/location
- zero, negative, non-number, overdraw validation
- movement ledger records actor/reference/before/after
- low stock

### DEL — Delivery

Controls: Back, search/project cards, quick-fill values, Auto-fill remaining PO, product/warehouse dropdown, add/remove dispatch item, save round, Depart, Complete

- create scheduled round with one/multiple items
- required address/date/items
- direct delivery without warehouse vs warehouse stock deduction
- confirm once → status In Transit + movement OUT + stock decreases exactly once
- duplicate confirm must be idempotent/rejected
- insufficient stock returns readable error, not 500
- complete once → Delivered
- delivery summary/remaining quantity updates

### RPT — Reports

12 tabs: Revenue Forecast, Profitability, Cash Flow, Tax, Delivery, Lead Time, Inventory Aging, Supplier Rating, FOC, Customer Portfolio, Category Demand, Logistics Efficiency พร้อม Month/date filters

- click ทุก tab และตรวจไม่มี crash
- 4 API-backed datasets ตรงกับ API response
- derived totals: revenue, COGS, gross profit, active projects, on-time %, profit/project
- empty state, API error, large values, no divide-by-zero
- Owner-only access เป็น security test ที่ต้อง fail จนกว่าจะมี role guard

## 6. Critical end-to-end flows

### FLOW-P0-01: Order-to-Cash

Login → Create Customer → Create Project + Product → Client Sample approve → Artwork V1 reject/V2 approve → QU → PI → Deposit Payment + Slip + Verify → Container → Inventory Receive → Delivery Create → Confirm stock OUT → Complete → Reports reconcile

Assertions สำคัญ:

- ทุกหน้ามองเห็น run ID เดียวกัน
- document/payment/project totals ตรงกัน
- confirm delivery ลด stock เพียงครั้งเดียว
- dashboard/reports สะท้อน payment และ project ล่าสุด

### FLOW-P0-02: Procure-to-Pay / Supplier Quote

Admin create supplier/request quote → Generate session link → Supplier login → Submit quote/sample terms → Admin Need Revision → Supplier resubmit → Admin Approve → Supplier Bill → Upload PI/Invoice → Mark Paid → Finance outbound/report

### FLOW-P0-03: Sample and Artwork revision loops

Sample attempt 1 reject → feedback → attempt 2 approve; Artwork V1 reject → feedback → V2 approve; ตรวจ history/version ไม่ overwrite record เก่า

### FLOW-P0-04: Delivery stock safety

Read stock before → create round → confirm → read stock/movement → confirm again → complete → assert exact-once mutation

## 7. Test data strategy

- ทุก record ใช้ `PW-<timestamp>-<random>` เพื่อค้นหาและแยกจากข้อมูลจริง
- ห้าม `migrate:fresh`, `db:wipe` หรือ reset DB ใน E2E ปกติ
- smoke/regression ไม่เปลี่ยนข้อมูลถาวร
- mutation tests tag `@live-mutation` และรัน `--workers=1`
- ระบบไม่มี delete endpoint สำหรับ customer/project/supplier/container/delivery จึง cleanup ไม่ครบ; แนะนำเพิ่ม test-only cleanup command ที่อนุญาตเฉพาะ `APP_ENV=testing` หรือใช้ isolated database
- file fixtures ต้องเป็นไฟล์เล็กที่ commit ได้และไม่มีข้อมูลจริง
- ก่อน delivery mutation ต้อง snapshot stock และห้ามใช้ stock ของ production

## 8. Test tiers และคำสั่ง

| Tier | คำสั่ง | ใช้เมื่อไร |
|---|---|---|
| List/type discovery | `npm run e2e:list` | ตรวจว่า spec ถูกโหลด |
| Smoke | `npm run e2e:smoke` | ทุก commit |
| Regression non-mutating | `npm run e2e:regression` | PR/ก่อนส่ง QA |
| Mutation serial | `npm run e2e:live` | isolated staging DB เท่านั้น |
| Full | `npm run e2e` | nightly |
| Debug | `npm run e2e:debug` | แก้ locator/flow |
| UI mode | `npm run e2e:ui` | พัฒนา test |
| HTML report | `npm run e2e:report` | เปิด report ล่าสุด |

เตรียมครั้งแรก:

```powershell
cd D:\07_Projects\Work\PNN\ppn_great
npm install
npm run e2e:install
npm run build:web
npm run e2e:smoke
```

Environment override:

```powershell
$env:E2E_ADMIN_URL='https://staging.example.com'
$env:E2E_API_URL='https://staging-api.example.com'
$env:E2E_SUPPLIER_URL='https://supplier.example.com'
$env:E2E_ADMIN_EMAIL='e2e-admin@example.com'
$env:E2E_ADMIN_PASSWORD='***'
$env:E2E_EXTERNAL_SERVERS='1'
npm run e2e:regression
```

## 9. Defects/gaps ที่ test ต้องเปิดเผย

1. `Settings` เป็น placeholder เท่านั้น
2. SUPER ADMIN/OWNER ONLY เป็น label แต่ไม่มี role-based UI/API authorization ที่ route group
3. มี named route แค่ `/login`; ไม่สามารถ deep-link ไปแต่ละ module หรือทดสอบ route guard ต่อหน้าได้
4. URL API และ supplier portal hard-coded ใน Dart/PHP ทำให้ staging/CI config ยาก
5. icon buttons บางตัวไม่มี tooltip/semantic label เช่น add container และ view toggles; responsive Projects detail ซ่อน Back control ที่ viewport desktop ของ Playwright จึงต้องใช้ browser history หลังรอ API จบ
6. แผน integration มีสถานะเก่าขัดกับ source จริง โดยเฉพาะ Finance/Payment/Reports
7. API plan พูดถึง permission แต่ routes ส่วนใหญ่มีเพียง `auth:api`
8. ไม่มี delete/rollback endpoint หลาย resource ทำให้ E2E data cleanup และ rerun ยาก
9. Supplier Portal input มี default credential ใน HTML และ backend ยอมรับ token `123456` แบบ global mock — ต้องห้ามใช้ production
10. CORS file endpoints เป็น public และ Artwork ใช้ `Access-Control-Allow-Origin: *`; ต้องมี security review
11. `POST /api/containers` รับ `{}` และสร้าง container ว่างได้ เพราะทุก field เป็น `nullable`; UI validate แต่ API ไม่ validate
12. unauthenticated API request ที่ไม่ส่ง `Accept: application/json` ตอบ 500 แทน 401 เพราะ middleware หา named login route ไม่พบ
13. `flutter test` compile ไม่ได้บน Dart VM เพราะ `upload_design_screen.dart` import `dart:js` โดยตรง; ควรใช้ conditional import/`package:web`
14. `flutter analyze` พบ 305 issues (ส่วนใหญ่ deprecated `withOpacity`, unused fields/imports, web-only import และ async BuildContext)
15. Supplier Portal submit endpointรับเพียง `{qid}` และไม่ตรวจ generated token/session ที่ controller; เป็น Broken Access Control ที่ต้องแก้ก่อน production

## 10. Definition of Done

- P0 smoke ผ่าน Chromium ทุก commit
- non-mutating regression ผ่านโดยไม่มี unexpected fail
- known defect ใช้ `test.fail()` พร้อมเหตุผล ไม่ใช้ silent skip
- mutation flow รันกับ isolated staging DB และ reconcile จำนวนเงิน/stock หลังจบ
- ทุก icon button มี semantic label
- role tests มีอย่างน้อย super_admin, owner และ staff
- trace, screenshot, video เก็บเฉพาะ failure; JUnit พร้อมส่ง CI
- coverage matrix อัปเดตเมื่อ UI/API เปลี่ยน

## 11. ผล validation รอบส่งมอบ

| Check | ผล |
|---|---|
| `flutter build web` | ผ่าน |
| `npx tsc --noEmit` | ผ่าน |
| `npm run e2e:smoke` (2 workers) | 5/5 ผ่านใน 1.2 นาที |
| `npm run e2e:regression` | 23 ผ่าน, 2 skipped guard, 0 failed ใน 2.7 นาที |
| Supplier Portal suite | 2/2 ผ่าน |
| Laravel `artisan test` | 34 tests / 236 assertions ผ่าน |
| `flutter analyze` | ไม่ผ่าน quality gate: 305 issues |
| `flutter test` | ไม่ผ่าน compile: direct `dart:js` import |
| `@live-mutation` | ยังไม่รันบน `ppn_staging` ที่แชร์ เพื่อไม่สร้างข้อมูลถาวร |

Primary suite มี 29 tests ใน 10 spec files รวม live flows 3 เส้นทาง; legacy specs ใน `e2e/tests/` ถูกเก็บไว้แต่ exclude จาก root config จนกว่าจะย้าย selector ให้ semantics-aware

Expected failures ใน non-mutating regression ปัจจุบัน: ไม่มี โดย Dashboard quick-action ทั้ง 6 flow และ Edit Supplier ถูกย้ายกลับมาเป็น normal passing tests แล้ว

Known `fixme` ที่ไม่ยิง request เพื่อป้องกันข้อมูลเสีย:

- Containers API ควร reject empty payload; ปัจจุบันจะสร้าง record ว่าง
