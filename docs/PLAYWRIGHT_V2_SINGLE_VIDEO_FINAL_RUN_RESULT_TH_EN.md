# Playwright V2 Single-Video Final Run Result | ผลรันทดสอบคลิปยาว V2

## Run outcome | ผลการรัน

- Run date: 2026-07-18 (Asia/Bangkok)
- Test: `LONG-001 | Full realistic, policy and error journey in one video | วงจรจริงพร้อมเคสผิดปกติในวิดีโอเดียว`
- Duration: 1,078,872 ms (ประมาณ 18.0 นาที)
- Video: 1 WebM file, 28.46 MB
- Coverage: Workflow 1–13 in one Playwright test and one browser context
- Automation result: no `AUTOMATION-ERROR` and no `BLOCKED` findings remained
- Playwright status: intentionally failed because four `PRODUCT-MISMATCH` findings were preserved as defects; product code was not changed

## Database baseline | ฐานข้อมูลเริ่มต้น

The dedicated local database `ppn_e2e` was reset before the run. It began with one Admin user, one Supplier identity, and zero business transactions.

ฐานข้อมูล local `ppn_e2e` ถูกรีเซ็ตก่อนรัน เหลือผู้ใช้ Admin หนึ่งราย, Supplier หนึ่งราย และข้อมูลธุรกิจเป็นศูนย์

## Completed business state | สถานะธุรกิจปลายทาง

| Area | Final evidence |
|---|---|
| Customer / Project | 1 customer, 1 project, 1 product × 1,000 units |
| Artwork / Samples | 2 artwork revisions, 3 client sample records |
| Supplier | 1 sample request, 1 quote, Deposit and Balance bills both Paid |
| Customer finance | PI, QU and CI all Sent at 149,000 THB |
| Customer payments | 30,000 + 20,000 + 99,000 = 149,000 THB, all Confirmed |
| Container | 1 container, status Delivered |
| Inventory | Warehouse stock received 100 and ended at 0 |
| Valid delivery | 900 Direct + 100 Warehouse, status Delivered |
| Negative delivery evidence | 101 warehouse units were incorrectly accepted and remained Scheduled |

## Product mismatches | จุดที่ระบบไม่ตรงเงื่อนไข

1. `WF04-ERR-SEQUENCE` — The system created a client sample before Artwork was approved (`before=0`, `after=1`). ระบบยอมสร้าง Sample ก่อน Artwork Approved
2. `WF05-ERR-FILE` — Saving Artwork without a file did not show the required visible validation (`validationVisible=false`). ไม่แสดง validation เมื่อไม่เลือกไฟล์ Artwork
3. `WF10-ERR-NUMBER` — Saving a Container without a container number did not show the required visible validation (`validationVisible=false`). ไม่แสดง validation เมื่อไม่กรอกเลขตู้
4. `WF12-ERR-STOCK` — The system created a delivery round for 101 warehouse units while only 100 were in stock (`before=0`, `after=1`). ระบบยอมสร้างรอบส่งเกินสต๊อก

## Supported policy/use cases demonstrated | Use case ที่ทดสอบผ่าน

- PI before QU
- Partial customer payments
- Shipping before full customer payment
- CI before final payment
- Final customer settlement after delivery
- Supplier quote, approval, Deposit and Balance payments
- Container lifecycle to Delivered
- Warehouse receipt, duplicate-receipt probe, 90/10 Direct/Warehouse delivery split
- Report navigation and final cross-module reconciliation

## Artifacts | ไฟล์ผลลัพธ์

- HTML report: `playwright-report-adversarial-v2-long/index.html`
- Video/trace/screenshots: `test-results-adversarial-v2-long/`
- Machine-readable reporter output: `test-results-adversarial-v2-long/adversarial-findings.json`
- Test plan: `docs/PLAYWRIGHT_V2_SINGLE_VIDEO_WORKFLOW_1_13_PLAN_TH_EN.md`
- Test implementation: `e2e/adversarial-v2/long.paired.spec.ts`

## Re-run command | คำสั่งรันซ้ำ

```powershell
.\scripts\run-adversarial-v2-e2e-video.ps1 -ConfirmReset -Pack LONG
```

Use `-SkipBuild` only when the current Flutter Web build is already up to date.

