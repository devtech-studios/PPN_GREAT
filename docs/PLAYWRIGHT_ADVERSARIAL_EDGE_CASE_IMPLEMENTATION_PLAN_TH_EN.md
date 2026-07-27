# Playwright Adversarial & Edge-Case Implementation Plan — แผนทดสอบเคสผิดปกติและค้นหาบัค

สถานะเอกสาร: V2 scaffold implemented; AUTH และ NETWORK packs ผ่านการรันจริง; repository snapshot scope still pending  
วันที่จัดทำ: 18 กรกฎาคม 2026  
ระบบ: Flutter Web + Laravel API + MySQL + Supplier Portal, local only  
ฐานข้อมูลทดสอบ: `ppn_e2e` เท่านั้น

## 1. วัตถุประสงค์ / Objective

สร้าง Playwright test version ใหม่แยกจาก realistic happy-path version ที่ผ่านแล้ว เพื่อค้นหา error, validation gap, state corruption, race condition, authorization defect, data mismatch และกรณีใช้งานผิดลำดับ โดยมีข้อกำหนดสำคัญ:

- ห้ามแก้ Flutter, Laravel, Supplier Portal หรือ schema เพื่อทำให้ test ผ่าน
- เจอ error ให้เก็บ actual result, screenshot, video, trace, console, API response และ database delta แล้วรัน test ถัดไป
- เวอร์ชัน realistic ปัจจุบันต้องเก็บไว้และยังรันซ้ำได้เหมือนเดิม
- วิดีโอต้องช้าพอสำหรับมนุษย์อ่านหน้าจอและผล validation
- ชื่อ suite, test และ step ต้องเป็น English | ไทย
- ทุก mutation ต้องใช้ dedicated database `ppn_e2e`; ห้ามใช้ `ppn_staging`
- ข้อสรุปต้องแยก Product Bug, Automation Defect, Environment Error, Blocked และ Cascade Failure

คำว่า “ครอบคลุมทุกเคส” ในเอกสารนี้หมายถึงครอบคลุมทุก equivalence class, boundary, state transition, relation, interruption และ flow permutation ที่ประกาศไว้ ไม่ได้หมายถึงลองทุก string/number ที่เป็นไปได้ซึ่งมีจำนวนไม่สิ้นสุด

## 2. Change Freeze / ขอบเขตไฟล์ที่อนุญาตให้แก้

อนุญาตเฉพาะ:

- `docs/PLAYWRIGHT_ADVERSARIAL_EDGE_CASE_IMPLEMENTATION_PLAN_TH_EN.md`
- test version ใหม่ภายใต้ path ที่รอยืนยันในหัวข้อ 16
- Playwright config/runner/reporter/fixtures ของ version ใหม่
- test fixtures เช่น zero-byte, wrong-extension, Unicode filename และ oversized file
- generated reports ภายใต้ output directory ของ version ใหม่

ห้ามแก้:

- `lib/**`
- `ppn-api/app/**`
- `ppn-api/database/migrations/**`
- `Supplier_ui_moocup/**`
- realistic V1 test files หลังสร้าง snapshot/copy สำเร็จ

หาก test ทำไม่ได้เพราะ UI ไม่มี control หรือ API ไม่มี contract ให้รายงาน `COVERAGE-GAP` หรือ `BLOCKED-BY-PRODUCT` ห้ามเพิ่ม control/endpoint เพื่อทำให้ทดสอบได้

## 3. Versioning Strategy / กลยุทธ์เก็บเวอร์ชัน

ข้อเสนอที่ต้องได้รับคำยืนยัน:

- V1 Frozen: realistic happy-path version ที่ผ่าน `1 passed` เมื่อ 18 กรกฎาคม 2026
- V2 Adversarial: copy test infrastructure ไปยัง namespace ใหม่ ไม่ import mutable flow logic จาก V1 ยกเว้น read-only helpers ที่ copy แล้วตรึง hash
- V1 artifacts ต้องมี manifest: source file SHA-256, command, result, video, trace, timestamp และ final database reconciliation
- V2 ใช้ output แยก เช่น `test-results-adversarial`, `playwright-report-adversarial`, `adversarial-findings.json`
- V2 ห้ามเขียนทับ `test-results-realistic` และ `playwright-report-realistic`

ก่อน copy ต้องยืนยันก่อนว่า “version” หมายถึงเฉพาะ Playwright suite/config/runner หรือ snapshot ทั้งสาม source repositories ดูหัวข้อ 16

## 4. Human-Readable Video Pacing / ความเร็ววิดีโอ

จะใช้สองชั้นร่วมกัน:

1. Browser-level `slowMo` หน่วงทุก click/fill/keypress
2. Named reading checkpoints หน่วงเฉพาะหน้าที่มนุษย์ต้องอ่าน เช่น validation, dialog, status card, totals, stock result และ error banner

ค่าที่ผู้ใช้ยืนยันแล้ว:

- `slowMo`: 1,000 milliseconds ต่อ action
- Normal checkpoint: 3 วินาที
- Important checkpoint: 4 วินาที
- Error checkpoint: 6 วินาที
- Final reconciliation checkpoint: 10 วินาที

หลักการ:

- ไม่ใช้ pause เพื่อแก้ race; synchronization ยังใช้ locator/API/database postcondition
- pause มีไว้เพื่อวิดีโอเท่านั้น
- test timeout ต้องคำนวณจาก pacing ไม่เพิ่มแบบไม่จำกัด
- video `on`, trace `on`, screenshot `on` สำหรับทุก test

## 5. Continue-on-Error Architecture / เจอพังแล้วไปเคสถัดไป

- หนึ่ง adversarial case = หนึ่ง `test()` เพื่อให้ failure ไม่ตัด case ถัดไป
- `workers: 1` เพื่อให้วิดีโอและ database mutation อ่านง่าย
- `retries: 0` เพื่อไม่ซ่อนความไม่แน่นอน
- `maxFailures: 0` เพื่อไม่หยุดทั้ง run เมื่อพบ failure
- ใช้ `expect.soft` เฉพาะหลาย assertion ภายใน case เดียว เพื่อเก็บ evidence ให้ครบ
- ห้าม catch error แล้วเปลี่ยน test ให้ผ่าน
- หลัง test ล้ม Playwright ต้องสร้าง browser context ใหม่ก่อน case ถัดไป
- prerequisite failure ให้ classify เป็น `BLOCKED` หรือ `CASCADE`; ห้ามนับเป็น product bug ซ้ำหลายรายการ
- global reporter ต้องสร้าง failure inventory ต่อ case แม้ process exit code สุดท้ายเป็น 1

Result taxonomy:

| Code | ความหมาย |
|---|---|
| `PASS` | ระบบตอบตาม contract/expected rejection |
| `PRODUCT-BUG` | ผลจริงขัดกับ contract หรือทำข้อมูลเสีย |
| `SECURITY-FINDING` | authorization/data exposure ผิดขอบเขต |
| `AUTOMATION-DEFECT` | selector/wait/test logic ผิด |
| `ENVIRONMENT` | server/port/browser/MySQL/build มีปัญหา |
| `BLOCKED` | UI/API ไม่มีทางทำ case หรือ prerequisite ไม่มี |
| `CASCADE` | พังเพราะ record ก่อนหน้าสร้างไม่สำเร็จ |
| `OBSERVATION` | behavior ไม่ได้ประกาศ contract จึงยังตัดสิน pass/fail ไม่ได้ |
| `COVERAGE-GAP` | พบ function/control ที่ยังไม่มี test หรือไม่มี stable selector |

### 5.1 Positive–Negative–Recovery Pairing / ทุก error ต้องมีเคสสำเร็จเทียบ

ห้ามรัน negative/error case แบบโดดเดี่ยวโดยไม่มี successful comparator ทุกเคสต้องอยู่ในหนึ่ง pattern ต่อไปนี้:

1. `SUCCESS → ERROR` — ทำวิธีถูกต้องก่อนเพื่อพิสูจน์ว่า environment, selector และ prerequisite ใช้งานได้ แล้วจึงลองค่าผิด
2. `ERROR → RECOVERY SUCCESS` — ลองค่าผิดก่อน ตรวจว่าไม่เกิด mutation แล้วแก้ข้อมูลผ่าน UI และ submit สำเร็จ
3. `SUCCESS → ERROR → RECOVERY SUCCESS` — รูปแบบมาตรฐานที่แนะนำ ใช้พิสูจน์ทั้ง baseline, validation และความสามารถกลับมาทำงานต่อ
4. `VALID VARIANT A → VALID VARIANT B → ERROR` — ใช้กับ flow ที่มีวิธีสำเร็จมากกว่าหนึ่งแบบ

แต่ละคู่/ชุดต้องมี `Pair ID` เดียวกัน เช่น:

- `PAIR-PAY-001-A` Deposit + Balance success | มัดจำและจ่ายยอดคงเหลือสำเร็จ
- `PAIR-PAY-001-B` Negative balance rejected | ยอดคงเหลือติดลบต้องไม่ถูกบันทึก
- `PAIR-PAY-001-C` Corrected balance succeeds | แก้ยอดแล้วชำระสำเร็จ

หาก successful comparator พังก่อน:

- negative case ที่อาศัย comparator เดียวกันต้องระบุ `BLOCKED-BY-BASELINE`
- ห้ามสรุป negative case เป็น product bug เพราะยังพิสูจน์ไม่ได้ว่าเส้นทางปกติทำงาน
- test ถัดไปที่ไม่พึ่ง comparator นี้ยังต้องรันต่อ

ลำดับมาตรฐานของ isolated packs คือ `success → error → recovery` ส่วน chaos journey สามารถใช้ `error → recovery success` เพื่อให้เห็นว่าระบบกลับมาทำต่อได้หรือไม่

### 5.2 Success Explanation Contract / เคสสำเร็จต้องอธิบายว่าสำเร็จอย่างไร

successful case ทุกตัวต้องสร้าง `Success Path Card` ใน report และวิดีโอ ประกอบด้วย:

- วิธีที่ใช้: full payment, deposit + balance, partial delivery, split warehouse, direct delivery หรือวิธีอื่น
- Preconditions: สถานะ project/document/payment/stock/container ก่อนเริ่ม
- ลำดับ action ที่ผู้ใช้ทำจริง
- UI confirmation ที่เห็น
- API status/result และ database rows ที่เกิดขึ้น
- จำนวนเงิน/จำนวนสินค้า before → delta → after
- เหตุผลที่ถือว่าสำเร็จ ไม่ใช้เพียง HTTP 200 หรือปุ่มหายไป
- ข้อจำกัดของวิธีนั้น เช่น ต้อง Delivered ก่อน stock-in หรือต้องมี stock พอก่อน confirm delivery
- ระบุว่าเป็น `CONTRACT-CONFIRMED`, `VALID-ALTERNATIVE` หรือ `POLICY-OBSERVATION`

Success taxonomy:

| Code | ความหมาย |
|---|---|
| `CONTRACT-CONFIRMED` | controller/UI/แผนปัจจุบันประกาศชัดและ invariants ผ่าน |
| `VALID-ALTERNATIVE` | ระบบรองรับและข้อมูลถูกต้อง แต่เป็นอีกลำดับ/รูปแบบจาก happy path |
| `POLICY-OBSERVATION` | ระบบยอมรับ แต่ไม่มี business rule ยืนยันว่าควรอนุญาต จึงยังไม่เรียกว่าถูกหรือผิด |

ห้ามตีความว่า action “สำเร็จ” เพียงเพราะ backend ยอมรับ หากยอดเงิน สต๊อก relation หรือรายงานไม่ reconcile ต้องเป็น finding

## 6. Data Isolation / การแยกข้อมูล

ต้องมีสองโหมด:

### 6.1 Isolated Packs

- reset `ppn_e2e` ก่อนแต่ละ scenario pack
- สร้าง prerequisite ที่ทราบสถานะแน่นอน
- เหมาะสำหรับ validation, authorization, boundary และ concurrency
- ลด cascade failure และช่วยระบุต้นเหตุ

### 6.2 Chaos Journey

- reset หนึ่งครั้งแล้วสลับ flow ไปมาบน project เดียว
- เจตนาทำ partial work, reload, back, multi-tab และ out-of-order actions
- ใช้ค้นหา stale state, incorrect totals และ cross-module inconsistency

วิธีสร้าง prerequisite ที่ยืนยันแล้ว: UI-only ทุกขั้น ห้ามใช้ API สร้าง record ตั้งต้นแทนผู้ใช้ API และ MySQL ใช้ตรวจผลลัพธ์แบบ read-only เท่านั้น

## 7. Evidence Contract / หลักฐานที่ต้องเก็บทุกเคส

แต่ละ case ต้องเก็บ:

- Case ID และชื่อ English | ไทย
- Preconditions และ record IDs
- User actions ตามลำดับ
- Expected UI/API/database result
- Actual UI text/status
- HTTP method, URL, status และ sanitized response body
- Browser console errors, `pageerror`, failed requests
- Before/after database counts และค่าที่เกี่ยวข้อง
- Screenshot ตอนผลลัพธ์สุดท้าย
- Video path และ trace path
- Classification และ confidence
- Dependency/cascade reference หาก case พังเพราะ case อื่น
- ห้ามเก็บ password, bearer token หรือ supplier session token แบบเต็มใน report

## 8. Coverage Model / โมเดลความครอบคลุม

ทุก field/action จะเลือกค่าจาก class ต่อไปนี้เมื่อชนิดข้อมูลรองรับ:

- Empty, missing, whitespace-only, leading/trailing whitespace
- Minimum-1, minimum, minimum+1
- Maximum-1, maximum, maximum+1
- Zero, negative, decimal, very large number, scientific notation
- Thai, English, mixed language, emoji, combining characters
- Quotes, apostrophe, HTML-like text, script-like text, SQL-like text โดยใช้ local non-destructive payload
- Duplicate exact value และ duplicate ที่ต่างเฉพาะ case/space
- Past date, today, future date, invalid date, reversed date range
- Valid relation, missing relation, deleted/nonexistent ID, wrong-parent relation
- Single click, double click, rapid click, concurrent request
- Normal network, latency, abort, offline, reload/navigation during request

## 9. Master Scenario Catalog / บัญชีเคสหลัก

### Pack A — Authentication & Session (18)

- `ADV-AUTH-001` Valid admin login | ล็อกอินถูกต้อง
- `ADV-AUTH-002` Empty both fields | เว้นว่างทั้งสองช่อง
- `ADV-AUTH-003` Email only | มีเฉพาะอีเมล
- `ADV-AUTH-004` Password only | มีเฉพาะรหัสผ่าน
- `ADV-AUTH-005` Whitespace credentials | ค่าเป็นช่องว่าง
- `ADV-AUTH-006` Leading/trailing spaces | ช่องว่างหัวท้าย
- `ADV-AUTH-007` Email case variation | ตัวพิมพ์ใหญ่เล็กของอีเมล
- `ADV-AUTH-008` Very long credentials | ค่ายาวผิดปกติ
- `ADV-AUTH-009` Unicode/emoji credentials | Unicode ใน credentials
- `ADV-AUTH-010` Injection-like local strings | string รูปแบบ injection
- `ADV-AUTH-011` Rapid double submit | กดล็อกอินซ้ำเร็ว
- `ADV-AUTH-012` Enter versus click | Enter เทียบปุ่ม
- `ADV-AUTH-013` Reload during login | refresh ระหว่างล็อกอิน
- `ADV-AUTH-014` Persisted valid token | reload ด้วย token ถูกต้อง
- `ADV-AUTH-015` Corrupted local token | token ใน storage เสีย
- `ADV-AUTH-016` Logout twice/back after logout | logout ซ้ำและ browser back
- `ADV-AUTH-017` Protected page after logout | เปิด protected route หลัง logout
- `ADV-AUTH-018` Concurrent tabs logout | logout จากอีก tab

### Pack B — Navigation, Rendering & Accessibility (16)

- เปิดทุกเมนูด้วย mouse, keyboard และ browser back/forward
- คลิกเมนูเร็วสลับ Customers → Finance → Containers → Reports
- refresh ทุกหน้าหลักและ reload ระหว่างโหลด API
- viewport desktop, narrow desktop และ zoom/text scale ที่รอยืนยัน
- ตรวจ duplicate accessible names, disabled named node, unnamed textbox/button
- ตรวจ focus order, Enter/Space activation และ Escape ปิด dialog
- ตรวจ console error/pageerror/requestfailed ทุกหน้า
- ตรวจ empty/loading/error state ไม่เกิด white screen

### Pack C — Customer & Contact Integrity (22)

- ไม่กรอกชื่อ, ชื่อ whitespace, ยาวเกิน 255, Thai/emoji/special characters
- tax ID ว่าง, สั้น, ยาว, ตัวอักษร, duplicate
- email ถูก/ผิดรูปแบบ, phone หลายรูปแบบ
- contact 0/1/หลายคน, duplicate contact และลบ contact ระหว่างแก้ไข
- billing address ว่าง/ยาว/Unicode
- same-as-billing toggle ไปมาและตรวจ shipping address ที่บันทึกจริง
- double save และ reload หลัง Confirm ก่อน response กลับ
- duplicate customer exact/case-insensitive/space-normalized
- แก้ customer ที่มี project/payment/delivery แล้ว
- delete/update address/contact ที่เป็นของ customer คนอื่นผ่าน API relation probe

### Pack D — Project & Product Boundaries (24)

- สร้าง project โดยไม่มี customer/assignee/product
- qty: ว่าง, 0, -1, 1, decimal, integer สูงมาก
- budget: ว่าง, 0, negative, decimal ใหญ่
- product name/specs ว่าง, whitespace, Unicode, HTML-like, max boundary
- target date อดีต/วันนี้/อนาคต/invalid
- product หลายรายการ, duplicate product, remove last product
- double create และ reload during create
- update project while another tab changes status
- arbitrary project status jumps, backward transition, change after Delivered/Cancelled
- upload PO: missing, wrong type, empty, duplicate, Unicode filename, oversized
- product ID ที่ไม่อยู่ใน project สำหรับ update/delete

### Pack E — Client Sample State Machine (18)

- Local/In-Stock/China origin behavior และ initial status
- missing project/product/type/origin
- skip Waiting → Approved, Received → Approved และย้อน Approved → Rejected
- repeat same status, double status submit
- Rejected without feedback และ feedback Unicode/long
- sent date past/future/invalid
- update tracking during Approved
- sample ของ project A กับ product project B
- reload/back ระหว่าง status mutation
- concurrent status updates จากสอง tabs

### Pack F — Artwork & File Handling (22)

- no file, zero-byte, wrong extension, MIME mismatch, Unicode filename
- filename very long, duplicate file/version, oversized >10 MB
- missing project/product/source/version
- version empty, duplicate, unusual string, max boundary
- Awaiting → Approved without Reviewing
- Reviewing → Awaiting, Approved → Need Revision, Rejected → Approved
- approval without feedback versus revision without feedback
- upload same file twice rapidly
- reload/navigate away during upload
- project A + product project B relation
- unauthorized file read probe for public file endpoint

### Pack G — Supplier Quote & Portal Authorization (26)

- quote missing project/product/name/qty
- qty 0, negative, decimal, huge
- quote for product not in project
- generate link twice and compare token/session invalidation behavior
- supplier login wrong username/token/expired-like/whitespace
- token from supplier A used with supplier B username
- public token invalid, random, reused after approval
- submit without price/lead/MOQ
- price 0, negative, decimal precision, huge
- MOQ 0/negative/decimal/huge
- invalid currency, long lead time, Unicode remark
- submit same quote twice/parallel
- submit qid different from authenticated supplier session (IDOR probe)
- approve before price, revise before price, approve twice
- revise after Approved and resubmit old/new token
- portal back/reload/offline during submit

### Pack H — Supplier Samples & Accounts Payable (20)

- supplier sample missing project/product, invalid dates, cost formats
- sample status skip/back/repeat/concurrent
- bill missing project/product/type/amount/currency
- amount 0, negative, precision, huge; Deposit + Balance totals mismatch
- Full Payment together with Deposit/Balance duplicates
- due month invalid/past/future
- pay before PI/Invoice upload
- upload only PI, only Invoice, wrong type, zero-byte, oversized, duplicate
- pay twice/parallel and verify `paid_at`/activity exact-once
- supplier bill references project unrelated to supplier quote

### Pack I — Finance Documents & Accounts Receivable (28)

- QU/PI/CI created out of expected order
- document missing project/customer/items
- item qty/price 0, negative, decimal precision, huge
- item project/product relation mismatch
- discount/tax/deposit boundary and rounding reconciliation
- issue date after due date, past/future extremes
- duplicate issue via rapid click and parallel tabs
- status jumps Draft → Paid, Cancelled → Sent/Paid, Paid → Draft
- payment missing project/type/method/date
- amount 0, negative, over exact total, over by 0.01, partial by 0.01
- payment finance document belongs to another project/customer
- verify before slip, upload after confirm, verify twice/parallel
- duplicate slip, wrong type, zero-byte, oversized, Unicode filename
- deposit + balance under/over total; PI must become Paid only at correct accumulated amount
- cancel document after confirmed payment and inspect reports

### Pack J — Container & Routing State Machine (24)

- create without container number/project and with duplicate number
- project checkbox none/multiple/duplicate
- date boundaries and ETA before ETD
- skip Factory → Delivered, backward transitions, repeat same step
- status action without required date
- route before Delivered
- route missing project/product/warehouse
- project not linked to container
- product not linked to project
- routing total below/above received quantity
- qty 0, negative, decimal, huge
- inventory/direct mixed routing and multiple warehouses
- duplicate exact routing, parallel duplicate routing
- reload/back/navigation during step
- two containers receiving same project/product and expected accumulation

### Pack K — Inventory Integrity (22)

- warehouse missing name/location, duplicate name, Unicode/long fields
- manual IN/OUT/ADJUST qty 0, negative, decimal, huge
- adjustment for missing/wrong product/project/warehouse relation
- OUT greater than stock, equal stock, stock-1
- concurrent OUT from two tabs against same balance
- duplicate receive/reference and parallel receive
- stock exact-once after reload/retry
- low-stock threshold boundaries
- movement chronology and before/after balance reconciliation
- stock created with project A/product B mismatch

### Pack L — Delivery Integrity (24)

- create without driver/vehicle/items
- item missing project/product/warehouse/address
- qty 0, negative, decimal, equal stock, greater than stock
- same stock item duplicated twice in one round
- mixed valid/invalid items must remain atomic
- confirm Scheduled once/twice/parallel
- complete before confirm, complete twice
- edit/navigate/reload during confirmation
- two delivery rounds reserve/confirm same stock concurrently
- wrong warehouse with stock in another warehouse
- project/customer/address mismatch
- direct shipment versus warehouse shipment
- delivered round with later stock adjustment
- OUT movement/reference exact-once and remaining stock reconciliation

### Pack M — Reports, Dashboard & Cross-Module Reconciliation (18)

- empty baseline reports
- partial flow: project only, QU only, unconfirmed payment, unpaid bill
- partial payment, overpayment, cancelled doc, rejected artwork/sample
- revenue includes confirmed only
- COGS includes paid supplier bills only
- profit project A must not include project B
- delivered count versus delivery/project statuses
- month boundary/timezone Asia/Bangkok
- rapid tab/filter switching and API latency/error
- refresh after mutation and stale cache detection
- totals after duplicate action probes must remain exact

### Pack N — Network & Interruption Injection (16, อนุญาตแล้ว)

- delayed GET/POST/PATCH
- abort create/update/upload/status request
- synthetic 400/401/403/409/422/500/503 response
- offline before submit, during submit, after server commit before client response
- reload, browser back, navigate menu, close dialog during request
- duplicate retry after unknown commit outcome
- verify loading indicator, button disabling, error message and no unintended mutation

### Pack O — Chaos Flow Permutations (12 journeys)

- `CHAOS-001` Finance before sample/artwork approval
- `CHAOS-002` Container before customer deposit
- `CHAOS-003` Supplier balance before deposit
- `CHAOS-004` CI before PI/QU
- `CHAOS-005` Delivery before container receipt/stock
- `CHAOS-006` Payment before supplier quote approval
- `CHAOS-007` Cancel/reopen project between modules
- `CHAOS-008` Alternate Project A and B on every page
- `CHAOS-009` Two tabs mutate same project in different modules
- `CHAOS-010` Reload/back after every commit
- `CHAOS-011` Partial upload/payment then logout/login resume
- `CHAOS-012` Complete happy flow then attempt every backward/repeat action

### Pack P — Valid Flexible Business Flows (อย่างน้อย 32 journeys)

Pack นี้มีไว้พิสูจน์ว่าเส้นทางสำเร็จไม่ได้มีเพียง happy path เดียว และเป็น comparator ให้ negative packs

#### Payment Variants / รูปแบบการชำระเงิน

- `VALID-PAY-001` Customer pays full amount once | ลูกค้าจ่ายเต็มครั้งเดียว
- `VALID-PAY-002` Customer deposit then exact balance | มัดจำแล้วจ่ายยอดคงเหลือพอดี
- `VALID-PAY-003` Multiple partial payments reaching exact total | แบ่งจ่ายหลายครั้งจนครบ — `CONTRACT-CONFIRMED`; ต้องสำเร็จและรองรับอย่างเป็นทางการ
- `VALID-PAY-004` Payment before shipment | ชำระก่อนส่งสินค้า
- `VALID-PAY-005` Payment after delivery/credit | ส่งก่อนแล้วชำระภายหลัง — `POLICY-OBSERVATION`; ผู้ใช้ยืนยันว่าอนุญาตและต้องเก็บ outstanding balance/ประวัติ
- `VALID-PAY-006` Supplier full payment once | จ่ายโรงงานเต็มครั้งเดียว
- `VALID-PAY-007` Supplier deposit then balance | มัดจำโรงงานแล้วจ่ายคงเหลือ
- `VALID-PAY-008` Supplier paid before container | จ่ายโรงงานก่อนเริ่มขนส่ง
- `VALID-PAY-009` Supplier balance after customer delivery | จ่ายโรงงานหลังส่งลูกค้า — `POLICY-OBSERVATION`

#### Delivery Variants / รูปแบบการส่งมอบ

- `VALID-DEL-001` Deliver all stock in one round | ส่งทั้งหมดรอบเดียว
- `VALID-DEL-002` Partial delivery then second round | ส่งบางส่วนแล้วส่งส่วนที่เหลือ
- `VALID-DEL-003` Three partial rounds with exact final zero | แบ่งส่งสามรอบจนสต๊อกเป็นศูนย์
- `VALID-DEL-004` Keep remaining safety stock | ส่งบางส่วนและเหลือ safety stock
- `VALID-DEL-005` Multiple products in one round | ส่งหลายสินค้าในรอบเดียว
- `VALID-DEL-006` Multiple projects/customers in one round | หลายโครงการในรอบเดียว — ต้องตรวจว่า UI/API ประกาศรองรับจริง
- `VALID-DEL-007` Direct customer routing from container | ส่งตรงลูกค้าจากตู้
- `VALID-DEL-008` Mixed direct + warehouse routing | แบ่งบางส่วนส่งตรงและบางส่วนเข้าโกดัง

#### Inventory & Container Variants / รูปแบบตู้และคลัง

- `VALID-INV-001` Receive all quantity into one warehouse | รับเข้าคลังเดียว
- `VALID-INV-002` Split one receipt across two warehouses | แบ่งรับเข้าสองคลัง
- `VALID-INV-003` Container carries multiple projects | หนึ่งตู้มีหลายโครงการ
- `VALID-INV-004` Two containers for one project/product | สินค้าโครงการเดียวมาสองตู้
- `VALID-INV-005` Receive then manual documented adjustment | รับเข้าแล้วปรับยอดแบบมีเหตุผล
- `VALID-INV-006` Receive, reserve, release through failed delivery, retry | จอง/ยกเลิก/ส่งใหม่ตาม contract ที่มีจริง

#### Document & Workflow Variants / รูปแบบเอกสารและลำดับงาน

- `VALID-DOC-001` QU → PI → CI canonical | เอกสารตามลำดับมาตรฐาน
- `VALID-DOC-002` PI created without prior QU | ออก PI โดยไม่ออก QU — `POLICY-OBSERVATION`
- `VALID-DOC-003` CI after full payment | ออก CI หลังรับครบ
- `VALID-DOC-004` CI before final payment | ออก CI ก่อนรับครบ — `POLICY-OBSERVATION`
- `VALID-FLOW-001` Sample then artwork | ตัวอย่างก่อนอาร์ตเวิร์ก
- `VALID-FLOW-002` Artwork Approved then Sample Request | อนุมัติอาร์ตเวิร์กก่อนขอตัวอย่าง — `ENFORCED-SEQUENCE`; ต้องสำเร็จตามลำดับนี้
- `INVALID-FLOW-002` Sample Request before Artwork Approved | ขอตัวอย่างก่อนอาร์ตเวิร์กอนุมัติ — `EXPECTED-REJECTION`; ระบบต้องบล็อกและไม่สร้าง Sample Request
- `VALID-FLOW-003` Supplier quote while sample pending | ขอราคาระหว่างรอตัวอย่าง
- `VALID-FLOW-004` Pause/logout/resume at every major module | หยุดและกลับมาทำต่อ
- `VALID-FLOW-005` Alternate two projects without cross-contamination | สลับสองโครงการโดยข้อมูลไม่ปน

จำนวนที่วางแผนเบื้องต้นหลังเพิ่ม successful comparators: อย่างน้อย 350 test cases/journeys ก่อนแตก parameterized boundaries จำนวนสุดท้ายต้องสร้างจาก field inventory manifest เพื่อป้องกันการนับซ้ำ

### 9.1 Required Pair Map / แผนจับคู่ success กับ error

| Negative area | Successful comparator ที่ต้องรันก่อนหรือหลัง |
|---|---|
| Login invalid/empty/session | valid login + logout + login again |
| Customer field validation | valid minimal customer + corrected resubmit |
| Project/product boundary | valid one-product project + corrected quantity |
| Sample/artwork state/file | valid upload/status progression + recovery upload |
| Supplier quote/portal auth | valid generated token + valid quote submit |
| Supplier bill/payment | full-payment success หรือ deposit+balance success |
| Finance/payment validation | exact total payment success + corrected payment |
| Container transition/routing | canonical Delivered + valid exact routing |
| Inventory insufficient/duplicate | valid IN + valid OUT + exact remaining stock |
| Delivery invalid/double confirm | valid scheduled→transit→delivered round |
| Report mismatch | known reconciled dataset ก่อนสร้าง partial/abnormal dataset |
| Network abort/retry | same action with normal network before/after injection |

Pair map ฉบับ implement ต้องอ้าง Case ID จริงทุกตัว ห้ามมี negative case ที่ `positive_pair_id` ว่าง

## 10. API Contract Matrix / การทดสอบ API โดยไม่แก้ระบบ

สำหรับ protected endpoint ทุกตัว:

- no token, malformed token, logged-out token
- missing payload
- wrong content type
- unknown resource ID
- wrong-parent nested resource ID
- method not allowed
- duplicate/parallel mutation เมื่อมีความเสี่ยง exact-once

สำหรับ public endpoint:

- invalid/random token
- token/qid mismatch
- cross-supplier access
- path traversal-like filename ที่ปลอดภัยและอยู่ local
- unauthorized file disclosure behavior

API tests เป็น observation/probe เท่านั้น ห้าม bypass UI เพื่อประกาศว่า UI case ผ่าน

## 11. Database Oracle / สิ่งที่ตรวจจาก MySQL

ใช้ read-only query หลัง action เพื่อตรวจ:

- row count ก่อน/หลัง
- foreign keys และ parent ownership
- status และ timestamp
- payment/document accumulated totals
- supplier bill totals
- stock item balance
- stock movement exact-once/reference
- delivery status and item quantity
- container project pivot และ routing side effects
- activity log duplication

ห้ามแก้ข้อมูลด้วย query หลัง test เพื่อทำให้ผลผ่าน การ reset ใช้เฉพาะ guarded reset ก่อน scenario pack

## 12. Non-Functional Checks / เคสที่ไม่ใช่ business rule

- Flutter `pageerror`, console error และ failed network request
- selector uniqueness และ accessible role/name
- keyboard navigation/focus trap
- loading/disabled state ป้องกัน double submit
- responsive viewport ที่รอยืนยัน
- long text overflow และ error text readability
- video readability และ evidence completeness
- test runtime/slow selector inventory โดยแยกจาก deliberate video pacing

## 13. Execution Phases / ลำดับดำเนินการ

1. Freeze V1 และสร้าง manifest/hash
2. Copy/create V2 namespace และ output directories
3. สร้าง pacing helper จากค่าที่ผู้ใช้ยืนยัน
4. สร้าง evidence reporter และ result taxonomy
5. สร้าง Success Path Card และ positive-pair registry
6. สร้าง field/action inventory จาก Flutter/controller/routes จริง
7. Implement Pack P successful variants/comparators ก่อน negative packs ที่พึ่งพา
8. Implement Pack A–D: identity/master data พร้อม success→error→recovery
9. Implement Pack E–H: samples/artwork/supplier/AP พร้อม success→error→recovery
10. Implement Pack I–L: finance/container/inventory/delivery พร้อม success→error→recovery
11. Implement Pack M: report reconciliation
12. Implement Pack N หลังยืนยัน network injection
13. Implement Pack O chaos journeys
14. ตรวจว่า negative case ทุกตัวมี `positive_pair_id`
15. `--list` และ TypeScript validation
16. Dry run non-mutating cases
17. Run isolated packs พร้อม reset guard
18. Run chaos journey
19. Generate success-method catalog, defect inventory, coverage-gap matrix และ executive summary

## 14. Definition of Done / เงื่อนไขเสร็จงาน

- V1 ยังรันคำสั่งเดิมได้และ artifact เดิมไม่ถูกเขียนทับ
- V2 มี plan, config, runner, helpers, fixtures, suites และ reporter แยก
- ทุก case มี bilingual name, precondition, expected result และ evidence links
- negative case ทุกตัวมี successful comparator ก่อนหรือหลัง และมี `positive_pair_id`
- report อธิบายวิธีสำเร็จของ valid variant พร้อม before/delta/after reconciliation
- run ไม่หยุดที่ failure แรก
- product code diff ไม่มีการเปลี่ยนจาก baseline snapshot
- report แยก Product Bug/Automation/Environment/Blocked/Cascade
- coverage matrix ระบุ Tested/Not Testable/Not Implemented/Blocked ทุก control/endpoint
- final report มี reproducible command ต่อ defect
- วิดีโอผ่าน readability review ตามค่าความเร็วที่ผู้ใช้ยืนยัน

## 15. Commands ที่วางแผนไว้ / Planned Commands

```powershell
# List without database reset
npm run e2e:adversarial:v2:list

# Run isolated packs, continue after failures, record every artifact
.\scripts\run-adversarial-v2-e2e-video.ps1 -ConfirmReset

# Run one pack
.\scripts\run-adversarial-v2-e2e-video.ps1 -ConfirmReset -Pack AUTH

# Run network injection pack
.\scripts\run-adversarial-v2-e2e-video.ps1 -ConfirmReset -Pack NETWORK

# Open dedicated reports
npm run e2e:adversarial:v2:report:auth
npm run e2e:adversarial:v2:report:network
```

Runner ต้อง exit non-zero เมื่อมี product/automation/environment failures แต่ต้องรันทุก case ให้ครบก่อน exit

## 16. Explicit Decisions Required / จุดที่ต้องให้ผู้ใช้ยืนยัน

ห้าม implement ส่วนที่ขึ้นกับคำตอบต่อไปนี้โดยเดา:

1. Version copy scope ยังรอยืนยัน: copy เฉพาะ Playwright V1 suite/config/runner ไป V2 หรือ snapshot ทั้ง `ppn_great`, `ppn-api`, `Supplier_ui_moocup`

รายการที่ยืนยันแล้ว:

- V2 เริ่มใน Playwright namespace แยกและไม่แตะ product code
- Video pacing: slowMo 1,000 ms; normal 3 s; important 4 s; error 6 s; final 10 s
- Prerequisite setup: UI-only ทุกขั้น
- Network injection: อนุญาต `page.route()` สำหรับ local latency/abort/4xx/5xx
- Viewport: Desktop 1440×1000 เท่านั้น
- ส่งสินค้าก่อนลูกค้าชำระ: `POLICY-OBSERVATION`, อนุญาตให้ระบบทำได้และควรแสดง outstanding balance/ประวัติ
- แบ่งชำระหลายงวด: `CONTRACT-CONFIRMED`, ต้องรองรับอย่างเป็นทางการและ reconcile partial payments
- PI โดยไม่มี QU: `POLICY-OBSERVATION`, อนุญาตสำหรับงานซื้อซ้ำ/เร่งด่วน
- CI ก่อนรับเงินครบ: `POLICY-OBSERVATION`, อนุญาตสำหรับเอกสารบัญชี/ศุลกากร
- Artwork ก่อน Sample: `ENFORCED-SEQUENCE`; ต้อง Artwork Approved ก่อนเปิด/ยอมรับ Sample Request

เริ่มสร้าง V2 scaffold/test infrastructure ได้แล้วโดยไม่แก้ product code ส่วน snapshot ทั้งสาม repositories จะยังไม่ทำจนกว่าจะได้รับคำตอบเรื่อง copy scope

## 17. Known Hypotheses — ยังไม่ถือว่าเป็นบัคจนกว่าจะรัน

- zero amount อาจผ่าน validation เพราะบาง controller ใช้ `min:0`
- status endpoint บางตัวอาจอนุญาตกระโดด/ย้อนสถานะโดยไม่ตรวจ previous state
- Supplier Portal submit อาจต้องตรวจ token ownership กับ quote ID เพิ่มเติม
- public file endpoints อาจอ่านไฟล์ได้โดยไม่มี authenticated user ตาม route contract
- Client Sample initial status อาจไม่ตรง payload ที่ UI ส่ง
- duplicate/parallel mutation อาจสร้าง record หรือ movement ซ้ำ
- finance/report totals อาจมี rounding/timezone/overpayment edge cases

ทุกข้อข้างต้นเป็น test hypothesis เท่านั้น ห้ามระบุเป็น defect ก่อนมี reproducible evidence

## 18. Implementation Run Ledger / บันทึกการสร้างและรัน V2

สถานะ ณ 18 กรกฎาคม 2026:

| Pack | Cases | Result | Video | Trace | Classification |
|---|---:|---:|---:|---:|---|
| AUTH | 6 | 6 passed, 0 failed, 0 skipped | 6 | 6 | success, expected rejection, recovery |
| NETWORK | 4 | 4 passed, 0 failed, 0 skipped | 4 | 4 | baseline, latency, synthetic 503, recovery |
| ALL (consolidated) | 10 | 10 passed, 0 failed, 0 skipped | 10 | 10 | AUTH + NETWORK in one report |

รายละเอียดที่ยืนยันจากการรัน:

- V1 freeze guard ผ่านก่อน reset ทุกครั้ง
- reset จำกัดเฉพาะ `ppn_e2e`; baseline หลัง seed คือ users=1, suppliers=1, customers=0, projects=0
- test แยก context และไม่ใช้ serial dependency ดังนั้น failure หนึ่งเคสไม่ทำให้เคสถัดไปถูก skip
- AUTH เคสแรกเคยพบ `AUTOMATION-DEFECT`: Flutter password field ไม่รับค่าจาก `fill()` แม้ Playwright ไม่ throw; แก้เฉพาะ V2 helper ให้ใช้ keyboard interaction แบบเดียวกับ V1 แล้วรันซ้ำผ่าน 6/6
- NETWORK ใช้ `page.route()` เฉพาะ login endpoint และ context ใหม่ทุกเคส; latency 3 วินาที, synthetic 503 และ normal recovery ผ่านตาม expected contract
- artifact แยกตาม pack เป็น `test-results-adversarial-v2-<pack>` และ `playwright-report-adversarial-v2-<pack>` เพื่อไม่ให้วิดีโอถูกรันถัดไปเขียนทับ
- ยังไม่มีข้อใดถูกจัดเป็น Product Bug จาก 10 เคสแรก
